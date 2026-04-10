---
type: action-plan
project: openclaw-colocation
domain: software
status: draft
created: 2026-02-18
updated: 2026-02-18
source: docs/openclaw-colocation-spec.md
tags:
  - openclaw
  - security
  - infrastructure
  - migration
---

# OpenClaw Colocation — Action Plan

## Overview

This plan decomposes the approved colocation specification into four milestones that
sequence all work from vault preparation through live platform onboarding. Milestones 1
and 2 can be completed on the current machine (MacBook). Milestones 3 and 4 require the
Mac Studio hardware.

The spec defined OC-001 through OC-007 (with OC-007 already complete). This plan
preserves those IDs and adds OC-008 through OC-012 for on-Studio execution work that
the spec described in prose but did not assign task IDs.

**Workflow note:** The project-state.yaml specifies four-phase (SPECIFY → PLAN → TASK →
IMPLEMENT). Given that tasks are already atomic (≤5 file changes each, clear acceptance
criteria), the TASK phase can be a lightweight validation pass rather than further
decomposition. Recommend advancing directly to IMPLEMENT after plan approval.

---

## Milestone 1: Vault Preparation

**Goal:** Create the `_openclaw/` directory scaffold in the vault so it exists before
Studio migration and permissions setup.

**Success criteria:** `_openclaw/` directory exists with inbox/outbox subdirectories,
`.gitignore` excludes it from tracking, and a README explains the access model.

**Dependencies:** None — can start immediately.

### Phase 1.1: Create Directory Scaffold (OC-003)

Create `_openclaw/` with:
- `inbox/` and `outbox/` subdirectories (per spec §Vault Integration Architecture)
- `outbox/.pending/` hidden subdir (per Phase 2 lock protocol)
- `.gitignore` at vault root entry to exclude `_openclaw/`
- `_openclaw/README.md` explaining purpose and access model

---

## Milestone 2: Documentation & Tooling

**Goal:** Produce all written artifacts and script updates needed before Studio execution.
The migration runbook is the primary deliverable — it drives Milestone 3.

**Success criteria:** Migration runbook has a complete OpenClaw installation phase,
`setup-crumb.sh` has an optional OpenClaw health check, spec §9 is current, and the
reference doc exists.

**Dependencies:** Milestone 1 (scaffold must exist so runbook can reference it).

### Phase 2.1: Update Migration Runbook (OC-001)

Integrate the spec's "Migration Runbook Impact" section into the actual Studio migration
runbook (`~/downloads/crumb-studio-migration.md`). This includes:
- OpenClaw installation phase (dedicated user, nvm, wrapper script, plist)
- Tier 1 hardening checklist
- Mandatory isolation test suite (go/no-go gate)
- Updates to existing phases (Brew, Shell config, Config files, Backup)

### Phase 2.2: Update setup-crumb.sh (OC-002)

Add optional OpenClaw health check to the validation script:
- Detect OpenClaw presence
- Validate hardening config (loopback binding, workspaceOnly, dedicated user)
- Report status without failing if OpenClaw is not installed

**Depends on:** OC-001 (runbook defines what setup-crumb.sh should validate).

### Phase 2.3: Update Crumb Spec §9 (OC-004)

Update the main Crumb design spec's §9 (OpenClaw integration) to reflect:
- Current threat landscape (CVEs, malicious skills)
- Dedicated user model (Tier 1 mandatory)
- Vault access architecture (relaxed read model with group permissions)
- Kill-switch runbook as go-live prerequisite

### Phase 2.4: Create Reference Document (OC-006)

Create `docs/openclaw-crumb-reference.md` covering:
- Integration architecture overview
- Exchange formats (inbox/outbox)
- Use case allocation (what OpenClaw handles vs. what Crumb handles)
- Vault access model summary
- Links to spec, runbook, and kill-switch procedures

**Depends on:** OC-004 (spec §9 update provides canonical architecture language).

---

## Milestone 3: On-Studio Installation & Hardening

**Goal:** OpenClaw is installed on a dedicated macOS user with Tier 1 hardening applied
and all isolation tests passing.

**Success criteria:** All 9 isolation tests pass (go/no-go gate), `openclaw doctor` reports
no issues, `openclaw security audit --deep` completes with no critical findings.

**Dependencies:** Milestone 2 (runbook must be complete), Studio hardware available.

**Prerequisite:** Create a full, verified system backup (Time Machine snapshot or
equivalent) before beginning any M3 work. M3 modifies system-level state (user creation,
launchd, filesystem permissions) and must have a recovery checkpoint.

**Rollback procedure (if OC-011 fails):**
1. Revert vault permissions: `chgrp -R staff ~/crumb-vault && chmod -R g-w ~/crumb-vault`
2. Remove crumbvault group: `sudo dseditgroup -o delete crumbvault`
3. Unload LaunchAgent/Daemon: `sudo -u openclaw launchctl bootout gui/$(id -u openclaw)/com.openclaw.daemon`
4. Optionally remove openclaw user: `sudo sysadminctl -deleteUser openclaw`
5. Restore from Time Machine snapshot if needed
6. Document failure root cause in run-log before retrying

### Phase 3.1: Node.js Compatibility Testing (OC-005)

