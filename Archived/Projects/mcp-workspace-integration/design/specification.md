---
type: specification
domain: software
status: active
project: mcp-workspace-integration
skill_origin: systems-analyst
created: 2026-03-16
updated: 2026-03-16
---

# MCP Workspace Integration — Specification

## Problem Statement

Crumb and Tess access Google Workspace through bespoke, divergent integrations — gws CLI, direct API calls in bash scripts, and manual OAuth token management. This creates maintenance drag (OAuth rotation, CLI updates, per-script debugging) and capability asymmetry (Crumb has no direct GWS access; Tess has partial access through scripts). A community MCP server (taylorwilsdon/google_workspace_mcp, 1.8k stars, 94 tools, 12 services) can unify both agents' access through a single server with shared auth.

## Facts

- F1: Community MCP server (taylorwilsdon/google_workspace_mcp) provides 94 tools across 12 Google services. MIT licensed, Python 3.10+, FastMCP-based. 1.8k stars, 1,597 commits, 528 forks as of 2026-03-16.
- F2: Claude Code has native MCP client support (configured in `.claude/settings.json`). Already in use (context7 MCP server active in current config).
- F3: OpenClaw has native MCP client support via `@modelcontextprotocol/sdk@1.25.3`. MCP servers configured in `openclaw.json`, spawned as child processes.
- F4: Current email-triage.sh (441 lines) uses gws CLI for Gmail API calls + direct Anthropic API (Haiku) for classification. Cost: ~$0.17/106 emails. Runs every 30 min during waking hours. Architecture: bash orchestrates fetch → classify → label. Model never touches Gmail directly.
- F5: Google released official `gws` CLI with MCP mode (March 2, 2026), but it's pre-v1.0, requires gcloud CLI (200MB), and has painful OAuth setup (85 manual scopes, 45+ min reported).
- F6: The community server supports streamable HTTP transport (recommended for Claude Code) and stdio. OAuth 2.0/2.1 with automatic token refresh and session management. Desktop OAuth clients — no redirect URI configuration needed.
- F7: The community server has tool tiers: `core` (essential), `extended` (core + extras), `complete` (everything). Selective loading also available via `--tools gmail drive`.
- F8: MCP server runs as a local process. Both agents connect to it. One OAuth credential set, one token refresh mechanism.

## Assumptions

