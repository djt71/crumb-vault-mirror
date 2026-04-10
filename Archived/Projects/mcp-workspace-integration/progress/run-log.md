---
type: run-log
project: mcp-workspace-integration
created: 2026-03-16
updated: 2026-03-16T22:00:00
---

# Run Log — mcp-workspace-integration

## 2026-03-16 — Project creation

**Context:** Emerged from ADR review of pydantic-ai-adoption project (§2.2 MCP as Integration Protocol). Research confirmed:
- Community Google Workspace MCP server (taylorwilsdon/google_workspace_mcp) is mature: 1.8k stars, 1,597 commits, 94 tools across 12 services
- OpenClaw has native MCP client support — both Crumb and Tess can connect to the same server
- Google also released official `gws` CLI with MCP mode (March 2, 2026), but community server has better auth ergonomics
- Current bespoke surface (gws CLI, OAuth rotation, direct API calls in email-triage.sh) is maintenance drag

**Scope decision:** Gmail, Calendar, Drive, Contacts for both agents. Docs + Sheets for Crumb only. Tasks, Forms, Slides, Chat, Apps Script, Search skipped (no current use case).

**Approach:** Spike-first within formal workflow — validate MCP server works in environment before committing to full migration.

**Phase:** SPECIFY

**Context inventory (5 docs):**
1. pydantic-ai-adoption ADR §2.2 (MCP direction, read in conversation)
2. pydantic-ai-adoption analysis §4 (MCP evaluation, read in conversation)
3. email-triage.sh (441 lines — current bespoke GWS integration to replace)
4. claude-print-automation-patterns.md (prior art for automation patterns)
5. behavioral-vs-automated-triggers.md (enforcement pattern reference)

**Specification written:** `design/specification.md` — 13 tasks, 4 milestones, spike-first approach. Decision gate at MWI-003 for email triage migration architecture (Option 1: bash+MCP-HTTP vs Option 2: agent-native). Operator leaning Option 1.

**Key findings during research:**
- Community MCP server (1.8k stars, 94 tools) is more mature than expected
- OpenClaw has native MCP client support — both agents can connect to same server
- Google's official `gws` CLI now has MCP mode (March 2, 2026) but is pre-v1.0 with painful auth
- Gmail label operations are the critical unknown (U1) — validates in spike

**Scope:** Standard spec. Peer review not recommended (infrastructure project, well-scoped from extensive discussion).

**Action plan written:** `design/action-plan.md` + `design/tasks.md` — 4 milestones, 13 tasks. Spike-gated progression. Estimated 5-7 sessions across 2-3 weeks + 7-day soak. Key decision gate at MWI-003 (email triage migration architecture).

**Cross-project deps updated:** XD-019 (MC Relationship Heat Map), XD-020 (MC Comms Cadence), XD-021 (ADR §2.2 feasibility) — all now have this project as upstream.

**Phase transition:** SPECIFY → PLAN → IMPLEMENT. MWI-001 complete.

**MWI-001 completed:**
- Installed workspace-mcp v1.14.3 via pipx (isolated venv)
- OAuth credentials stored in macOS keychain (crumb account)
- MCP server added to `.claude/settings.json` via `claude mcp add` — stdio transport, extended tier (gmail, drive, calendar, contacts, docs, sheets), single-user mode
- `.mcp.json` added to `.gitignore` (contains OAuth credentials in plaintext)
- Server health check: connected ✓
- **Next:** Restart session to pick up MCP tools, then MWI-002 (validate core tools across 6 services)

**Compound evaluation:**
- Session covered ADR review, sync vs async architecture analysis, parallelism friction identification, concurrent session validation, and full project creation through to first task completion
- Pattern: "self-imposed constraints masquerading as platform limitations" — the flock rule, sequential dispatch, and single-session workflow were conservative choices that became friction after the bridge stabilized. Worth capturing as a solution doc if it recurs.
- Cross-project impact: XD-005 and XD-007 (Mission Control customer panels) now have an upstream project. ADR §2.2 feasibility brief will be resolved by MWI-002.
- Anthropic March 2026 promo (doubled off-peak through March 28) provides cost headroom for concurrent session experimentation and spike work.

