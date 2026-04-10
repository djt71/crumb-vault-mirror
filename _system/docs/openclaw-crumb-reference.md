---
type: reference
domain: software
status: draft
created: 2026-02-18
updated: 2026-02-18
tags:
  - openclaw
  - infrastructure
  - integration
---

# OpenClaw + Crumb Integration Reference

Quick-reference for the colocation of Crumb (governed vault + Claude Code) and OpenClaw
(always-on autonomous agent) on a single Mac Studio. For full rationale, threat model, and
hardening tiers, see the [colocation spec](openclaw-colocation-spec.md).

## 1. Integration Architecture Overview

Both systems run on the same Mac Studio M3 Ultra under separate macOS users.

| Aspect | Crumb | OpenClaw |
|--------|-------|----------|
| Runtime | Claude Code (interactive) | Node.js gateway (daemon) |
| macOS user | Primary user | Dedicated `openclaw` user |
| Execution model | On-demand sessions | Always-on via LaunchAgent |
| LLM keys | `~/.config/crumb/.env` | `/Users/openclaw/.openclaw/openclaw.json` |
| Primary workspace | `~/crumb-vault/` (full R/W) | `~/.openclaw/workspace/` |
| Network binding | Outbound only | Loopback (`127.0.0.1:18789`) + messaging APIs |

**Two-layer security model:**

1. **OS-level (Tier 1, mandatory):** Dedicated `openclaw` macOS user enforces filesystem
   isolation via Unix permissions. Credential files are inaccessible across users.
2. **Application-level (defense-in-depth):** `workspaceOnly` restricts the LLM's
   tool-invoked file operations. Its failure is non-catastrophic because the OS layer
   is the backstop.

Credential stores are fully separated -- no shared `.env`, no cross-user access.

## 2. Vault Access Model

```
~/crumb-vault/
  ├── (all vault dirs)    ── Crumb: R/W │ OpenClaw: R (via crumbvault group)
  ├── _openclaw/
  │   ├── inbox/          ── OpenClaw: R/W │ Crumb: R/W
  │   ├── outbox/         ── OpenClaw: R/W │ Crumb: R/W
  │   └── outbox/.pending/── OpenClaw: R/W (staging; ignored by Obsidian)
  └── .env, ~/.ssh/, etc. ── Crumb: R/W │ OpenClaw: NO ACCESS
```

**How it works:**

- Shared `crumbvault` group grants OpenClaw recursive **read** access to the vault
  (`chgrp -R crumbvault ~/crumb-vault && chmod -R g+rX,g-w ~/crumb-vault`).
- **Write access** is restricted to `_openclaw/` only
  (`chmod -R g+rwX ~/crumb-vault/_openclaw`).
- A **vault skill** in OpenClaw curates what content the LLM actually sees. It enforces
  allowlisted paths, size limits (50 KB/file, 5 files/request), and API key redaction.
  This is a **curation layer, not a security boundary** -- the OS permissions are the real control.
- Credential files (`~/.config/crumb/.env`, `~/.ssh/`) are owned by the primary user
  with no group read -- invisible to the `openclaw` user even if `workspaceOnly` is bypassed.

## 3. Exchange Formats

### Directory Structure

| Path | Purpose | Git-tracked? |
|------|---------|-------------|
| `_openclaw/inbox/` | Crumb writes requests for OpenClaw | Phase 1: no; Phase 2+: yes |
| `_openclaw/outbox/` | OpenClaw writes results for Crumb | Phase 1: no; Phase 2+: yes |
| `_openclaw/outbox/.pending/` | Staging area for atomic writes | Never (hidden dir) |
| `_openclaw/.write-lock` | Lock file for git coordination | Never |

### Phase 2 Lock Protocol (Atomic-Write)

Prevents git index corruption when both systems touch `_openclaw/`.

1. OpenClaw acquires `_openclaw/.write-lock` (via `O_CREAT|O_EXCL` -- atomic create)
2. Writes to a temp file in `_openclaw/outbox/.pending/`
3. Atomically renames to final location (e.g., `_openclaw/outbox/msg-001.json`)
4. Deletes `_openclaw/.write-lock`
5. Crumb's pre-commit hook checks for `.write-lock` -- if present, polls every 100 ms
   for up to 5 seconds, then warns and proceeds if the lock is stale

