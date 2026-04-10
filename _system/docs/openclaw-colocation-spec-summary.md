---
type: specification-summary
domain: software
skill_origin: systems-analyst
status: draft
source_updated: 2026-02-26
created: 2026-02-18
updated: 2026-02-26
tags:
  - openclaw
  - security
  - infrastructure
  - migration
---

# OpenClaw + Crumb Colocation — Specification Summary

## Problem

Running OpenClaw (always-on autonomous AI agent) alongside Crumb (governed vault + Claude Code) on one Mac Studio introduces security surface that must be addressed before deployment. OpenClaw has had 6 GitHub Security Advisories in 3 weeks, a CVSS 8.8 RCE (CVE-2026-25253), active infostealer targeting, and 341 confirmed malicious skills — making security the primary design driver.

## Core Security Architecture

Two-layer isolation model:
1. **OS-level (Tier 1, mandatory):** Dedicated `openclaw` macOS user provides filesystem isolation via Unix permissions. OpenClaw cannot read Crumb credentials, SSH keys, or any primary user files. Vault read access via shared `crumbvault` group (recursive); write access restricted to `_openclaw/` only. TCC is not relied upon — Unix file permissions are the enforcement mechanism.
2. **Application-level (Tier 1):** `workspaceOnly` config restricts the LLM's tool-invoked file operations. This is defense-in-depth — not the primary boundary. Its failure is non-catastrophic because the OS-level user separation is the backstop.

## Core Security Policies

- **P1:** Only manually vetted skills installed. Concrete vetting checklist: reject patterns (eval, exec, out-of-workspace I/O, non-whitelisted network calls), recorded audit trail (skill name, version, hash, vetter, date, outcome).
- **P2:** Stable release channel only; patches within 48h of advisory for first 60 days

## Key Decisions

1. **Dedicated macOS user is Tier 1 mandatory** — the single most impactful control. LaunchDaemon with `UserName: openclaw` in `system/` domain (chosen over LaunchAgent after 2026-02-26 migration — `gui/` domain requires active GUI session, which never exists for the headless service account). Does not run as root.
2. **Vault access model (relaxed):** OpenClaw has OS-level read access to vault via group membership. The "mediated vault skill" is a curation layer, not a security boundary. Vault content is readable; credentials are not. Vault skill contract specifies allowlisted/denylisted paths, size limits, and API key redaction.
3. **Credential separation:** Crumb keys at `~/.config/crumb/.env`, OpenClaw keys in `/Users/openclaw/.openclaw/`. No shared `.env`. No cross-user access.
4. **Wrapper script for launchd:** `launch-openclaw.sh` adds `/opt/homebrew/bin` to PATH and runs `exec openclaw daemon`. Both users share Homebrew Node (≥22.12.0). nvm is a future contingency only if Homebrew Node diverges from OpenClaw requirements.
5. **Browser automation disabled** until Phase 3 enablement checklist (includes domain allowlist config in `openclaw.json`)
6. **Remote access disabled** until Phase 2, then Tailscale Serve only (not Funnel)
7. **Burner accounts** for messaging platforms initially
8. **Atomic-rename protocol** for Phase 2 git integration (write to temp, rename to final — no lock file needed; T5 is LOW risk and git handles concurrent file writes outside the index)
9. **Global emergency stop** + per-platform kill-switch runbook (go-live prerequisite) with correct `launchctl bootout`/`bootstrap` commands
10. **Explicit risk acceptance** for residual prompt injection via messaging platforms
11. **Egress control** via Little Snitch / LuLu at Tier 2 — restricts OpenClaw outbound to messaging + LLM API domains only

## Threat Model (11 colocation + 7 bridge threats)