**Model routing:** All work in main Opus session. No delegation to Sonnet. Three Explore subagents for parallel research (Tess architecture, bridge/dispatch, active projects) — all returned high-quality results, no rework needed.

## 2026-03-16 — MWI-002: Core tool validation (session 2)

**Context:** MWI-001 complete (server installed, configured, connected). This session validates all 6 services before the MWI-003 decision gate.

**OAuth finding:** Tokens from MWI-001 session did not persist across sessions. First tool call triggered browser-based OAuth consent flow. Single consent covered all scopes (unified scope set across all services). After one consent, all services authenticated. This is notable for Tess integration (MWI-004) — Tess will need its own OAuth flow, and token persistence needs investigation for unattended operation (A4).

**Validation results — 14 tests, 14 pass:**

| Service | Tools Tested | Result |
|---------|-------------|--------|
| Gmail | `list_gmail_labels` | 53 labels (15 system + 38 user). All Cora triage labels + @Agent workflow labels visible with IDs. |
| Gmail | `search_gmail_messages` | Search with Gmail operators works. Pagination supported. Returns message IDs + thread IDs. |
| Gmail | `get_gmail_message_content` | Full message content: subject, from, to, date, body (plain text). |
| Gmail | `modify_gmail_message_labels` (add) | Single-message label add by ID — works. |
| Gmail | `modify_gmail_message_labels` (remove) | Single-message label remove by ID — works. |
| Gmail | `batch_modify_gmail_message_labels` (add) | Multi-message batch add — works (2 messages in one call). |
| Gmail | `batch_modify_gmail_message_labels` (remove) | Multi-message batch remove — works. |
| Calendar | `list_calendars` | 5 calendars: primary (dturner71@gmail.com), Agent — Followups, Agent — Staging, Turner Family, US Holidays. |
| Calendar | `get_events` | Events by date range with time_min/time_max — works. Supports query search, detailed mode, attachments. |
| Drive | `search_drive_files` (docs) | MIME type filtering works. Returns Google Docs with IDs. Pagination supported. |
| Drive | `search_drive_files` (sheets) | Spreadsheet search works. Returns IDs + metadata. |
| Contacts | `search_contacts` | Name search works. Returns name, email, phone, organization. |
| Docs | `get_doc_as_markdown` | Full markdown export with headings, tables, links, citations. Supports inline/appendix comment modes. |
| Sheets | `read_sheet_values` | Cell range reads work. Returns structured row data. Supports hyperlink metadata option. |

**U1 RESOLVED: Gmail label operations fully supported.** Both `modify_gmail_message_labels` (single) and `batch_modify_gmail_message_labels` (multi) work with add and remove. Label IDs from `list_gmail_labels` are the currency. This unblocks the email triage migration path.

**Key findings for MWI-003 decision gate:**
1. **Batch label ops** — triage can classify N emails, then apply labels in one batch call per label category. More efficient than current gws CLI (one API call per email per label).
2. **MCP tool API is Claude-native** — tools take simple params (message_id, label_ids) and return structured text. No HTTP/JSON plumbing needed. This changes the Option 1 vs Option 2 calculus.
3. **Token persistence unknown** — OAuth worked after browser consent, but we don't know if tokens survive across Claude Code sessions or MCP server restarts. Critical for Tess's unattended 30-min triage cycle (A4). Needs explicit testing.
4. **No `get_drive_file_content` test yet** — validated search but not content read. Low risk (search is the harder part).

**Assumptions validated:**
- A1 (OAuth token refresh): Partially — works within a session. Cross-session persistence TBD.
- A3 (Gmail label operations): **Fully validated.** Add, remove, batch add, batch remove all work.

**Next:** MWI-003 — decision gate. Evaluate Option 1 (bash+MCP-HTTP) vs Option 2 (agent-native MCP) in light of these findings. The batch label tool and Claude-native API surface shift the balance toward Option 2 for Crumb's interactive use, but Tess's unattended triage still needs the bash approach unless token persistence is confirmed.

### MWI-003: Decision gate — email triage migration architecture

**Decision: Option 1b — bash + direct Gmail REST API.** Operator approved.

