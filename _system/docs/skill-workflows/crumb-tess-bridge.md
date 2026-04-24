---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
tags:
  - system
  - openclaw
topics:
  - moc-crumb-architecture
---

# Crumb-Tess Bridge

Crumb is session-bound (Claude Code, terminal); Tess is always-on (OpenClaw, Telegram). The bridge lets Tess relay governed operations to Crumb via atomic file exchange so phone-based interactions can trigger full vault work.

## Who Owns What

| | Crumb | Tess |
|---|---|---|
| Runtime | Session-bound | Always-on |
| Vault access | Full governed read/write | Read all; write to `_openclaw/` only |
| Architecture & design decisions | Yes — sole authority | No |
| Workflow execution (SPECIFY → IMPLEMENT) | Yes | No |
| Phase gate execution | Yes | Relays your approval via bridge |
| Convergence, peer review, compound engineering | Yes | No |
| Inbox triage and quick lookups | Can, but expensive | Yes — primary function |
| Monitoring and routine automation | No | Yes |
| Session logging | Yes | No — Crumb logs, Tess relays |

## How Requests Flow

**Tess → Crumb:** Telegram message → Tess parses intent → crumb-bridge skill validates + hashes payload → confirmation echo to user → user sends `CONFIRM <hash>` → Tess writes request to `_openclaw/inbox/` → Crumb picks up at next session → writes response to `_openclaw/outbox/` → Tess relays to Telegram.

**Crumb → Tess:** Crumb writes project state to vault. Tess reads on your next ping.

Transport: `_openclaw/inbox/` (Tess → Crumb), `_openclaw/outbox/` (Crumb → Tess). The filesystem is the security boundary — Tess never invokes `claude` directly.

## Common Operations

| Operation | Type | Confirmation |
|-----------|------|:---:|
| `query-status` — project phase and state | Phase 1 (immediate) | No |
| `query-vault` — read a vault file | Phase 1 (immediate) | No |
| `list-projects` — all active projects | Phase 1 (immediate) | No |
| `approve-gate` / `reject-gate` — phase transitions | Phase 1 (immediate) | Yes |
| `start-task` — begin a project task | Phase 2 (dispatch, minutes) | Yes |
| `invoke-skill` — trigger a Crumb skill | Phase 2 (dispatch, minutes) | Yes |
| `quick-fix` — targeted fix to a project | Phase 2 (dispatch, minutes) | Yes |
| `escalation-response` — answer blocked dispatch | Phase 2 | Yes |
| `cancel-dispatch` — abort running dispatch | Phase 2 | Yes |

Dispatch operations (Phase 2) run via `claude --print` and may take minutes. Tess polls for status updates and escalation questions while they run.

## Bridge Protocol

1. **Parse** — Tess maps natural language to the operation allowlist.
2. **Validate** — bridge CLI checks params and rejects unknown operations.
3. **Hash** — CLI produces a 12-char hex confirmation code from the canonical payload.
4. **Confirm** — Tess sends exact payload + hash to Telegram; user replies `CONFIRM <hash>`. Hash mismatch = abort. (Read-only ops skip this step.)
5. **Write** — request file dropped atomically into `_openclaw/inbox/`.
6. **Watch** — Phase 1: poll 30s timeout. Phase 2: poll with status updates; handle escalations via `ANSWER <id> <options>` shorthand.

Security: ASCII-only params, bidi-override stripping, CLI output never modified.

## Scope

Bridge = governed operations only. Quick-capture was retired 2026-04-24 — see `_system/docs/capture-tiers.md` for the current capture design (Apple Notes as phone inbox, weekly sweep promotion to vault).