- A1: The community MCP server's OAuth token refresh is reliable enough to replace manual token management. **Validate during spike.**
- A2: OpenClaw can connect to the MCP server via stdio (child process spawn). **Validate during spike.**
- A3: The MCP server's Gmail tools support label management (apply/remove labels by ID). **Validate during spike.** If not, email-triage.sh migration is blocked.
- A4: Running the MCP server as a persistent local process (for Tess's 30-min triage cycle) is operationally stable. **Validate during soak.**
- A5: The MCP server's Google API calls don't hit rate limits at current usage patterns (~48 triage runs/day + ad-hoc Crumb session queries).

## Unknowns

- U1: Does the MCP server handle Gmail label operations (add/remove labels by ID, not just search)? The tool list shows `search_gmail_messages` and thread management, but explicit label application needs verification.
- U2: Can OpenClaw spawn the MCP server as a child process via stdio, or does it need HTTP transport? The community server supports both, but OpenClaw's MCP client may prefer one.
- U3: What's the MCP server's cold start time? If Tess's triage script needs it warm, it may need to run as a persistent process rather than on-demand.
- U4: OAuth consent screen — does Danny's Google account require admin approval for the OAuth app, or can desktop app credentials bypass this? Personal Gmail accounts are typically self-service; Google Workspace accounts may require admin consent.
- U5: Concurrent access — can both Crumb and Tess connect to the same MCP server instance simultaneously, or do they need separate instances? If separate, token/credential sharing still unifies auth but doubles process overhead.

## System Map

### Components

```
┌──────────────────────────────────────────────────┐
│      Google Workspace MCP Server (local)          │
│      taylorwilsdon/google_workspace_mcp           │
│      OAuth 2.0 + auto token refresh               │
│      Transport: stdio (OpenClaw) + HTTP (Crumb)   │
└──────────┬───────────────────┬───────────────────┘
           │                   │
     ┌─────┴──────┐      ┌────┴──────┐
     │   Crumb    │      │   Tess    │
     │ Claude Code│      │ OpenClaw  │
     │ Extended   │      │ Core      │
     │ Gmail,Cal, │      │ Gmail,Cal,│
     │ Drive,Cont,│      │ Drive,    │
     │ Docs,Sheets│      │ Contacts  │
     └────────────┘      └───────────┘
```

### Dependencies

- **Upstream:** Google Workspace APIs, community MCP server releases
- **Internal:** OpenClaw config (`openclaw.json`), Claude Code config (`.claude/settings.json`), email-triage.sh, daily-attention.sh, Tess voice/mechanic agent prompts
- **Downstream:** pydantic-ai-adoption ADR §2.2 (this resolves the MCP feasibility question), tess-operations (email triage migration)

### Constraints

- C1: Must work for Danny's personal Google account (not Google Workspace admin)
- C2: Email-triage.sh's proven economics ($0.17/106 emails) must not regress. The current bash+API architecture is efficient — migration must preserve or improve cost.
- C3: OAuth credentials must be secured (keychain or environment, not committed to git)
- C4: Spike-first — validate before committing to full migration
- C5: No service disruption during migration. Old and new can run in parallel during validation.

### Levers

- **Tool tiers:** Crumb extended, Tess core. Limits attack surface and context overhead per agent.
- **Transport mode:** HTTP for Crumb (recommended by server docs), stdio for OpenClaw (native MCP pattern). May use HTTP for both if concurrent access requires it.
- **Migration sequencing:** Crumb first (additive — new capability), Tess second (replacement — higher risk).

### Second-Order Effects

- Crumb gains direct GWS access it never had — may change workflow patterns (e.g., checking email mid-session instead of asking Tess)
- Tess's chief-of-staff role clarifies: always-on monitoring (triage, briefings, alerts) stays with Tess. Crumb gets on-demand access during sessions.
- gws CLI can be retired after migration, removing a dependency and its update/auth maintenance
- OAuth token rotation pain (documented in memory) is eliminated — MCP server handles refresh automatically
- If the community server becomes unmaintained, de-adoption path is: revert to gws CLI + direct API (code still exists in git history)

## Decision Gate: Email Triage Migration Architecture

Two paths for migrating email-triage.sh from gws CLI to MCP:

### Option 1: Keep bash, swap transport (LEANING)

Replace `gws` CLI calls in email-triage.sh with `curl` to the MCP server's HTTP endpoint. Bash still orchestrates fetch → classify → label. Model still makes a single API call for classification — never touches Gmail directly.

**Pro:** Minimal architectural change. Preserves proven cost model. Debuggable (curl commands in bash). No change to Haiku's role (classifier, not tool-caller).
**Con:** MCP server's HTTP API may not map 1:1 to gws CLI calls. Script is coupling to MCP's HTTP transport format rather than using MCP natively.

### Option 2: Move to agent-native MCP

Tess's OpenClaw agent uses MCP tools directly. The agent calls `search_gmail_messages`, reasons about each email, applies labels via MCP tools. Replaces the bash script entirely.

**Pro:** Fully MCP-native. Cleaner long-term. Agent can reason about context (e.g., "this email is about the Steelcase account I prepped for yesterday").
**Con:** Changes execution model from script to agent. Haiku making tool calls is more expensive than a single classification call. Harder to debug. Triage cost likely increases from ~$0.17 to $1-3+ per run (multiple tool calls × 30+ emails).

### Gate Condition

Decide after spike validates MCP server functionality (MWI-002 complete). Evaluate:
1. Does the MCP HTTP API support the specific Gmail operations email-triage.sh needs (search, read metadata, modify labels)?
2. What's the latency overhead of MCP HTTP calls vs. direct gws CLI calls?
3. Is the label modification tool available and reliable?

Operator preference as of specification: **Option 1**.

## Domain Classification & Workflow

- **Domain:** software (system infrastructure)
- **Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Rationale:** Touches both agents' configurations, replaces existing infrastructure, involves external dependency adoption. Multi-milestone with a spike gate.

## Task Decomposition

### Milestone 1: Spike — Validate MCP Server (Crumb only)

| ID | Task | Type | Risk | Acceptance Criteria |
|---|---|---|---|---|
| MWI-001 | Install MCP server, configure OAuth, add to Claude Code config | #code | medium | MCP server running locally, Crumb can list Gmail messages in a session |
| MWI-002 | Validate core tools: Gmail search, read, label ops; Calendar events; Drive search/read; Contacts search | #research | medium | Each tool tested manually in a Crumb session. Document which tools work, which don't, any gaps |
| MWI-003 | Decision gate: email triage migration architecture (Option 1 vs Option 2) | #decision | low | Decision documented in run-log with rationale based on MWI-002 findings |

### Milestone 2: Tess Direct API Access

*Rescoped from "Tess MCP Integration" — OpenClaw v2026.3.13 does not support external MCP servers. The `@modelcontextprotocol/sdk` is used only for ACP protocol and Chrome browser control. Original MWI-004/005/006 blocked. Replaced with direct REST API approach using shared OAuth tokens.*

| ID | Task | Type | Risk | Acceptance Criteria |
|---|---|---|---|---|
| MWI-004 | Build shared OAuth token reader for Tess scripts | #code | medium | Bash function reads access token from MCP server's credential store. Handles token refresh via stored refresh_token if access token expired. Tested: returns valid token that authenticates against Gmail and Calendar APIs |
| MWI-005 | Build OpenClaw workspace skill for interactive GWS queries | #code | medium | Tess can answer "what's on my calendar?" and "what emails came in?" in Telegram using direct REST API calls. Skill wraps curl + token reader |
| MWI-006 | Validate Tess interactive GWS access end-to-end | #research | low | Test via Telegram: calendar query, email search, contact lookup all return correct results |

### Milestone 3: Email Triage Migration

*MWI-003 decision: Option 1b — bash + direct Gmail REST API. Keep Haiku batch classification, swap gws CLI for direct API calls using shared OAuth tokens from Milestone 2.*

| ID | Task | Type | Risk | Acceptance Criteria |
|---|---|---|---|---|
| MWI-007 | Migrate email-triage.sh: replace gws CLI with direct Gmail REST API | #code | high | Migrated script processes test batch correctly: emails classified, labels applied, urgent alerts sent. Uses token reader from MWI-004. Batch label API for efficiency |
| MWI-008 | Parallel validation — run old and new triage side-by-side for 48 hours | #code | medium | Classification parity: new script produces equivalent labels on same emails. Cost delta documented |
| MWI-009 | Migrate daily-attention calendar reads to direct Google Calendar API | #code | low | Daily attention script reads calendar via REST API instead of Apple Calendar snapshots. Real-time, no GUI dependency |
| MWI-010 | Retire gws CLI dependency from triage and attention scripts | #code | low | gws CLI calls removed. Scripts pass with REST API-only access. Old scripts preserved in git history |

### Milestone 4: Documentation & Stabilization

| ID | Task | Type | Risk | Acceptance Criteria |
|---|---|---|---|---|
| MWI-011 | Update tess-operations docs to reflect direct API GWS access | #writing | low | Operational docs accurate. Token reader, skill, and LaunchAgent configs documented |
| MWI-012 | Update pydantic-ai-adoption ADR §2.2 to reflect MCP feasibility findings | #writing | low | ADR updated: MCP works for Crumb (Claude Code), not for Tess (OpenClaw lacks support). Direct API is the Tess path |
| MWI-013 | 7-day soak — monitor token refresh, triage stability, calendar accuracy | #research | medium | Zero auth failures over 7 days. Token refresh works unattended. No triage runs missed. Calendar reads match Apple Calendar data |

### Dependencies

```
MWI-001 → MWI-002 → MWI-003 (spike, sequential — COMPLETE)
MWI-003 → MWI-004 (token reader is foundation for all Tess API access)
MWI-004 → MWI-005 (skill uses token reader)
MWI-004 → MWI-007 (triage migration uses token reader)
MWI-005 → MWI-006 (validate after skill is built)
MWI-007 → MWI-008 → MWI-010 (migration, sequential with parallel validation)
MWI-009 can run in parallel with MWI-007 (both use token reader from MWI-004)
MWI-010 → MWI-011 (retire before documenting)
MWI-008 → MWI-013 (soak after parallel validation passes)
MWI-012 can run anytime after MWI-002
```

### Risk Summary

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| MCP server OAuth doesn't handle Danny's account type | Low | High (blocks project) | Spike validates first. Fallback: use official `gws mcp` mode |
| Gmail label operations not supported by MCP tools | Medium | High (blocks email triage migration) | MWI-002 validates. If blocked, keep bash+gws for labels, use MCP for reads only |
| Community server goes unmaintained | Low | Medium | Pin version. De-adoption path: revert to gws CLI (code in git history). Monitor project health signals |
| Concurrent access causes auth conflicts | Low | Medium | MWI-005 validates. If needed, run separate instances with shared credentials |
| MCP HTTP latency degrades triage performance | Low | Low | Measure in spike. Current gws CLI has its own overhead — MCP may be comparable |