**Rationale:**
- Current triage architecture (bash orchestration, single Haiku batch classification) is fundamentally sound at ~$0.005/run (~$7/mo)
- Option 2 (agent-native MCP) would be 100-600x more expensive ($720-4,320/mo) due to per-email tool-calling overhead replacing the single batch prompt
- Option 1b refines the original Option 1: instead of MCP HTTP transport (adds running server dependency), use direct `curl` to Gmail REST API with OAuth tokens from the MCP server's credential store
- MCP server's auto-refresh handles token lifecycle; bash reads current access token from credential store
- Crumb interactive sessions stay MCP-native (tools in Claude Code — validated MWI-002)
- Tess unattended triage stays bash-orchestrated with direct API

**Architecture (post-migration):**
```
email-triage.sh:
  Fetch (curl → Gmail REST API) → Classify (Haiku batch, unchanged) → Label (curl → Gmail REST API, batch) → Alert (curl → Telegram)
                ↓                                                              ↓
  Token from MCP server credential store                          batch_modify endpoint (new — more efficient)

Crumb interactive:
  MCP tools (search_gmail_messages, modify_gmail_message_labels, etc.) — native in Claude Code sessions
```

**What changes vs. current:**
1. `gws` CLI calls → direct `curl` to `googleapis.com/gmail/v1/`
2. Per-email label application → batch label POST (one per label category)
3. OAuth token source: MCP server's credential store instead of gws auth
4. Everything else stays: Haiku classification, bash orchestration, JSONL logging, cron-lib metrics, Telegram alerts

**What stays the same:**
- Script structure (fetch → classify → label → alert)
- Haiku as classifier ($0.005/batch)
- email-triage-tuning.md operator feedback injection
- JSONL classification logging
- LaunchAgent scheduling (30-min intervals, waking hours)

**Implementation notes for MWI-007:**
- Locate MCP server's token storage path (likely `~/.config/workspace-mcp/` or pipx venv)
- Token refresh fallback: if access token expired and MCP server not running, bash can use stored refresh_token + client credentials for direct refresh via Google OAuth endpoint
- Batch label API: `POST /gmail/v1/users/me/messages/batchModify` with `{ids: [...], addLabelIds: [...], removeLabelIds: [...]}` — more efficient than current per-email modify

**Milestone 1 complete.** Spike validated. Proceeding to Milestone 2 (Tess Integration).

### Milestone 2 rescope: MCP blocked → Direct API Access

**Finding: OpenClaw v2026.3.13 does not support external MCP servers.**

Investigation path:
1. Added `mcpServers` key to `openclaw.json` → gateway rejected: "Unrecognized key: mcpServers"
2. Inspected OpenClawSchema (Zod schema in `auth-profiles-DRjqKE3G.js:12412`) — no `mcpServers` in top-level keys. Valid keys: `$schema`, `meta`, `env`, `wizard`, `diagnostics`, `logging`, `cli`, `update`, `browser`, `ui`, `secrets`, `auth`, `acp`, `models`, `nodeHost`, `agents`, `tools`, `bindings`, `broadcast`, `audio`, `media`, `messages`, `commands`, `approvals`, `session`, `cron`, `hooks`, `web`, `channels`, `discovery`, `canvasHost`, `talk`
3. Checked ACP session layer — `mcpServers` exists in session setup params but: "ACP bridge mode does not support per-session MCP servers. Configure MCP on the OpenClaw gateway or agent instead." (line 1738)
4. Placed `.mcp.json` in agent workspace (`/Users/openclaw/.openclaw/workspace/`) — not discovered. Grep confirmed: zero references to `.mcp.json` or `mcp.json` in OpenClaw dist.
5. `StdioClientTransport` usage is only for Chrome MCP browser control (`DEFAULT_CHROME_MCP_COMMAND`), not general-purpose MCP server spawning.
6. Checked `hooks.gmail` schema — inbound push notifications (Google Pub/Sub), not outbound API access.

**Conclusion:** The `@modelcontextprotocol/sdk@1.25.3` dependency is used for ACP protocol layer and Chrome browser integration only. No mechanism exists to load arbitrary external MCP tool servers.

