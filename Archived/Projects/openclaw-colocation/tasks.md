---
type: task
project: openclaw-colocation
domain: software
created: 2026-02-18
updated: 2026-02-19
source: docs/openclaw-colocation-spec.md
tags:
  - openclaw
  - security
  - infrastructure
  - migration
---

# OpenClaw Colocation — Tasks

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| OC-001 | Update Studio migration runbook with OpenClaw installation phase | done | OC-003 | low | writing | Runbook file contains OpenClaw phase with: dedicated user creation, nvm install, wrapper script, plist config, Tier 1 hardening steps, isolation test suite, and verification commands |
| OC-002 | Add optional OpenClaw health check to setup-crumb.sh | done | OC-001 | low | code | Script detects OpenClaw presence; validates loopback binding, workspaceOnly, and dedicated user when present; exits 0 when OpenClaw is absent |
| OC-003 | Create `_openclaw/` directory scaffold with .gitignore | done | — | low | code | `_openclaw/inbox/`, `_openclaw/outbox/`, `_openclaw/outbox/.pending/` exist; `.gitignore` entry excludes `_openclaw/`; README.md explains access model |
| OC-004 | Update Crumb spec §9 with current threat landscape and dedicated user model | done | — | medium | writing | §9 reflects CVE-2026-25253, dedicated user as Tier 1, relaxed vault read model, kill-switch prerequisite; no Crumb spec summary exists (N/A) |
| OC-005 | Test Node.js version compatibility (MacBook partial, Studio full) | done | Studio available | medium | research | Claude Code works with primary user's Node (v25.6.1 Homebrew); OpenClaw needs ≥22.12.0 (satisfied); both users share Homebrew Node — no nvm needed; wrapper script adds /opt/homebrew/bin to PATH for launchd |
| OC-006 | Create `docs/openclaw-crumb-reference.md` | done | OC-004 | medium | writing | Doc covers integration architecture, exchange formats, use case allocation, vault access model; linked from spec and CLAUDE.md |
| OC-007 | ~~Document messaging platform kill-switch procedures~~ | done | — | low | writing | Kill-switch runbook written inline in spec §Messaging Platform Kill-Switch Runbook |
| OC-008 | Execute OpenClaw installation runbook on Studio | done | OC-001, OC-005, Studio | medium | ops | Dedicated `openclaw` user (uid 502) exists; Homebrew Node v25.6.1 accessible; OpenClaw v2026.2.17 installed; wrapper script tested (gateway starts on ws://127.0.0.1:18789, clean SIGTERM shutdown); plist label: `ai.openclaw.gateway` |
| OC-009 | Apply Tier 1 hardening to OpenClaw config | done | OC-008 | medium | ops | workspaceOnly (fs + exec), browser disabled, loopback binding, password auth, tailscale off, local mode; `openclaw doctor` and `security audit --deep` deferred to OC-011 pre-test diagnostics; gateway password rotation pending |
| OC-010 | Set up vault permissions with shared crumbvault group | done | OC-003, OC-008 | medium | ops | `crumbvault` group exists with both users; vault has recursive group read + setgid (verified — new files inherit crumbvault); `_openclaw/` (incl. inbox/, outbox/, outbox/.pending/) has group write; openclaw.json is 600, .openclaw/ is 700 |
| OC-011 | Run and pass mandatory isolation test suite | done | OC-009, OC-010 | high | ops | All 9 isolation tests pass (4 deny + 2 read + 1 write-deny + 2 sandbox-write); `scripts/openclaw-isolation-test.sh` committed to vault; credential files locked down (chmod 600/700 on .zshrc, .config/crumb/, .config/meme-creator/); setgid verified |
| OC-012 | Connect first messaging platform with burner account | done | OC-011 | medium | ops | Telegram connected, pairing mode active, bot sends/receives; kill-switch dry-run verified (`daemon stop` + `pkill`, restart via `launchctl bootstrap`); openclaw.json 600, .openclaw/ 700; Haiku 4.5 model configured |

Note: OC-009 and OC-010 are parallel — both depend on OC-008, not on each other.
OC-010 also depends on OC-003 (scaffold must exist before permissions are set).
Set up permissions (OC-010) before or alongside hardening (OC-009) so that
`openclaw doctor` doesn't report false failures from missing vault access.

## Task Counts

- **Total:** 12
- **Done:** 12 (OC-001 through OC-012 — all tasks complete)
- **Pending:** 0
- **Pre-migration (Milestones 1-2):** 6 tasks (OC-001 through OC-006)
- **On-Studio (Milestones 3-4):** 5 tasks (OC-005, OC-008 through OC-012)

## Notes

- OC-005 spans milestones: research can begin on current hardware but validation requires Studio
- OC-008 through OC-012 are operator-executed (hands-on-keyboard), not code generation tasks
- Tier 2 hardening is intentionally deferred to post-go-live and not tracked as a task here
- Each task is ≤5 file changes; on-Studio ops tasks affect config files and system state rather than vault files