| Threat | Severity | Key Mitigation |
|--------|----------|----------------|
| T1. Prompt injection via messaging | HIGH | Pairing mode + workspace-only + user isolation + risk acceptance. **Bridge impact:** blast radius escalates from sandbox to vault writes; mitigated by confirmation echo, hash-bound code, operation allowlist |
| T2. Malicious skill installation | HIGH | Policy P1 — vetted skills only |
| T3. Infostealer targeting config | MEDIUM | File permissions + Gatekeeper + loopback |
| T4. Lateral movement to Crumb creds | HIGH | Dedicated user (OS) + workspaceOnly (app). v2026.2.24: multiple app-layer vectors closed; exec validates binary paths + strips dangerous env vars. **Bridge impact:** indirect path via `_openclaw/inbox/` → Crumb sessions (Phase 2) |
| T5. Git index corruption | LOW | gitignore `_openclaw/` until Phase 2; atomic rename |
| T6. Browser automation abuse | MEDIUM | Disabled until Phase 3 checklist + domain allowlist |
| T7. npm supply chain | MEDIUM | Pin versions, SBOM snapshot, audit |
| T8. Remote access misconfig | MEDIUM | Disabled until Phase 2, Serve-only |
| T9. Resource exhaustion / DoS | MEDIUM | Monitoring + launchd resource limits |
| T10. Log/diagnostic exfiltration | MEDIUM | Minimal logging + user isolation |
| T11. Messaging account takeover | MEDIUM / HIGH Phase 2 | Burner accounts + 2FA + kill-switch. **Bridge impact:** Phase 2 automation removes visual inspection backstop → escalates to HIGH |
| BT1. Telegram injection surviving echo | HIGH | Confirmation echo + hash-bound code + operation allowlist |
| BT2. Confirmation echo bypass | MEDIUM | JSON-in-echo (hard requirement) + hash binding + ASCII-only |
| BT3. Governance degradation (automated) | HIGH | Two-tier verification: runner-side hash + canary check |
| BT4. Transcript injection / log poisoning | MEDIUM | Crumb writes own transcripts + run-log outside `_openclaw/` |
| BT5. Bridge flooding / DoS | LOW | Rate limiting + confirmation throttle |
| BT6. NLU misparse / ambiguous intent | HIGH | JSON-in-echo + hash-bound code + strict field validation |
| BT7. Tess process compromise | HIGH | Operation allowlist + schema validation + kill-switch file |

## Hardening Tiers

- **Tier 1 (mandatory, 12 items):** Loopback binding, pairing mode, workspace-only, browser off (note: `tools.browser` not a valid config key in v2026.2.25 — dedicated-user boundary is the primary browser control), credential permissions, separate key stores, doctor + audit, stable channel, verification checks, **dedicated macOS user + LaunchDaemon**. **v2026.2.17→v2026.2.25 evolution:** app-level hardening across 8 releases (heredoc bypass, shell env injection, exec path pinning, hardlink rejection, SSRF), gateway auth key migrated (`gateway.auth.token`), subagent spawn depth pinned to 1, heartbeat directPolicy config, branding `bot.molt`→`ai.openclaw`, daemon restart hardened, supervisor migrated to LaunchDaemon `system/` domain with execution corrections (node path, xattr lifecycle)
- **Tier 2 (recommended, 7 items):** Vetted skills only, gitignore `_openclaw/`, burner accounts, remote access off, disk monitoring, patching SLA, **egress control (Little Snitch / LuLu)**
- **Tier 3 (optional, 2 items):** Docker containerization, macOS PF firewall rules (kernel-level egress, stronger than Tier 2 app-layer)

## Vault Integration Updates (v2026.2.25)

**Pairing** is now a primary guardrail — shared token + pairing, scoped to loopback. `openclaw security audit` is a first-class maintenance primitive (run after every upgrade). Kilo Gateway / `kilocode` provider available but not enabled.

## Migration Runbook Impact

Two installation paths (Day 1 or Phased). New phase covers: dedicated user creation, Homebrew Node verification, OpenClaw install, wrapper script with pre-test, LaunchDaemon creation from onboard's LaunchAgent (add `UserName`, `GroupName`, `ThrottleInterval`, `WorkingDirectory`; node path must be `/opt/homebrew/bin/node`; strip `com.apple.provenance` xattr as last step before bootstrap), Tier 1 hardening, recursive vault permissions (shared group + setgid for group inheritance on new files), diagnostics, mandatory permission isolation test suite (go/no-go gate before messaging setup), messaging setup, verification. Kill-switch runbook uses `launchctl bootout system/ai.openclaw.gateway`.

## Tasks (12 — all complete)

OC-001 through OC-012: runbook update, setup script, directory scaffold, spec §9 update, Node compatibility test, reference doc creation, messaging kill-switch procedures, OpenClaw installation on Studio, Tier 1 hardening, vault permissions with crumbvault group + setgid, isolation test suite (9/9 pass), Telegram bot connected with pairing mode.

## Peer Review

Three rounds (2026-02-18) by GPT-5.2, Gemini 2.5 Pro / 3 Pro Preview, and Perplexity Sonar Reasoning Pro. Round 1 consensus: workspace-only insufficient — dedicated user essential. Round 2 consensus: nvm path brittle (use wrapper script), TCC irrelevant (Unix perms are the control), vault read model needs consistency (resolved: relaxed model), dedicated user should be Tier 1 mandatory. Round 3 consensus: nvm not installed for openclaw user (runbook blocker), plist label unverified, wrapper script untested before loading, permission tests should be mandatory gate, LaunchDaemon with `UserName` is a valid non-root option. Architecture affirmed — findings shifted from design to implementation readiness. Full reviews at `_system/reviews/2026-02-18-openclaw-colocation-spec.md`, `_system/reviews/2026-02-18-openclaw-colocation-spec-r2.md`, and `_system/reviews/2026-02-18-openclaw-colocation-spec-r3.md`.