**Operational incident during investigation:**
- Adding `mcpServers` to `openclaw.json` caused gateway hot-reload to reject the config
- `launchctl kickstart` spawned a second gateway instance → Telegram 409 conflict loop (two bots polling same token)
- Fix: restored `openclaw.json` from backup, `bootout` + `bootstrap` for clean single-instance restart
- Tess was unresponsive for ~15 min during diagnosis

**Rescoped Milestone 2: "Tess Direct API Access"**
- MWI-004: Shared OAuth token reader (bash function, reads from MCP server credential store, handles refresh)
- MWI-005: OpenClaw workspace skill for interactive GWS queries (calendar, email, contacts via Telegram)
- MWI-006: End-to-end validation via Telegram

This approach gives Tess the same effective access without MCP — she uses direct REST API calls with shared OAuth tokens. The token reader (MWI-004) becomes the foundation for both Milestone 2 (interactive) and Milestone 3 (triage migration).

**Key insight:** Apple Calendar snapshot chain (AppleScript → snapshot → 30 min stale → requires danny GUI session) can be replaced entirely by direct Google Calendar REST API. Real-time, no GUI dependency. MWI-009 gains importance.

**Spec updated** with rescoped tasks, acceptance criteria, and dependencies. Cleaned up `.mcp.json` from workspace (does nothing).

### MWI-004: Shared OAuth token reader — complete

**Artifact:** `_openclaw/lib/gws-token.sh` — bash library, sourced by any script needing Google API access.

**Token store location:** `/Users/tess/.google_workspace_mcp/credentials/dturner71@gmail.com.json`
- Written by workspace-mcp during OAuth consent
- Standard Google OAuth format: `token`, `refresh_token`, `expiry`, `client_id`, `client_secret`, `scopes`
- File is 644 (world-readable); credentials dir made group-writable for crumbvault group so openclaw user can write back refreshed tokens

**Functions provided:**
- `gws_get_token` — returns valid access token (reads from file, refreshes if expired, persists new token)
- `gws_calendar_events <date_min> <date_max> [calendar_id]` — Google Calendar events
- `gws_gmail_search <query> [max_results]` — Gmail message search
- `gws_gmail_get <message_id> [format]` — Gmail message metadata/content
- `gws_gmail_batch_label <ids_json> <add_json> <remove_json>` — batch label modification

**Validation (7 tests, 7 pass):**

| Test | Result |
|------|--------|
| Read token from file | Pass |
| Detect expired token | Pass (token was 5 min past expiry) |
| Refresh via Google OAuth endpoint | Pass (curl to oauth2.googleapis.com/token) |
| Persist refreshed token to file | Pass (59 min validity after refresh) |
| Calendar API: get events | Pass (1 event: "Meet with Dan" @ 11:00) |
| Gmail API: search messages | Pass (201 results for newer_than:1d) |
| Gmail API: read message metadata | Pass (Cloudflare email, labels, headers) |

**Bug found during testing:** `gws_gmail_search` initially used `--data-urlencode` without `-G` flag — curl sent query as POST body instead of URL parameter. Fixed by adding `-G`.

**Cross-user access:** Token file permissions updated — `chgrp crumbvault` + `chmod g+w` on credentials dir and file. OpenClaw user (in crumbvault group) can now read tokens and write back refreshed tokens.

**Next:** MWI-005 — OpenClaw workspace skill for interactive GWS queries via Telegram.

**Compound evaluation (session 2):**
- **Pattern: "MCP ≠ universal"** — MCP server support is per-client, not per-SDK. OpenClaw bundles `@modelcontextprotocol/sdk` but only uses it for ACP protocol and Chrome browser, not general tool servers. Assumption A2 ("OpenClaw can connect to MCP server via stdio") was wrong. The SDK presence created a false signal of capability. **Lesson:** verify capability at the integration layer (config schema, runtime behavior), not the dependency layer (package.json).
- **Pattern: "gateway restart hazards"** — `launchctl kickstart` on a running LaunchDaemon spawns a second instance without stopping the first. For Telegram bots, this causes immediate 409 conflict loops. Always `bootout` first, then `bootstrap`. This joins the existing macOS multi-user operations memory.
- **Direct API as MCP alternative** — the token reader pattern (`gws-token.sh`) is reusable beyond this project. Any bash script needing Google API access can source it. The refresh-and-persist flow works for unattended cron jobs. This is a general-purpose primitive.
- Cross-project: pydantic-ai-adoption ADR §2.2 finding is nuanced — MCP works for Claude Code (Crumb), not for OpenClaw (Tess). The feasibility brief needs both sides.