Partially executable on current MacBook (Claude Code Node requirements, nvm isolation
concept). Full validation requires Studio (nvm-under-separate-user, LaunchAgent non-interactive
shell environment). OC-005 is an explicit dependency of OC-008.

Test that:
- Claude Code works with the primary user's Node installation
- OpenClaw works with Node ≥22 via nvm under the `openclaw` user
- Both can coexist via separate nvm installations
- LaunchAgent non-interactive shell correctly sources nvm

### Phase 3.2: Execute Installation Runbook (OC-008)

Follow the migration runbook's OpenClaw phase:
1. Create dedicated `openclaw` macOS user
2. Install nvm + Node ≥22 for `openclaw` user
3. Install OpenClaw, run onboard
4. Create and test wrapper script (`launch-openclaw.sh`)
5. Verify plist, record LaunchAgent label

### Phase 3.3: Apply Tier 1 Hardening + Vault Permissions (OC-009, OC-010 — parallel)

These two tasks both depend on OC-008 and can execute in parallel. Vault permissions
(OC-010) should be set up before or alongside hardening (OC-009) because `openclaw doctor`
in OC-009 may check vault access and report false failures if permissions aren't configured.

**OC-009 — Apply Tier 1 Hardening:**
- Loopback binding, pairing mode, workspaceOnly
- Browser disabled, credential permissions
- Separate key stores, diagnostics, stable channel
- Verification checks

**OC-010 — Set Up Vault Permissions** (depends on OC-003 — scaffold must exist before permissions are set)**:**
- Create shared `crumbvault` group with both users
- Recursive group read on vault
- Write access only to `_openclaw/` (including `inbox/`, `outbox/`, `outbox/.pending/`)
- Credential files locked down (`chmod 600`)

### Phase 3.4: Run Isolation Test Suite (OC-011)

Execute the mandatory 9-test isolation suite via `_system/scripts/openclaw-isolation-test.sh`
(created during OC-001/OC-002). Script produces timestamped output to
`Projects/openclaw-colocation/progress/isolation-test-{date}.txt`.

Tests:
- MUST FAIL: openclaw reads `~/.config/crumb/.env` (credential isolation)
- MUST FAIL: openclaw reads `~/.ssh/` (SSH key isolation)
- MUST FAIL: openclaw reads `~/.zshrc` (shell env isolation)
- MUST FAIL: openclaw reads `~/Library/Keychains/` (keychain isolation)
- MUST SUCCEED: openclaw reads vault `docs/` (group read access)
- MUST SUCCEED: openclaw reads `CLAUDE.md` (group read access)
- MUST FAIL: openclaw writes to vault root (write boundary)
- MUST SUCCEED: openclaw writes to `_openclaw/` (sandbox write)
- MUST SUCCEED: openclaw creates directory in `_openclaw/` (sandbox mkdir)

**This is a GO/NO-GO gate.** Do not proceed to Milestone 4 until all tests pass.
If any test fails, follow the M3 rollback procedure above.

---

## Milestone 4: Platform Onboarding

**Goal:** At least one messaging platform connected via burner account, with kill-switch
procedures verified.

**Success criteria:** One platform sends/receives test messages, kill-switch dry-run
verified (gateway stops, credentials revoked, baseline state restored within 5 minutes).

**Dependencies:** Milestone 3 (isolation tests must pass).

### Phase 4.1: Messaging Platform Setup (OC-012)

1. Create burner accounts for initial platform(s)
2. Connect first platform (recommend Telegram — simplest bot token model)
3. Send/receive test messages
4. Dry-run the kill-switch procedure for the connected platform
5. Connect additional platforms as needed

### Phase 4.2: Tier 2 Hardening (deferred — post-go-live)

Apply recommended hardening after initial stability:
- Egress control (Little Snitch / LuLu)
- Disk monitoring
- Patching SLA tracking
- Gitignore review for `_openclaw/`

---

## Risk Summary

| Milestone | Overall Risk | Key Risk |
|-----------|-------------|----------|
| M1: Vault Prep | Low | Minimal — scaffold only |
| M2: Documentation | Low | Runbook accuracy — mitigated by spec's 3 review rounds |
| M3: Installation | Medium | LaunchAgent vs LaunchDaemon decision (test-first); nvm path issues; permission misconfiguration |
| M4: Onboarding | Medium | Messaging auth complexity; prompt injection (accepted residual risk) |

## Dependency Graph

```
Track A (runbook):
  OC-003 (scaffold) ── OC-001 (runbook) ──┬── OC-002 (setup script)
                                           │
Track B (docs):                            │                    ┌── OC-009 (harden) ──┐
  OC-004 (spec §9) ── OC-006 (ref doc)    ├── OC-008 (install) ┤                     ├── OC-011 (gate) ── OC-012 (messaging)
                                           │                    └── OC-010 (perms) ───┘
                                           │                         ▲
  OC-005 (Node compat) ──────────────────┘                          │
                                                                OC-003 (scaffold)
  OC-007: DONE (kill-switch runbook)

  Track A and Track B are parallel. OC-010 also depends on OC-003 (scaffold must exist
  before permissions are set).
```