**Gate:** Protocol must pass a concurrent write load test (100+ writes during git
operations) before Phase 2 activation.

### File Naming

Files in `inbox/` and `outbox/` follow the pattern: `{type}-{NNN}.json`
(e.g., `msg-001.json`, `research-req-002.json`).

## 4. Use Case Allocation

### OpenClaw handles

| Capability | Notes |
|-----------|-------|
| Always-on messaging | Telegram, WhatsApp, Signal, Discord via burner accounts |
| Proactive monitoring | Cron-scheduled checks, event webhooks |
| Research delegation | Accepts research requests from Crumb inbox, writes results to outbox |
| Mobile vault access | Read vault context via vault skill; respond on messaging platforms |
| Lightweight automation | Scheduled tasks, notifications, triage |

### Crumb handles

| Capability | Notes |
|-----------|-------|
| Governed vault operations | All vault writes (except `_openclaw/`), YAML frontmatter, summaries |
| Spec / design / implementation | Full four-phase software workflow |
| Skill execution | Claude Code skills, subagents, overlays |
| Interactive sessions | Claude Code terminal sessions with the operator |
| Compound engineering | Insight extraction, pattern routing, knowledge base curation |
| Git governance | Commits, branch management, pre-commit hooks |

### Boundary rules

- Crumb is the **sole authority** over vault content outside `_openclaw/`.
- OpenClaw never commits to git directly -- it writes to `_openclaw/` and Crumb
  integrates during interactive sessions.
- Browser automation is **OpenClaw only** (Phase 3+), with a domain allowlist
  and human-confirm gate for unknown domains.
- CLI escalation (Phase 3): OpenClaw may invoke `claude` CLI for governed operations
  with careful scoping.

## 5. Phase Roadmap

| Phase | Name | Key deliverables |
|-------|------|-----------------|
| **1** | OS isolation + LaunchAgent | Dedicated `openclaw` user, LaunchAgent/Daemon tested on Studio, Tier 1 hardening, kill-switch runbook validated, `_openclaw/` gitignored |
| **2** | Shared filesystem + vault skill + cron sync | `_openclaw/` added to git, vault skill with allowlist/denylist, cron sync, lock protocol tested under load, Tailscale Serve (optional) |
| **3** | Bidirectional exchange + research delegation | Inbox processing from `_openclaw/outbox/`, research delegation protocol, event webhooks |
| **4** | CLI escalation + browser validation | `claude` CLI invocation from OpenClaw, browser automation with domain allowlist + dedicated profile, monthly allowlist review |

**LaunchAgent vs. LaunchDaemon:** Test LaunchAgent with `bootstrap` first on the Studio.
Fall back to LaunchDaemon with `UserName` if boot-start reliability is insufficient.
Neither option runs as root. See [colocation spec -- Key Decisions](openclaw-colocation-spec.md)
for details.

## 6. Key Links

| Resource | Path |
|----------|------|
| Colocation specification | [_system/docs/openclaw-colocation-spec.md](openclaw-colocation-spec.md) |
| Spec summary | [_system/docs/openclaw-colocation-spec-summary.md](openclaw-colocation-spec-summary.md) |
| Migration runbook | `~/downloads/crumb-studio-migration.md` |
| Kill-switch runbook | [Messaging Platform Kill-Switch Runbook](openclaw-colocation-spec.md) (spec appendix) |
| Project tracker | [[Projects/openclaw-colocation/progress/run-log\|Projects/openclaw-colocation/]] |
| Crumb spec -- OpenClaw entry | [_system/docs/crumb-design-spec-v2-0.md](crumb-design-spec-v2-0.md) (spec section 9, "OpenClaw integration") |
| Peer reviews | [[2026-02-18-openclaw-colocation-spec\|Projects/openclaw-colocation/reviews/]] (R1, R2, R3 from 2026-02-18) |