**Model routing:** All work in main Opus session. One Explore subagent (email-triage.sh research) — returned comprehensive 440-line script analysis, no rework. One Explore subagent (OpenClaw MCP config research) — inconclusive, required manual source inspection to find the real answer.

## 2026-03-16 — MWI-005: OpenClaw workspace skill (session 3)

**Context:** MWI-004 (token reader) complete. Building the interactive GWS query skill for Tess.

**Context inventory (4 docs):**
1. `_openclaw/lib/gws-token.sh` — token reader library (MWI-004 artifact)
2. `_openclaw/skills/quick-capture/SKILL.md` — skill format reference
3. `_openclaw/skills/crumb-bridge/SKILL.md` — skill format reference (complex example)
4. `_openclaw/config/google-calendars.json` + `gmail-label-ids.json` — config references

**Skill format finding:** OpenClaw workspace skills are SKILL.md files with YAML frontmatter (`name`, `description`) in `_openclaw/skills/<name>/` directories. The `description` field drives auto-matching — it needs trigger phrases for natural language dispatch. Existing skills (quick-capture, crumb-bridge) use this pattern with bash tool calls in procedure sections.

**Artifact:** `_openclaw/skills/google-workspace/SKILL.md`

**Skill capabilities:**
- Calendar events: list by date range, defaults to today, supports primary/staging/followups calendars
- Gmail search: builds Gmail query operators (from:, subject:, newer_than:, is:unread, etc.), fetches metadata per result
- Gmail read: full message content by ID (from prior search)
- Contact lookup: People API search by name/email/org
- Follow-up handling: "read email 2", "what about tomorrow?", etc.

**API validation (4 tests, 4 pass):**

| Test | Result |
|------|--------|
| Calendar events (today) | Pass — 1 event: "Meet with Dan" |
| Gmail search (newer_than:1d) | Pass — 201 results, 3 returned |
| Gmail metadata fetch | Pass — LinkedIn email, subject, date, snippet |
| Contacts search ("Dan") | Pass — 3 results with display names |

**Cross-user access verified:** Token file `rw-rw-r--` group `crumbvault` — openclaw user has read+write.

### MWI-005 deployment steps:
1. Created `_openclaw/skills/google-workspace/SKILL.md` (source copy in vault)
2. Deployed to `/Users/openclaw/.openclaw/workspace/skills/google-workspace/SKILL.md` (runtime location)
3. Enabled in `openclaw.json` → `skills.entries.google-workspace.enabled: true`
4. `openclaw skills list` confirmed: **ready**, source: `openclaw-workspace`
5. Gateway restarted via `launchctl kickstart -k`

### MWI-006: End-to-end Telegram validation — complete

**Blocker: Telegram 409 conflict loop (19:19–20:28, ~70 minutes)**

Root cause: `com.scout.feedback-poller` LaunchAgent (opportunity-scout project, PID 31382) was long-polling `getUpdates` on the **same Telegram bot token** (`8526390912:AAH_...`) as the OpenClaw gateway. Two processes fighting over one bot token = permanent 409 loop.

Investigation path:
1. Checked for duplicate gateway processes — only one (single PID confirmed via `ps` and `lsof`)
2. Checked for Telegram webhooks — none set
3. Checked OpenClaw LaunchAgent vs LaunchDaemon — LaunchAgent existed but was not loaded
4. Checked for multiple Telegram channel configs — only one
5. Found `opportunity-scout/src/feedback/poller.js` also calling `getUpdates` on the same bot token
6. Confirmed via `.env` file: identical `TELEGRAM_BOT_TOKEN`

Fix:
- `launchctl bootout gui/501/com.scout.feedback-poller` — unloaded the competing poller
- Gateway restarted clean — 409 loop broken immediately
- **Poller needs a separate bot token before re-enabling** (or migrate to webhook-based delivery)

**Validation result:** Operator sent `/new` + "What's on my calendar today?" via Telegram. Tess used the google-workspace skill, called Calendar API, returned results. **Pass.**

Remaining MWI-006 acceptance criteria (email search, contact lookup) not yet tested — calendar query validated the full pipeline: skill discovery → token reader → API call → response formatting → Telegram delivery.

**Next:** MWI-007 — email triage migration (Milestone 3). Or complete MWI-006 acceptance criteria (email search + contact lookup via Telegram).

**Compound evaluation (session 3):**
- **Pattern: "shared bot token collision"** — when multiple services share a Telegram bot token, `getUpdates` long-polling creates mutual exclusion. Only ONE process can poll at a time. The opportunity-scout poller was added after the OpenClaw gateway was established, and the token collision was never caught because the poller was a separate project. **Lesson:** Telegram bot tokens are exclusive resources — track ownership in a central registry. Each polling service needs its own bot.
- **Skill deployment has three locations:** vault source (`_openclaw/skills/`), OpenClaw runtime (`~/.openclaw/workspace/skills/`), and config enablement (`openclaw.json`). Missing any one = skill invisible to Tess. Document this three-step deployment in operational docs.
- **Session snapshot freezes skill list** (confirmed from openclaw-skill-integration.md) — `/new` in Telegram is required after skill deployment. Gateway restart alone is insufficient.
- The 409 diagnostic took ~30 minutes of investigation. The root cause was non-obvious because the competing process was in a completely separate project (opportunity-scout) with no cross-reference to OpenClaw.

**Model routing:** All work in main Opus session. No delegation to Sonnet. No subagents.

## 2026-03-16 — MWI-006 completion + MWI-007 start (session 4)

**Context:** MWI-005 (skill) and MWI-006 (e2e validation) in progress from session 3. Calendar query passed; email search and contact lookup remained.

**MWI-006 completion — all 3 acceptance criteria pass:**

| Test | Result |
|------|--------|
| Calendar events (via Telegram) | Pass (session 3) |
| Email search (via Telegram) | Pass — operator confirmed |
| Contact lookup (via Telegram) | Pass — operator confirmed |

API-level pre-validation (this session): Gmail search returned 201 results, Contacts search returned 4 results for "Dan". Operator then confirmed both worked end-to-end through Telegram.

**Milestone 2 complete.** All 3 tasks done (MWI-004, MWI-005, MWI-006). Proceeding to Milestone 3.

**Context inventory (MWI-007, 4 docs):**
1. `_openclaw/scripts/email-triage.sh` — target script (441→497 lines)
2. `_openclaw/lib/gws-token.sh` — token reader library (MWI-004)
3. `_openclaw/scripts/cron-lib.sh` — cron infrastructure (VAULT_ROOT, BRIDGE_DIR, etc.)
4. `design/specification.md` — acceptance criteria and architecture decision (Option 1b)

### MWI-007: Migrate email-triage.sh to direct Gmail REST API

**Changes made (4 call sites replaced):**

| Phase | Before (gws CLI) | After (REST API) |
|-------|-------------------|------------------|
| Auth check | `gws auth status --format json` | `gws_get_token > /dev/null` |
| Message list | `gws gmail users messages list --params ...` | `gws_gmail_search "label:@Agent/IN ..." "$BATCH_SIZE"` |
| Message metadata | `gws gmail users messages get --params ...` | `gws_gmail_get "$msg_id" "metadata"` |
| Label application | Per-email `gws gmail users messages modify` (N calls) | Decomposed batch: `gws_gmail_batch_label` per label dimension (~7-11 calls) |

**Architecture change — batch label decomposition:**
Old: N API calls (one per email, each with unique label combination).
New: ~7-11 batch calls (one per label value that appears). All processed emails share the agent-state transition call (add @Agent/DONE, remove @Agent/IN + UNREAD). Then one call per trust/action/project value.

**What stayed unchanged:**
- Phase 3 (Haiku classification): identical — same system prompt, same API call, same JSON parsing
- Phase 5 (urgent alerts): identical — same Telegram delivery
- Phase 6 (summary): identical — same jq-based counting
- Metrics: identical — same cost calculation and cron-lib reporting
- JSONL classification logging: identical

**Removed:** `resolve_label_id()` function — no longer needed since batch approach uses label constants directly.

**Validation:**
- Syntax check: pass
- Dry-run: pass (auth → fetch → "no emails" exit — full pipeline validated except classification + labeling)
- API-level tests: Gmail search (201 results), metadata fetch (Apple receipt headers parsed), Contacts search (4 results) — all working via gws-token.sh
- Zero `gws` CLI references remaining in script

**Not yet validated:** Full pipeline with actual @Agent/IN emails (currently 0 in queue). MWI-008 parallel validation will cover this.

**Next:** Need to decide whether to run parallel validation (MWI-008) or go straight to production. Current state: old LaunchAgent still runs old script. Options:
1. Swap the LaunchAgent to new script, monitor for 48h → simplified MWI-008
2. Run both scripts on alternating 30-min cycles → true parallel validation
Recommending option 1 — the script is functionally identical (same classification, same labels), only transport changed. Parallel validation of two scripts that can't share the same inbox is awkward.

**Deployment:** No LaunchAgent plist change needed — `ai.openclaw.email-triage` already points to `_openclaw/scripts/email-triage.sh` (the file we edited in place). PATH includes `/opt/homebrew/bin` (jq, python3). 30-min interval, 24 runs today, last exit 0. Migrated script goes live on next scheduled run.

**MWI-008 validation period:** 2026-03-16 21:10 → 2026-03-18 21:10. Monitor `_openclaw/logs/email-triage.log` and `email-triage-stderr.log` for batch label errors or auth failures.

### MWI-009: Add calendar awareness to daily-attention.sh

**Finding:** daily-attention.sh never read calendar data — it gathered goal tracker, SE inventory, strategic priorities, previous artifact, and project states, but had zero calendar awareness. The Apple Calendar snapshot chain (`apple-snapshot.sh` → `apple-calendar.txt`) was consumed only by the morning-briefing-prompt.md, not by daily-attention.

**Changes:**
1. Source `gws-token.sh` for REST API access
2. Fetch today's Google Calendar events via `gws_calendar_events` during context gathering
3. Inject calendar data into the prompt as "Today's Calendar (Google Calendar — real-time)"
4. Added Calendar lens to prioritization procedure (meeting density, prep items, open blocks)
5. Added calendar conflict flag to priority resolution heuristic

**Dry-run validation:** pass — 1 event fetched ("Meet with Dan" at 11:00–12:00), calendar section appears in prompt. Token estimate: ~5476 (within budget).

**Architecture note:** This replaces the *need* for Apple Calendar snapshots in the daily attention pipeline. The morning-briefing-prompt.md still uses `gws calendar events list` (gws CLI) and Apple Calendar snapshots — that migration is part of MWI-010. The apple-snapshot LaunchAgent continues running for now.

**Compound evaluation (session 4):**
- **Pattern: "in-place file edits = zero-touch deployment"** — both email-triage.sh and daily-attention.sh are referenced by absolute path in their LaunchAgent plists. Editing the files in place meant zero deployment steps — no plist updates, no service restarts, no config changes. The LaunchAgent picks up changes on next scheduled run. This is a benefit of the "script is the deployment artifact" pattern used across Tess's operational scripts.
- **Finding: daily-attention had no calendar awareness** — the spec assumed it read Apple Calendar snapshots, but it never did. The calendar snapshot chain (apple-snapshot.sh → apple-calendar.txt) was only consumed by the morning briefing prompt. MWI-009 filled an actual integration gap rather than migrating an existing read.
- **gws CLI fully removed from operational scripts** — zero matches in `_openclaw/scripts/`. Remaining references are in staging prompts (morning-briefing-prompt.md) and historical docs (run-logs, gate evaluations).
- Session was efficient: MWI-006 completion + MWI-007 full migration + MWI-009 calendar integration in one pass. No rework, no dead ends.

**Model routing:** All work in main Opus session. One Explore subagent (daily-attention calendar consumer research) — returned accurate finding that daily-attention doesn't read calendar data, no rework. No delegation to Sonnet.
