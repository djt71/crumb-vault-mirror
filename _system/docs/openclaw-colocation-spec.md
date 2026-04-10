---
type: specification
domain: software
skill_origin: systems-analyst
status: draft
created: 2026-02-18
updated: 2026-02-26
peer_reviewed: 2026-02-18
review_rounds: 3
review_note: Projects/openclaw-colocation/reviews/2026-02-18-openclaw-colocation-spec.md
review_note_r2: Projects/openclaw-colocation/reviews/2026-02-18-openclaw-colocation-spec-r2.md
review_note_r3: Projects/openclaw-colocation/reviews/2026-02-18-openclaw-colocation-spec-r3.md
tags:
  - openclaw
  - security
  - infrastructure
  - migration
---

# OpenClaw + Crumb Colocation Specification

## Problem Statement

The Mac Studio M3 Ultra (96GB RAM, 1TB SSD) will host both Crumb (governed Obsidian vault + Claude Code) and OpenClaw (always-on autonomous AI agent with messaging interfaces). Running both systems on one machine introduces security surface, filesystem contention, credential exposure, and operational complexity that the current migration runbook and vault spec do not address. OpenClaw's recent CVE history (6 GitHub Security Advisories in 3 weeks, CVE-2026-25253 CVSS 8.8 RCE, infostealer targeting of config files, 341 confirmed malicious skills on ClawHub) makes security the primary design driver.

## Facts

- F1. OpenClaw is a Node.js gateway (requires Node ≥22) that runs as a persistent daemon via launchd on macOS
- F2. OpenClaw binds to `ws://127.0.0.1:18789` by default (loopback only)
- F3. OpenClaw config lives at `~/.openclaw/openclaw.json`; workspace at `~/.openclaw/workspace/`
- F4. OpenClaw connects outbound to messaging platform APIs (WhatsApp/Baileys, Telegram/grammY, Signal/signal-cli, Discord/discord.js, Slack/Bolt)
- F5. OpenClaw includes browser automation via Chrome DevTools Protocol
- F6. CVE-2026-25253 (CVSS 8.8): one-click RCE via malicious link — patched in v2026.1.29
- F7. Infostealers actively target `openclaw.json`, `device.json`, and `soul.md` for gateway tokens and crypto keys
- F8. Prompt injection through messaging platforms is an acknowledged unsolved problem; OpenClaw treats inbound DMs as untrusted input
- F9. Cisco research found 2 critical and 5 high-severity issues in skill ecosystem (silent data exfil, command injection, tool poisoning)
- F10. ClawHub skills install from disk as untrusted code with host-level execution privileges
- F11. GitHub issue #2341 proposed running OpenClaw as a dedicated `_clawdbot` system user via LaunchDaemon — closed but implementation status unclear
- F12. Crumb's vault contains API keys at `~/.config/crumb/.env` (OpenAI, Gemini, Perplexity) and `~/.config/meme-creator/tmdb-api-key`
- F13. Crumb runs as interactive Claude Code sessions (not a daemon); no persistent process
- F14. The Crumb spec §9 plans OpenClaw integration with a sandboxed `_openclaw/` directory in the vault
- F15. Mac Studio has 96GB unified memory and 1TB SSD — ample resources for both systems
- F16. Security researchers recommend "isolation, not hardening" as the primary defense for OpenClaw
- F17. OpenClaw supports `tools.fs.workspaceOnly: true` to restrict file operations to workspace directory
- F18. OpenClaw supports `tools.exec.applyPatch.workspaceOnly: true` to restrict write/delete to workspace
- F19. OpenClaw DM policy defaults to "pairing" mode — unknown senders must be approved via `openclaw pairing approve`
- F20. Tailscale Serve/Funnel is natively supported for remote access (`gateway.tailscale.mode`)

## Core Security Policies

The entire security model is predicated on these mandatory policies:

- **P1. Only manually vetted skills will be installed.** "Vetted" means: source code is published and reviewed before install, skill requests minimal permissions, no obfuscated or compiled-only code, and `openclaw security audit --deep` is run before and after installation. No ClawHub auto-install. No "just try it" installs. Vetting checklist per skill:
  - [ ] Source code is publicly readable (no compiled-only or obfuscated code)
  - [ ] No file read/write calls outside the declared workspace
  - [ ] No `eval()`, `exec()`, `child_process`, or dynamic code execution
  - [ ] No network calls to non-whitelisted domains
  - [ ] Permissions requested match stated purpose (minimal privilege)
  - [ ] Skill is simple enough to audit fully (few files, clear control flow, no dynamic code generation). If complexity exceeds confidence, defer or reject — do not rush vetting to meet a time target
  - [ ] Record: skill name, version, source hash, vetter, date, pass/fail
- **P2. OpenClaw runs on the stable release channel only.** Security patches are applied within 48 hours of advisory publication during the first 60 days, and within one week thereafter. No beta or dev builds on the Studio.

## Assumptions

- A3. **The Studio will be the only machine running OpenClaw** — no multi-node fleet to manage. (Validate: confirm no secondary nodes planned)
- A4. **Messaging platform credentials (WhatsApp session, Telegram bot token, etc.) are acceptable to store on the Studio.** (Validate: user comfort level with messaging auth material on personal hardware)
- A5. **Crumb and OpenClaw share read access to the vault** for contextual information (per the dedicated vault skill in Phase 1). OpenClaw's primary workspace is separate (`~/.openclaw/workspace/`). OpenClaw has write access only to `~/crumb-vault/_openclaw/` for inbox/outbox exchange. The vault is not "shared" in the sense of co-ownership — Crumb governs the vault; OpenClaw has read-only access with a write sandbox. (Validate: confirm integration model hasn't changed)
- A6. **The Studio will primarily be used from the home network**, with remote access as an optional addition. (Validate: user confirms network topology)

## Unknowns

- U1. Whether OpenClaw's `_clawdbot` dedicated user support (issue #2341) is actually usable in current releases
- U2. Exact Node.js version shipping with current OpenClaw stable — need ≥22.12.0 for CVE patches
- U3. Whether OpenClaw's `workspaceOnly` restrictions are reliable under prompt injection (no third-party audit)
- U4. How OpenClaw handles git conflicts if both systems write to the vault concurrently
- U5. ~~Whether macOS TCC can sandbox OpenClaw's filesystem access~~ **Clarified, verification deferred to OC-011:** TCC is per-app, not per-Unix-user — it does not apply to cross-user file access via Unix group permissions. The actual controls are `chmod`/`chown`/`chgrp`. Empirical verification that the `openclaw` user can read vault files via group permissions and cannot read `~/.config/crumb/.env` is covered by the mandatory isolation test suite (OC-011, step 7 in the runbook). Not independently resolved — the isolation tests are the verification mechanism.
- U6. Performance impact of OpenClaw's browser automation on Crumb's Claude Code sessions

## System Map

### Components

```
┌─────────────────────────────────────────────────────┐
│                   Mac Studio M3 Ultra                │
│                                                      │
│  ┌──────────────┐          ┌──────────────────────┐  │
│  │  Crumb        │          │  OpenClaw             │  │
│  │  (Claude Code) │          │  (Node.js Gateway)    │  │
│  │  Interactive   │          │  Always-on daemon     │  │
│  │  sessions      │          │  ws://127.0.0.1:18789 │  │
│  └──────┬───────┘          └──────────┬───────────┘  │
│         │                             │               │
│         ▼                             ▼               │
│  ┌─────────────────────────────────────────────────┐  │
│  │              Shared Vault (~/)                    │  │
│  │  ~/crumb-vault/         (Crumb-governed)         │  │
│  │  ~/crumb-vault/_openclaw/ (OpenClaw sandbox)     │  │
│  └─────────────────────────────────────────────────┘  │
│                                                      │
│  ┌──────────────┐          ┌──────────────────────┐  │
│  │  Credentials  │          │  Credentials          │  │
│  │  ~/.config/   │          │  ~/.openclaw/         │  │
│  │    crumb/     │          │    openclaw.json      │  │
│  │    meme-*/    │          │    device.json        │  │
│  │  ~/.zshrc     │          │  Messaging tokens     │  │
│  │  (ANTHROPIC)  │          │  LLM API keys         │  │
│  └──────────────┘          └──────────────────────┘  │
│                                                      │
│  ┌─────────────────────────────────────────────────┐  │
│  │              Network                             │  │
│  │  Outbound: Anthropic, OpenAI, Google APIs        │  │
│  │  Outbound: WhatsApp, Telegram, Signal, Discord   │  │
│  │  Inbound:  Loopback only (default)               │  │
│  │  Optional: Tailscale overlay network              │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Dependencies

- **OpenClaw → Node.js ≥22**: Both Claude Code and OpenClaw are satisfied by the Homebrew-installed Node (v25.6.1 as of 2026-02-18, well above the ≥22.12.0 requirement). The `openclaw` user uses the same Homebrew Node binary at `/opt/homebrew/bin/node` — no separate version manager needed. A wrapper script adds Homebrew to PATH for launchd (which does not inherit the user's shell environment):
  ```bash
  # /Users/openclaw/launch-openclaw.sh (chmod 700, owned by openclaw)
  #!/bin/bash
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  exec node /Users/openclaw/.local/lib/node_modules/openclaw/dist/index.js gateway --port 18789
  ```
  The LaunchDaemon plist calls the wrapper script:
  ```xml
  <key>ProgramArguments</key>
  <array>
    <string>/Users/openclaw/launch-openclaw.sh</string>
  </array>
  ```
  **If Homebrew Node is ever upgraded to a version OpenClaw doesn't support**, install nvm for the `openclaw` user at that point and update the wrapper script to source `nvm.sh`. This is a future contingency, not a day-1 requirement.
- **OpenClaw → npm ecosystem**: Large transitive dependency tree. Supply chain risk.
- **OpenClaw → Messaging APIs**: External services with auth tokens stored locally.
- **OpenClaw → Vault filesystem**: Read access to vault for context; write access to `_openclaw/` sandbox.
- **Crumb → Claude Code → Anthropic API**: Existing, well-understood dependency.
- **Crumb → Vault filesystem**: Full read/write to all governed directories.
- **Both → LLM API keys**: Separate key sets — Crumb uses Anthropic; OpenClaw uses whatever models are configured.
- **Backup job → Both systems' data**: `vault-backup.sh` must capture vault including `_openclaw/` sandbox.

### Constraints

- C1. **Single-user macOS by default**: Multi-user separation is straightforward on macOS (standard user + LaunchDaemon with `UserName`) and is the recommended approach for reasonable hardening. Docker/containerization adds more complexity.
- C2. **1TB SSD**: Browser automation profiles, messaging media, and vault backups consume disk
- C3. **Solo operator**: No dedicated security team; hardening must be maintainable by one person
- C4. **OpenClaw security posture is immature**: 6 advisories in 3 weeks, malicious skill ecosystem, active infostealer targeting

### High-Leverage Intervention Points

1. **Filesystem isolation** — Restricting OpenClaw's file access is the single highest-impact control. If the agent can't read `~/.config/crumb/.env` or `~/.ssh/`, a compromised skill can't exfiltrate those credentials.
2. **Workspace restriction (defense-in-depth, not primary boundary)** — `tools.fs.workspaceOnly: true` + `tools.exec.applyPatch.workspaceOnly: true` limits the LLM's file operations to the configured workspace. This is an application-enforced control with no third-party audit (U3). It reduces attack surface but must be layered with OS-level isolation (dedicated user) to prevent catastrophic failure from a single bypass.
3. **DM pairing policy** — Keeping the default pairing mode prevents unapproved senders from injecting prompts.
4. **Skill vetting** — Not installing unreviewed ClawHub skills eliminates the largest malware vector.
5. **Credential separation** — Separate API key stores for Crumb and OpenClaw, with no cross-access.

### Second-Order Effects

- Running OpenClaw as a daemon means it persists through reboots — any misconfiguration is persistent
- Browser automation creates a Chromium process with network access that could be abused by prompt injection
- Messaging platform sessions (especially WhatsApp/Baileys) maintain persistent auth that, if stolen, allows impersonation
- OpenClaw's workspace indexing (especially with qmd) will read vault content — this is by design but expands the data accessible through messaging-platform prompt injection
- If OpenClaw writes to `_openclaw/` while Crumb is in a git operation, race conditions on the git index are possible
- **Bridge integration:** The Crumb–Tess bridge (`Projects/crumb-tess-bridge/design/specification.md`) extends the colocation architecture with a Telegram → Tess → `_openclaw/inbox/` → Crumb execution path. This materially changes the blast radius of T1, T4, and T11, and introduces 7 new threats (BT1–BT7) documented in the Bridge Integration Threats subsection below

## Threat Model

### T1. Prompt Injection via Messaging Platform (HIGH)
**Vector:** Attacker sends crafted message via WhatsApp/Telegram/Signal containing hidden instructions.
**Impact:** Agent executes unintended commands — data exfiltration, file modification, credential theft.
**Mitigation:** Pairing mode (default), workspace-only file restrictions, no sensitive credentials in OpenClaw's reachable paths.
**Residual risk:** Acknowledged unsolved problem. Messaging platform integration inherently exposes the LLM to untrusted input.
**Risk acceptance:** The operator accepts the residual risk of prompt injection via messaging platforms. If a prompt injection is suspected, the response is: disconnect the affected platform immediately (see kill-switch procedures in §Messaging Platform Kill-Switch Runbook), rotate all messaging credentials, review `_openclaw/` for unauthorized writes, and check OpenClaw logs for exfiltration attempts.
**Bridge impact:** Pre-bridge, injection impact is bounded to the `_openclaw/` sandbox. Post-bridge, a successful injection can traverse Telegram → Tess → `_openclaw/inbox/` → Crumb → governed vault writes. The blast radius escalates from sandbox contamination to vault corruption. Mitigated by: confirmation echo (user sees exact JSON payload before confirming), hash-bound confirmation code (`payload_sha256[:12]`), operation allowlist (bounds what bridge requests can do), and schema validation. Rating remains HIGH — the mitigations meaningfully bound the escalation. Cross-ref: BT1, BT2, BT6.

### T2. Malicious Skill Installation (HIGH)
**Vector:** ClawHub skill contains hidden command injection, data exfiltration, or supply chain payload.
**Impact:** Full host access if workspace restrictions are not enforced; credential theft, lateral movement.
**Mitigation:** Only install manually vetted skills. Run `openclaw security audit --deep` before and after skill installation.
**Residual risk:** Even manual vetting can miss obfuscated payloads.

### T3. Infostealer Targeting OpenClaw Config (MEDIUM)
**Vector:** Vidar-family malware searches for `openclaw.json`, `device.json`, `soul.md` containing gateway tokens and crypto keys.
**Impact:** Remote attacker connects to gateway, impersonates legitimate client.
**Mitigation:** macOS Gatekeeper + standard endpoint hygiene. Don't expose gateway port beyond loopback. Encrypted credential storage if OpenClaw supports it (no config key exists as of v2026.1.x — track upstream `openclaw/openclaw` for future support; see §Secrets Management for interim approach).
**Residual risk:** Requires initial malware infection — not OpenClaw-specific.

### T4. Lateral Movement to Crumb Credentials (HIGH)
**Vector:** Compromised OpenClaw skill or prompt injection reads Crumb's API keys from `~/.config/crumb/.env`, Anthropic key from shell environment, or SSH keys from `~/.ssh/`.
**Impact:** Attacker gains access to Anthropic, OpenAI, Gemini, Perplexity APIs billed to the user; potential vault manipulation.
**Mitigation:** Defense-in-depth layering: (1) `tools.fs.workspaceOnly: true` restricts OpenClaw's file reads at the application level, (2) dedicated macOS user provides OS-level filesystem isolation, (3) restrictive file permissions (`chmod 600`) on credential files, (4) separate credential stores with no cross-access.
**Residual risk:** `workspaceOnly` is an unaudited, application-level control. It is the primary defense against vault compromise at the application layer, but its failure — due to a bug, bypass, or prompt injection — would be catastrophic without the OS-level user separation backstop. This combination of application + OS isolation represents the core security architecture.
**v2026.2.24 update:** Multiple application-layer lateral movement vectors closed across releases. The OS boundary (dedicated user) remains important as defense-in-depth but is no longer the sole effective control. Exec tool now validates binary paths and strips dangerous environment variables independently of OS-level controls.
**Bridge impact:** The bridge creates an indirect lateral movement path: a compromised OpenClaw that writes crafted files to `_openclaw/inbox/` can trigger Crumb sessions (Phase 2 automation), causing the primary user's Claude Code to execute attacker-influenced requests. This bypasses the confirmation echo (which protects Telegram→Tess, not Tess→inbox). The operation allowlist and Crumb's schema validation are the backstops. Cross-ref: BT7.

### T5. Git Index Corruption from Concurrent Writes (LOW)
**Vector:** OpenClaw writes to `_openclaw/` while Crumb runs `git add`/`git commit`.
**Impact:** Corrupted git index, failed commits, potential data loss.
**Mitigation:** OpenClaw writes to `_openclaw/` only; Crumb commits only during interactive sessions (user present). Add `.gitignore` entry for `_openclaw/` initially; integrate into git workflow only when the exchange protocol is formalized.
**Residual risk:** Low — git is resilient to concurrent file writes outside the index.

### T6. Browser Automation Abuse (MEDIUM)
**Vector:** Prompt injection instructs browser to visit malicious sites, download payloads, or exfiltrate data through the browser channel.
**Impact:** Drive-by downloads, cookie theft, credential harvest from browser sessions.
**Mitigation:** Disable browser automation initially (`tools.browser.enabled: false`). Enable only when specific use cases justify it. If enabled, use a dedicated browser profile with no saved credentials.
**Residual risk:** Browser is a powerful primitive. Any enabled browser access is an amplification vector for prompt injection.

### T7. Supply Chain Compromise via npm (MEDIUM)
**Vector:** Malicious package in OpenClaw's npm dependency tree.
**Impact:** Arbitrary code execution during install or runtime.
**Mitigation:** Install from official npm package only (`npm install -g openclaw@latest`). Pin to stable releases. Use `npm audit` after each install/update. Monitor OpenClaw GitHub security advisories (release watch). Record an SBOM snapshot (`npm ls --all > ~/.openclaw/sbom-$(date +%Y%m%d).txt`) after initial install for future comparison. Prefer `npm ci` over `npm install` when a lockfile is available.
**Residual risk:** Standard npm supply chain risk — affects all Node.js software. Mitigations reduce exposure but cannot eliminate the risk of a compromised upstream maintainer.

### T8. Remote Access Misconfiguration (MEDIUM if enabled)
**Vector:** Tailscale Funnel or exposed port allows unauthorized gateway access from outside the network.
**Impact:** Remote prompt injection, gateway takeover.
**Mitigation:** If remote access needed: Tailscale Serve (not Funnel) with identity headers. Never bind to `0.0.0.0`. Require password auth even on Tailscale.
**Residual risk:** Tailscale's security model is strong; residual risk is low if configured correctly.

### T9. Resource Exhaustion / Denial of Service (MEDIUM)
**Vector:** Prompt injection or compromised skill instructs the agent to perform resource-intensive operations (infinite loops, disk-filling writes within workspace, memory-leaking tasks, crypto mining).
**Impact:** Crumb system becomes slow or unusable. Mac Studio becomes unresponsive.
**Mitigation:** Monitor system resources (Activity Monitor, periodic `top` snapshots). Apply resource limits via the `openclaw` user's `launchd` plist (`HardResourceLimits`, `SoftResourceLimits`). Set workspace disk quota if macOS supports it for the dedicated user.
**Residual risk:** Difficult to distinguish legitimate heavy workloads from malicious resource consumption.

### T10. Indirect Data Exfiltration via Logs and Diagnostics (MEDIUM)
**Vector:** Prompt injection instructs OpenClaw to attempt reading a sensitive file. Even if `workspaceOnly` blocks the read, error messages or verbose debug logs may embed file content or path information. Logs are then accessible to other processes or transmitted to diagnostic endpoints.
**Impact:** Credential or sensitive data theft via side channel, bypassing workspace-only restrictions.
**Mitigation:** Configure OpenClaw for minimal logging verbosity. Secure log file permissions (`chmod 600` on `~/.openclaw/logs/`). Periodically purge logs. Disable remote diagnostic/telemetry reporting (no config key exists as of v2026.1.x — track upstream for `telemetry.enabled` or equivalent; mitigated by egress control in Tier 2). Logs are isolated to the `openclaw` user's home directory by the dedicated-user boundary.
**Residual risk:** Log-based side channels are difficult to fully eliminate; the dedicated-user boundary limits who can read them.

### T11. Messaging Account Takeover and Impersonation (MEDIUM / HIGH Phase 2)
**Vector:** SIM swap attack for Signal/WhatsApp registration, session token theft from `~/.openclaw/`, bot token leakage for Telegram/Discord/Slack.
**Impact:** Attacker impersonates the user via messaging platforms, social engineering amplification, reputation damage, access to conversation history.
**Mitigation:** Use burner/dedicated accounts (not personal). Enable 2FA where available. Implement session rotation runbook. Document "kill switch" steps for each connected platform (revoke session, rotate bot token, deregister device). Keep messaging auth tokens in `~/.openclaw/` with `chmod 600`.
**Residual risk:** WhatsApp/Baileys sessions are particularly fragile — Baileys maintains its own session store and re-registration invalidates it, but a stolen session can be used until invalidated.
**Bridge impact:**
- **Phase 1 (manual processing):** Attacker must go through the confirmation echo flow. Their requests are visible in Telegram chat history. The legitimate user sees the activity and can revoke access. Severity remains MEDIUM.
- **Phase 2 (automated file watcher):** Attacker's confirmed requests trigger Crumb sessions without the user watching the chat in real time. The visual inspection backstop is gone — the user discovers the compromise only when reviewing run-logs or receiving Telegram relay messages after the fact. Escalates to HIGH.
- **Rating: MEDIUM (Phase 1) / HIGH (Phase 2 automation active).** Cross-ref: BT1.

### Bridge Integration Threats

The Crumb–Tess bridge (designed in `Projects/crumb-tess-bridge/design/specification.md`) extends the colocation architecture with a Telegram → inbox → Crumb execution path. The following threats are specific to the bridge and supplement T1–T11 above. Residual risk assessment: `Projects/crumb-tess-bridge/progress/ctb-008-residual-risk-assessment.md`.

### BT1. Prompt Injection via Telegram Surviving Confirmation Echo (HIGH)
**Vector:** Attacker compromises the approved Telegram account (SIM swap, session theft) and sends crafted messages, confirming their own requests.
**Impact:** Full governed vault writes via Crumb — can modify specs, create files, alter project state.
**Mitigation:** Confirmation echo catches injection from unapproved senders. Phase 1 scope limited to approvals + status queries. Phase 2 adds rate limiting, operation allowlist, anomaly detection.
**Residual risk:** A compromised approved account has the same bridge capabilities as the user. Fundamental trust assumption. Cross-ref: T1, T11.

### BT2. Confirmation Echo Bypass via Injection (MEDIUM)
**Vector:** Prompt injection crafted to manipulate Tess's echo formatting — appears benign in echo but executes differently when relayed to Crumb.
**Impact:** Tess relays a different action than what the user confirmed.
**Mitigation:** Echo displays exact JSON payload (hard protocol requirement). Hash-bound confirmation code (`payload_sha256[:12]`) ties CONFIRM to specific payload. Crumb recomputes hash and rejects mismatches. ASCII-only values eliminate Unicode homoglyph/zero-width vectors.
**Residual risk:** If Tess's process is fully compromised (BT7), attacker controls both echo and inbox write. Operation allowlist bounds blast radius.

### BT3. Governance Degradation in Automated Sessions (HIGH)
**Vector:** Claude Code's `--print` mode doesn't fully load CLAUDE.md, or loads it but doesn't enforce tool restrictions, risk tiers, or phase gates.
**Impact:** Vault writes without proper governance. Silent bypass — "looks like it's working but isn't governed."
**Mitigation:** Two-tier governance verification: runner-side hash + canary check (non-echoable last 64 bytes of CLAUDE.md), plus in-session self-check. Mandatory for Phase 2 automated invocations.
**Residual risk:** Partial CLAUDE.md loading that skips middle sections. Low probability given current file size.

### BT4. Transcript Injection / Log Poisoning (MEDIUM)
**Vector:** Compromised Tess skill writes fabricated transcripts to `_openclaw/transcripts/`, making it appear Crumb took actions it didn't.
**Impact:** Operator decisions based on fabricated audit trail.
**Mitigation:** Crumb writes its own transcripts directly. Crumb's vault commit history is the authoritative record. Crumb logs to run-log inside the governed vault (outside `_openclaw/`).
**Residual risk:** `_openclaw/transcripts/` is writable by the `openclaw` user. Crumb's run-log (outside `_openclaw/`) is the backstop.

### BT5. Denial of Service via Bridge Flooding (LOW)
**Vector:** Compromised Telegram account sends high-frequency requests, each spawning a Claude Code session.
**Impact:** API cost spike; potential resource exhaustion on Studio.
**Mitigation:** Rate limiting in bridge skill (max N requests per hour). Cooldown after failed confirmation. Per-session cost cap.
**Residual risk:** Low — rate limiting is straightforward and confirmation echo adds natural throttle.

### BT6. NLU Misparse / Ambiguous Intent (HIGH)
**Vector:** Tess's NLU extracts wrong operation, parameters, or scope — due to ambiguous phrasing, LLM errors, or compounded STT transcription errors. User rubber-stamps the misparsed echo without careful review.
**Impact:** User confirms a different action than intended. Vault state changes that don't match actual request.
**Mitigation:** JSON-in-echo is a hard protocol requirement. Hash-bound confirmation code. Strict field validation — ambiguous fields require clarification before echoing. Original message preserved for forensic context.
**Residual risk:** Users may not carefully read JSON payloads on a phone. Hash-bound code adds mechanical check but doesn't prevent uninformed confirmation.

### BT7. Tess Process Compromise (HIGH)
**Vector:** Exploit in OpenClaw, malicious skill, npm supply-chain attack, or privilege escalation gives attacker control of the `openclaw` user's context.
**Impact:** Read access to vault, write access to `_openclaw/inbox/` (inject requests), `_openclaw/outbox/` (forge responses), `_openclaw/transcripts/` (poison audit trail). Phase 2: trigger unlimited Crumb sessions without user confirmation.
**Mitigation:** Operation allowlist bounds blast radius. Crumb validates request schema. Crumb logs to run-log outside `_openclaw/`. Transcript hash enables tamper detection. Phase 2 bridge runner rate limits. Kill-switch file (`~/.crumb/bridge_disabled`).
**Residual risk:** Compromised Tess with sandbox write access can inject schema-valid requests within the allowlist, bypassing confirmation echo. The operation allowlist is the blast-radius bound. Cross-ref: T2, T4, T7.

## Recommendations

### Tier 1: Baseline Hardening (install-time, mandatory)

These are the minimum controls for reasonable safety:

1. **Keep OpenClaw on loopback binding** — do not change the default `127.0.0.1:18789`
2. **Keep DM policy on "pairing" mode** — approve every new sender explicitly
3. **Enable workspace-only restrictions:**
   ```json
   {
     "tools": {
       "fs": { "workspaceOnly": true },
       "exec": { "applyPatch": { "workspaceOnly": true } }
     }
   }
   ```
4. **Set OpenClaw workspace to `~/.openclaw/workspace`** — NOT the vault root. OpenClaw reads the vault through a dedicated vault skill (per spec §9), not through unrestricted file access.
5. **Disable browser automation initially:** `"tools": { "browser": { "enabled": false } }` — **Note (v2026.2.25):** `tools.browser` is not a recognized config key in this version. `openclaw doctor --fix` will remove it. Browser automation may be controlled differently; check `openclaw configure` or docs for the current mechanism. The dedicated-user boundary is the primary control regardless.
6. **Restrict credential file permissions:**
   ```bash
   chmod 700 ~/.config/crumb
   chmod 600 ~/.config/crumb/.env
   chmod 700 ~/.config/meme-creator
   chmod 600 ~/.config/meme-creator/tmdb-api-key
   chmod 700 ~/.openclaw
   chmod 600 ~/.openclaw/openclaw.json ~/.openclaw/device.json
   ```
7. **Separate API key stores** — OpenClaw and Crumb must never share an `.env` file. OpenClaw's keys go in its own config; Crumb's stay in `~/.config/crumb/.env`.
8. **Run `openclaw doctor` after install** — flags misconfigured DM policies and security issues
9. **Run `openclaw security audit --deep`** — baseline audit before connecting messaging platforms
10. **Pin to stable release channel** — no beta/dev builds on the Studio
11. **Verify Tier 1 controls after install:**
    ```bash
    # Confirm loopback-only binding
    lsof -iTCP:18789 -sTCP:LISTEN    # should show 127.0.0.1 only, never 0.0.0.0
    # Confirm workspace-only is set
    grep -A2 '"fs"' ~/.openclaw/openclaw.json  # should show workspaceOnly: true
    # Confirm no ACLs grant broader access to credential files
    ls -le ~/.config/crumb/.env       # should show no ACL entries
    ls -le ~/.openclaw/openclaw.json  # should show no ACL entries
    # Confirm DM policy
    openclaw doctor                    # should report no issues
    ```
12. **Dedicated macOS user for OpenClaw** — create an `openclaw` standard user; run the gateway under that user via launchd. This provides OS-level filesystem isolation: the OpenClaw process physically cannot read `~/.config/crumb/`, `~/.ssh/`, or any of the primary user's files. This is the single most impactful control and the backstop that makes `workspaceOnly` failure non-catastrophic. **This is mandatory, not optional** — without it, a single bypass of the unaudited `workspaceOnly` control leads to full credential compromise.
    - Operational requirements: (a) ensure the `openclaw` user can access Homebrew Node at `/opt/homebrew/bin/node` (≥22.12.0), (b) grant read access to `~/crumb-vault/` via shared group for vault context, (c) grant write access only to `~/crumb-vault/_openclaw/` for the exchange directory.
    - **LaunchDaemon with `UserName` (chosen approach):** Plist at `/Library/LaunchDaemons/ai.openclaw.gateway.plist` (owned by `root:wheel`, mode 644). The plist includes `<key>UserName</key><string>openclaw</string>` so the process runs as the `openclaw` user, not root. This starts reliably at boot without requiring the `openclaw` user to have a GUI session.
      - **Why not LaunchAgent:** LaunchAgent requires the user's GUI domain to be active. Since the `openclaw` user is never interactively logged in, `launchctl bootstrap gui/<uid>` fails at boot — the `gui/<uid>` domain doesn't exist until a GUI login occurs. LaunchDaemon with `UserName` avoids this entirely.
      - **Do not run OpenClaw as root.** The `UserName` key ensures the process runs with the `openclaw` user's least-privilege filesystem access.
      - **Launchctl commands:**
        - Load: `sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist`
        - Unload: `sudo launchctl bootout system/ai.openclaw.gateway`
      - The unloaded LaunchAgent at `/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist` is retained for reference but is not active.
      - **Supervisor migration (U11, 2026-02-26):** Gateway supervisor migrated from LaunchAgent (`gui/502` domain) to LaunchDaemon (`system/` domain) with `UserName: openclaw`, `GroupName: staff`. The `gui/502` domain only exists when the `openclaw` user has an active GUI login session, which never happens for this headless service account. The LaunchDaemon starts at boot via `system/` domain regardless of login state. `ThrottleInterval: 60` included (v2026.2.25 restart hardening). `WorkingDirectory: /Users/openclaw` included (defensive — ensures consistent cwd regardless of launchd context). Health-check script updated to target `system/ai.openclaw.gateway`.
      - **Execution corrections (2026-02-26):** (1) **Node binary path:** `ProgramArguments` must reference `/opt/homebrew/bin/node`, not `/Users/openclaw/.local/bin/node`. The `.local/bin/` directory contains only the `openclaw` CLI symlink; `node` is installed via Homebrew. The incorrect path causes launchd to report `EX_CONFIG (exit code 78)` with zero log output — the process never launches, making the failure opaque. (2) **`com.apple.provenance` xattr lifecycle:** On macOS 15+, every file modification (`sudo tee`, `PlistBuddy -c`, `cp`) re-attaches this xattr. The strip must be the **last** operation before `launchctl bootstrap`. Stripping earlier in the sequence is ineffective if subsequent edits re-attach it.
    - The `openclaw` user should never be granted Accessibility, Screen Recording, Full Disk Access, or Files & Folders permissions beyond its own home and the explicitly allowed vault directories.

**v2026.2.17 → v2026.2.25 Tier 1 evolution notes:**

> **Application-level hardening (U1):** Security significantly strengthened across eight releases — heredoc substitution bypass blocked (v2026.2.21), shell env injection blocked (v2026.2.21), exec tool pinned to resolved absolute paths (v2026.2.22), safe-bin directories restricted to system paths (v2026.2.24), dangerous env keys stripped from non-sandboxed exec (v2026.2.24), workspace FS hardlink rejection added to `workspaceOnly` and `applyPatch` guards (v2026.2.25) — prevents out-of-workspace read/write via in-workspace hardlink aliases. SSRF protections expanded with IPv6 transition address blocking (v2026.2.19) and pinned DNS ordering (v2026.2.24).
>
> **`/opt/homebrew/bin` trust rationale:** Homebrew is the standard macOS package manager path. Agents require `git`, `node`, `python` — all installed via Homebrew. Symlinking individual binaries to `/usr/local/bin` would obscure binary provenance, add maintenance burden for each upgrade, and provide no additional security over trusting the directory. The operator controls the Homebrew supply chain on a single-user Studio machine.
>
> **Gateway auth migration (U3):** v2026.2.19 migrated the auth key from `gateway.token` to `gateway.auth.token`. Default auth mode for new installs is token-based with auto-generated secret. Password mode (our config) unaffected but key path changed.
>
> **Subagent spawn depth (U4):** v2026.2.21 config: `agents.defaults.maxSpawnDepth: 1` — pinned to prevent default increase to 2. Each subagent inherits workspace/exec permissions; spawning multiplies T1 (prompt injection) attack surface.
>
> **Heartbeat configuration (U5):** v2026.2.24 blocked DM delivery; v2026.2.25 restored it via `agents.defaults.heartbeat.directPolicy` (`allow` by default, `block` to suppress). Our config explicitly sets `directPolicy: "allow"` for resilience against future default changes. Per-agent override available via `agents.list[].heartbeat.directPolicy`.
>
> **v2026.2.25 security & branding (U7):** WebSocket auth origin checks hardened, workspace FS hardlink rejection added, exec approval binding tightened. Branding cleanup: all remaining `bot.molt` labels replaced with `ai.openclaw` across docs and CLI. Telegram webhook pre-init and callback-mode JSON handling added (polling mode unaffected).
>
> **Daemon restart hardening (U10):** v2026.2.25 upstream restart sequence hardened: `print → bootout → wait old pid exit → bootstrap → kickstart` with stale PID cleanup and supervisor marker detection. LaunchAgent plists now include `ThrottleInterval: 60` to bound launchd retry storms. Sentinel text (`NO_REPLY`, `HEARTBEAT_...`) no longer leaks into streaming output. Telegram `sendChatAction` 401 failures now use bounded exponential backoff.

### Tier 2: Operational Hardening (post-install, recommended)

13. **No ClawHub skills without manual review** — treat every skill as untrusted code. Review source before install. Prefer skills with published source over compiled/obfuscated ones.
14. **Gitignore `_openclaw/` initially** — until the bidirectional exchange protocol (spec §9 Phase 2) is built and tested, keep OpenClaw's sandbox out of git to avoid index contention.
15. **Use burner accounts for messaging platforms** — create dedicated bot accounts for Telegram, Discord, etc. Don't connect personal WhatsApp to OpenClaw until trust is established.
16. **Remote access disabled until Phase 2.** Do not enable Tailscale Serve/Funnel or any remote gateway access during initial setup. When enabled later, use Serve mode (not Funnel), with identity headers + password auth:
    ```json
    {
      "gateway": {
        "tailscale": { "mode": "serve" },
        "auth": { "mode": "password" }
      }
    }
    ```
    Verify after enabling: no Funnel active, no public exposure (`tailscale status`, `lsof -iTCP:18789`).
17. **Monitor disk usage** — OpenClaw media pipeline, browser profiles, and messaging attachments can accumulate. Set up a periodic check or cron alert.
18. **Update cadence** — check for OpenClaw security patches twice weekly for the first 60 days, then weekly. Set up a GitHub release watch (`gh api repos/openclaw/openclaw/releases/latest`) or RSS alert. After each update: verify hardening config is unchanged in `openclaw.json`.
19. **Egress control** — install Little Snitch or LuLu and configure rules for the `openclaw` user/process. Restrict outbound connections to only the required endpoints:
    | Service | Domains |
    |---------|---------|
    | WhatsApp | `*.whatsapp.net`, `*.whatsapp.com` |
    | Telegram | `api.telegram.org` |
    | Signal | `*.signal.org` |
    | Discord | `discord.com`, `gateway.discord.gg` |
    | Slack | `*.slack.com` |
    | LLM APIs | `api.openai.com`, `generativelanguage.googleapis.com`, `api.anthropic.com` |
    Block all other outbound from the OpenClaw process. This enforces P1's "no non-whitelisted network calls" at the OS level rather than relying solely on code review.

### Tier 3: Advanced Isolation (optional, for maximum hardening)

20. **Docker containerization** — run OpenClaw in Docker with `--read-only --cap-drop=ALL`, mounting only the `_openclaw/` directory. Strongest isolation but adds Docker as a dependency and complicates messaging platform auth.
21. **macOS PF firewall rules** — use `pf` packet filter rules to restrict the `openclaw` user's outbound connections at the kernel level. Provides stronger enforcement than application-layer egress control (Tier 2) but requires `pf.conf` maintenance.

## Vault Integration Architecture (from spec §9, updated)

The spec §9 phased integration remains valid with these adjustments:

**v2026.2.25 integration updates (U8):**

> **Pairing:** Operator device-identity sessions authenticated with shared token auth must now be paired; unpaired devices cannot self-assign operator scopes. The colocation design treats pairing as a primary guardrail, not an optional UX feature. "Shared token is sufficient" → "shared token + pairing, scoped to loopback."
>
> **Security audit:** `openclaw security audit` is now a first-class maintenance primitive. Run after every OpenClaw upgrade and any material configuration change. `--fix` is gated behind medium/high-risk approval semantics.
>
> **Provider roster:** OpenClaw 2026.2.25 adds first-class Kilo Gateway / `kilocode` provider support (default model: `kilocode/anthropic/claude-opus-4.6`). Not enabled in this colocation deployment. Crumb's model routing remains controlled in CLAUDE.md.

### Vault Access Model

OpenClaw does NOT get unrestricted filesystem access to the vault. The access model is:

- **OpenClaw's workspace** is `~/.openclaw/workspace/` — completely outside the vault
- **Vault read access** is OS-level: the dedicated `openclaw` user gets read permission to `~/crumb-vault/` via shared group membership (`crumbvault`). This means any process running as `openclaw` — including compromised skills — can read vault content. The "dedicated vault skill" that curates what context the agent sees is a **curation layer, not a security boundary**. It controls what the LLM is prompted with, but does not prevent underlying Node.js code from reading files directly. Accept this trade-off: vault content (notes, specs, docs) is readable; credentials are not.
- **Vault write access** is restricted to one directory: `~/crumb-vault/_openclaw/`. The dedicated user gets write permission only to this directory. All other vault directories are read-only at the OS level.
- **Sensitive paths** (`~/.config/crumb/`, `~/.ssh/`, `~/.zshrc`) are inaccessible: owned by the primary user, no group or world read permission.
- **Vault read permissions must be set recursively:** `chgrp -R crumbvault ~/crumb-vault && chmod -R g+rX,g-w ~/crumb-vault` (group read + traverse on directories, no group write). Then override for `_openclaw/`: `chmod -R g+rwX ~/crumb-vault/_openclaw`.
- **Group inheritance via setgid:** New files created by the primary user inherit that user's default group, not `crumbvault`. Without mitigation, the `openclaw` user loses read access to every new vault file until the next `chgrp -R`. Fix: set the setgid bit on vault directories so new files inherit the `crumbvault` group: `find ~/crumb-vault -type d -exec chmod g+s {} +`. Verify with `ls -ld ~/crumb-vault` — the group permission should show `s` (e.g., `drwxr-s---`). APFS honors setgid (standard POSIX behavior). The actual risk is tools that explicitly set the group on new files after creation (e.g., via `chown`/`chgrp`), which would override setgid inheritance. Verify during OC-011 that Claude Code's file creation (Write, Edit tools) respects setgid — if it does, no fallback is needed. If any tool overrides the group, add a periodic `chgrp -R crumbvault ~/crumb-vault` to compensate.

This model means: even if `workspaceOnly` is bypassed, the OS-level permissions on the dedicated user prevent writes outside `_openclaw/` and prevent any access to credential files. Vault content (notes, docs) is readable by OpenClaw — this is by design for context access.

### Vault Skill Contract

The dedicated OpenClaw vault skill (Phase 1) curates what vault content the LLM sees. While not a security boundary, it should enforce data minimization:

- **Allowlisted paths:** `_system/docs/`, `Domains/*/` summaries, `Projects/*/specification-summary.md`, `CLAUDE.md`
- **Denylisted paths:** `.env`, `*.key`, `~/.config/`, `~/.ssh/`, `_system/reviews/raw/`, any file matching secret patterns
- **Size limits:** Max 50KB per read, max 5 files per request
- **Redaction:** Before returning content to the model, strip any strings matching API key patterns (`sk-`, `ghp_`, `xoxb-`, etc.)
- **Audit:** Log which vault files are accessed per session for review

**Phase 1: Shared filesystem + mediated vault access + cron sync**
- OpenClaw reads vault files through its own skill (not raw filesystem access)
- OpenClaw writes only to `~/crumb-vault/_openclaw/inbox/` and `~/crumb-vault/_openclaw/outbox/`
- `_openclaw/` is gitignored until Phase 2
- Cron job (or OpenClaw's built-in scheduler) syncs captures for Crumb to process during interactive sessions

**Phase 2: Bidirectional exchange + research delegation**
- `_openclaw/` added to git tracking
- Crumb's inbox-processor skill gains a path for `_openclaw/outbox/` items
- Request/response file protocol for research delegation
- Git write coordination via atomic rename:
  1. OpenClaw writes to a temporary file in `_openclaw/outbox/` (e.g., `.msg-001.json.tmp`)
  2. After write completes, atomically rename to final location (e.g., `_openclaw/outbox/msg-001.json`)
  3. This prevents partial-write corruption — git never sees a half-written file
  - T5 (git index corruption) is rated LOW. Git is resilient to concurrent file writes outside the index, and `_openclaw/` is gitignored during Phase 1. The atomic-rename pattern is sufficient; no lock file, polling, or pre-commit coordination needed.

**Phase 3: CLI escalation + browser validation**
- OpenClaw can invoke `claude` CLI for governed operations (requires careful scoping)
- Browser automation enabled only after completing the **browser enablement checklist:**
  - Dedicated Chromium profile with no saved passwords or autofill data
  - Download directory restricted to workspace (`~/.openclaw/workspace/downloads/`)
  - Domain allowlist configured in `openclaw.json`:
    ```json
    { "tools": { "browser": { "enabled": true, "allowlist": ["anthropic.com", "github.com", "arxiv.org"] } } }
    ```
    Format: array of FQDNs (no wildcards — each domain is matched with subdomains). Navigation outside the allowlist triggers a confirmation prompt to the operator via the controlling messaging platform ("Navigate to [domain]? Reply YES or NO"). If confirmed, the domain is added to the allowlist persistently. Allowlist reviewed monthly during credential rotation.
  - Human-confirm gate for navigation to domains not on the allowlist
  - No stored cookies or sessions from personal browsing
  - Monitoring for unexpected outbound connections from the browser process

## Migration Runbook Impact

The Studio migration runbook (`~/downloads/crumb-studio-migration.md`) needs these additions:

### Installation Path Decision

Choose one:

**Option A: Day 1 (install both during Studio setup)**
Best if you want OpenClaw available immediately. Follow the full runbook, then append the OpenClaw phase. Higher initial complexity but avoids a second setup session.

**Option B: Phased (Crumb first, OpenClaw later)**
Best if you want to validate the Crumb migration before adding complexity. Complete the full Crumb runbook, run at least one successful Crumb session, then return and add OpenClaw. Lower risk, allows incremental validation.

Either option uses the same OpenClaw installation phase below. The difference is timing.

### New Phase: OpenClaw Installation

```
Phase N: OpenClaw

  Prerequisites:
  - Crumb is installed and validated (setup-crumb.sh passes)

  Setup:
  1. Create dedicated macOS user:
     sudo sysadminctl -addUser openclaw -password - -home /Users/openclaw
     # Set a strong password; you'll rarely use it directly
  2. Verify Homebrew Node is accessible and install OpenClaw:
     # Confirm Homebrew Node is ≥22.12.0
     sudo -u openclaw bash -c 'export PATH="/opt/homebrew/bin:$PATH" && node --version'
     # Expected output: v22.x.x or higher. If the openclaw user can't access /opt/homebrew/bin/node,
     # check directory permissions: ls -la /opt/homebrew/bin/node
     # Install OpenClaw globally
     sudo -u openclaw bash -c 'export PATH="/opt/homebrew/bin:$PATH" && npm install -g openclaw@latest'
  3. Create wrapper script and run onboard:
     # Create launch script (adds Homebrew to PATH for launchd)
     sudo -u openclaw tee /Users/openclaw/launch-openclaw.sh > /dev/null << 'SCRIPT'
     #!/bin/bash
     export PATH="/opt/homebrew/bin:$PATH"
     exec openclaw daemon
     SCRIPT
     sudo chmod 700 /Users/openclaw/launch-openclaw.sh
     sudo chown openclaw /Users/openclaw/launch-openclaw.sh
     # Run onboard
     sudo -u openclaw openclaw onboard
     - Configure workspace: /Users/openclaw/.openclaw/workspace
  4b. Create LaunchDaemon from onboard's LaunchAgent:
     # Onboard generates a LaunchAgent; copy to LaunchDaemons and add UserName
     sudo cp /Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist \
       /Library/LaunchDaemons/ai.openclaw.gateway.plist
     PLIST="/Library/LaunchDaemons/ai.openclaw.gateway.plist"
     sudo chown root:wheel "$PLIST" && sudo chmod 644 "$PLIST"
     sudo /usr/libexec/PlistBuddy -c "Add :UserName string openclaw" "$PLIST"
     sudo /usr/libexec/PlistBuddy -c "Add :GroupName string openclaw" "$PLIST"
     # Update ProgramArguments to call the wrapper script
     sudo /usr/libexec/PlistBuddy -c "Delete :ProgramArguments" "$PLIST"
     sudo /usr/libexec/PlistBuddy -c "Add :ProgramArguments array" "$PLIST"
     sudo /usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string /Users/openclaw/launch-openclaw.sh" "$PLIST"
     # Plist label: ai.openclaw.gateway
     # Load: sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
     # Unload: sudo launchctl bootout system/ai.openclaw.gateway
  4c. Test the wrapper script before loading the plist:
     # Dry-run: verify the script launches the daemon successfully
     sudo -u openclaw timeout 5 /Users/openclaw/launch-openclaw.sh &
     WRAPPER_PID=$!
     sleep 3
     if kill -0 $WRAPPER_PID 2>/dev/null; then
       echo "✓ Wrapper script launched successfully"
       kill $WRAPPER_PID 2>/dev/null
     else
       echo "✗ Wrapper script exited prematurely. Debug:"
       echo "  1. Verify Homebrew Node is accessible: sudo -u openclaw /opt/homebrew/bin/node --version"
       echo "  2. Verify PATH in wrapper: sudo -u openclaw bash -c 'export PATH=/opt/homebrew/bin:\$PATH && which openclaw'"
       echo "  3. Check openclaw user can execute: sudo -u openclaw bash -c 'export PATH=/opt/homebrew/bin:\$PATH && openclaw --version'"
       exit 1
     fi
  5. Apply Tier 1 hardening to /Users/openclaw/.openclaw/openclaw.json
  6. Set up vault access permissions:
     # Create shared group for vault read access
     sudo dseditgroup -o create -r "Crumb Vault Readers" crumbvault
     sudo dseditgroup -o edit -a openclaw -t user crumbvault
     sudo dseditgroup -o edit -a $(logname) -t user crumbvault
     # Grant recursive group read to vault, write only to _openclaw/
     chgrp -R crumbvault ~/crumb-vault
     chmod -R g+rX,g-w ~/crumb-vault          # group read + traverse, no group write
     mkdir -p ~/crumb-vault/_openclaw/{inbox,outbox,outbox/.pending}
     chown -R openclaw:crumbvault ~/crumb-vault/_openclaw
     chmod -R g+rwX ~/crumb-vault/_openclaw    # group read+write on sandbox
  7. MANDATORY: Run permission isolation test suite (GO/NO-GO gate).
      Do NOT proceed to messaging platform setup until ALL tests pass.
      Use absolute paths — ~ expansion is unreliable with sudo -u.
      PRIMARY_USER=$(logname)
      PASS=0; FAIL=0
      # --- Tests that MUST fail (isolation boundary) ---
      if sudo -u openclaw cat /Users/$PRIMARY_USER/.config/crumb/.env 2>&1 | grep -q "Permission denied"; then
        echo "✓ PASS: openclaw blocked from ~/.config/crumb/.env"; ((PASS++))
      else
        echo "✗ FAIL: openclaw CAN READ ~/.config/crumb/.env — ISOLATION BROKEN"; ((FAIL++))
      fi
      if sudo -u openclaw ls /Users/$PRIMARY_USER/.ssh/ 2>&1 | grep -q "Permission denied"; then
        echo "✓ PASS: openclaw blocked from ~/.ssh/"; ((PASS++))
      else
        echo "✗ FAIL: openclaw CAN READ ~/.ssh/ — ISOLATION BROKEN"; ((FAIL++))
      fi
      if sudo -u openclaw cat /Users/$PRIMARY_USER/.zshrc 2>&1 | grep -q "Permission denied"; then
        echo "✓ PASS: openclaw blocked from ~/.zshrc"; ((PASS++))
      else
        echo "✗ FAIL: openclaw CAN READ ~/.zshrc — ISOLATION BROKEN"; ((FAIL++))
      fi
      if sudo -u openclaw ls /Users/$PRIMARY_USER/Library/Keychains/ 2>&1 | grep -qE "Permission denied|Operation not permitted"; then
        echo "✓ PASS: openclaw blocked from ~/Library/Keychains/"; ((PASS++))
      else
        echo "✗ FAIL: openclaw CAN READ ~/Library/Keychains/"; ((FAIL++))
      fi
      # --- Tests that MUST succeed (vault access) ---
      if sudo -u openclaw ls /Users/$PRIMARY_USER/crumb-vault/_system/docs/ >/dev/null 2>&1; then
        echo "✓ PASS: openclaw can read vault _system/docs/"; ((PASS++))
      else
        echo "✗ FAIL: openclaw cannot read vault (group permissions misconfigured)"; ((FAIL++))
      fi
      if sudo -u openclaw cat /Users/$PRIMARY_USER/crumb-vault/CLAUDE.md >/dev/null 2>&1; then
        echo "✓ PASS: openclaw can read CLAUDE.md"; ((PASS++))
      else
        echo "✗ FAIL: openclaw cannot read CLAUDE.md"; ((FAIL++))
      fi
      # --- Tests that MUST fail (vault write boundary) ---
      if sudo -u openclaw touch /Users/$PRIMARY_USER/crumb-vault/test-isolation.txt 2>&1 | grep -q "Permission denied"; then
        echo "✓ PASS: openclaw blocked from vault write"; ((PASS++))
      else
        echo "✗ FAIL: openclaw CAN WRITE to vault root — WRITE BOUNDARY BROKEN"; ((FAIL++))
        rm -f /Users/$PRIMARY_USER/crumb-vault/test-isolation.txt
      fi
      # --- Tests that MUST succeed (sandbox write) ---
      if sudo -u openclaw touch /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation.txt 2>/dev/null; then
        echo "✓ PASS: openclaw can write to _openclaw/ sandbox"; ((PASS++))
        rm -f /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation.txt
      else
        echo "✗ FAIL: openclaw cannot write to _openclaw/ sandbox"; ((FAIL++))
      fi
      if sudo -u openclaw mkdir /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation-dir 2>/dev/null; then
        echo "✓ PASS: openclaw can mkdir in _openclaw/ sandbox"; ((PASS++))
        rmdir /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation-dir
      else
        echo "✗ FAIL: openclaw cannot mkdir in _openclaw/ sandbox"; ((FAIL++))
      fi
      # --- Gate ---
      echo ""
      echo "=== ISOLATION TEST RESULTS: $PASS passed, $FAIL failed ==="
      if [ $FAIL -gt 0 ]; then
        echo "*** STOP: $FAIL test(s) failed. Fix permissions before proceeding. ***"
        echo "*** Do NOT connect messaging platforms until all tests pass.      ***"
        exit 1
      else
        echo "All isolation tests passed. Safe to proceed."
      fi
  8. Run diagnostics:
     sudo -u openclaw openclaw doctor
     sudo -u openclaw openclaw security audit --deep
  9. Lock down credential files:
     sudo chmod 700 /Users/openclaw/.openclaw
     sudo chmod 600 /Users/openclaw/.openclaw/openclaw.json
     sudo chmod 600 /Users/openclaw/.openclaw/device.json
  10. Verify: sudo -u openclaw openclaw status
  11. Run Tier 1 verification checks (see Recommendations section)
  12. Set up messaging platform connections (use burner accounts)
```

### Updates to Existing Phases

- **Phase 2 (Brew packages):** Homebrew Node is shared between both users. The `openclaw` user accesses it at `/opt/homebrew/bin/node` via PATH in its wrapper script. No separate Node install needed.
- **Phase 5 (Shell config):** Do NOT add OpenClaw API keys to `~/.zshrc`. Keep them in OpenClaw's own config.
- **Phase 8 (Config files):** Add OpenClaw config to the list of non-git files to save/restore.
- **Phase 12 (Backup):** Verify `vault-backup.sh` captures `_openclaw/` directory (it will — it tars the entire `~/crumb-vault/`).
- **`setup-crumb.sh`:** Add an optional OpenClaw health check phase (check `openclaw status`, verify hardening config).

### New Section: "Before You Start" Additions

Save from the work machine (if OpenClaw is already running there):
- `~/.openclaw/openclaw.json` (redact gateway token; recreate on new machine)
- Messaging platform re-authentication will be required on the new machine regardless

## Messaging Platform Kill-Switch Runbook

**Go-live prerequisite:** This runbook must be reviewed and tested (dry-run) before connecting any messaging platform to OpenClaw.

Per-platform emergency disconnect and credential rotation procedures. Use when a prompt injection is suspected, account compromise is detected, or during scheduled credential rotation.

**Rotation schedule:** Monthly for all platforms during the first 60 days, then quarterly. Rotate off-hours to minimize disruption.

### Global Emergency Stop (All Platforms)

When an active compromise is suspected, execute this sequence first:

1. **Stop OpenClaw immediately:**
   ```bash
   # Stop via launchctl
   sudo launchctl bootout system/ai.openclaw.gateway
   # IMPORTANT: `openclaw daemon stop` and `launchctl bootout` may not fully kill the
   # node process. Always verify and follow up with pkill if needed:
   sleep 2
   if pgrep -f "openclaw/dist/index.js" >/dev/null; then
     sudo -u openclaw pkill -f "openclaw/dist/index.js"
   fi
   # Verify port is clear:
   lsof -iTCP:18789 -sTCP:LISTEN  # should return nothing
   ```
2. **Network containment (if severity warrants):** Disable Wi-Fi or pull Ethernet to prevent ongoing exfiltration.
3. **Collect forensic artifacts before rotating credentials:**
   ```bash
   sudo cp -r /Users/openclaw/.openclaw/logs/ /tmp/openclaw-incident-$(date +%Y%m%d)/
   sudo cp /Users/openclaw/.openclaw/openclaw.json /tmp/openclaw-incident-$(date +%Y%m%d)/
   cp -r ~/crumb-vault/_openclaw/ /tmp/openclaw-incident-$(date +%Y%m%d)/sandbox/
   ```
4. **Rotate all credentials:** OpenClaw gateway token, all messaging platform tokens (per-platform steps below), any LLM API keys stored in `/Users/openclaw/.openclaw/`.
5. **Review `_openclaw/` for unauthorized writes** — check for unexpected files, especially in `outbox/`.
6. **Re-enable** only after root cause is identified and remediated.

Then proceed with per-platform steps as needed. Use the standard restart sequence after credential changes:
```bash
# Standard daemon restart (use after any credential rotation)
sudo launchctl bootout system/ai.openclaw.gateway
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
```

### WhatsApp (Baileys)
1. Disconnect: `openclaw pairing disconnect whatsapp` (or stop the daemon via `bootout` above)
2. Revoke session: On the phone linked to the burner number, go to Settings → Linked Devices → remove the OpenClaw session
3. Baileys session store at `~/.openclaw/` is automatically invalidated when the device is unlinked
4. Restart daemon (standard restart sequence above)
5. Re-pair: `openclaw pairing restart whatsapp` → scan new QR code with the burner phone
6. Verify: send a test message to confirm new session works

### Telegram (grammY)
1. Revoke bot token: visit [@BotFather](https://t.me/BotFather) → select bot → `/revoke`
2. Generate new token: `/newtoken` → copy the token
3. Update `openclaw.json`: set `telegram.botToken` to the new token
4. Restart daemon (standard restart sequence above)
5. Verify: send test message via Telegram to confirm bot responds

### Signal (signal-cli)
1. Stop daemon (`bootout` from standard restart sequence above)
2. Unregister: `signal-cli -u +1XXXXXXXXXX unregister` (burner number)
3. Re-register with the same or new burner number: `signal-cli -u +1XXXXXXXXXX register`
4. Verify code, restart daemon (`bootstrap` from standard restart sequence above), test

### Discord (discord.js)
1. Revoke bot token: Discord Developer Portal → Bot → Reset Token
2. Copy new token, update `openclaw.json`: `discord.botToken`
3. Restart daemon (standard restart sequence above)
4. Verify: bot comes online in the configured server

### Slack (Bolt)
1. Revoke tokens: Slack API dashboard → Your Apps → select app → OAuth & Permissions → Revoke All Tokens
2. Reinstall app to workspace, copy new Bot User OAuth Token
3. Update `openclaw.json`: `slack.botToken`
4. Restart daemon (standard restart sequence above), verify in Slack

## Secrets Management

Current baseline: `chmod 600` on credential files prevents cross-user access. This is sufficient when combined with the dedicated-user model — the `openclaw` user physically cannot read the primary user's credential files.

**Future enhancement (Phase 2+):** For defense against compromise of the `openclaw` user itself, consider loading OpenClaw secrets from macOS Keychain or 1Password CLI at runtime rather than storing them in plaintext `openclaw.json`. The wrapper script (`launch-openclaw.sh`) can pull secrets into environment variables before `exec openclaw daemon`:
```bash
# Example with 1Password CLI (if adopted)
export TELEGRAM_BOT_TOKEN=$(op read op://openclaw-secrets/telegram/bot-token)
export OPENAI_API_KEY=$(op read op://openclaw-secrets/openai/api-key)
exec openclaw daemon
```
This prevents secrets from being stored in plaintext on disk and from appearing in backups. Evaluate after Phase 1 stability is confirmed.

## Backup Implications

- `vault-backup.sh` already tars the entire `~/crumb-vault/` — `_openclaw/` will be included automatically
- **`/Users/openclaw/.openclaw/` must be included in a system-level backup** (Time Machine or equivalent). This directory contains configuration, workspace data, and messaging session state that represents significant setup effort. Add `/Users/openclaw` to the Time Machine backup scope during initial setup.
- Messaging media (images, voice notes) cached by OpenClaw should have a retention policy to avoid disk bloat.

## Domain Classification and Workflow

- **Domain:** software
- **Workflow:** SPECIFY → PLAN → IMPLEMENT (three-phase — no formal TASK decomposition needed yet; this is infrastructure work, not a code project)
- **Rationale:** This is an infrastructure and security architecture analysis. The output is a hardening checklist and runbook update, not a multi-milestone software build.

## Task Decomposition

| ID | Task | Type | Risk | Dependencies | Acceptance Criteria |
|----|------|------|------|--------------|---------------------|
| OC-001 | Update migration runbook with OpenClaw installation phase | `#writing` | Low | This spec approved | Runbook includes OpenClaw install, dedicated user setup, hardening, and verification steps |
| OC-002 | Update `setup-crumb.sh` with optional OpenClaw health check | `#code` | Low | OC-001 | Script detects OpenClaw presence and validates hardening config (loopback binding, workspaceOnly, dedicated user) |
| OC-003 | Create `_openclaw/` directory scaffold with `.gitignore` | `#code` | Low | This spec approved | Directory exists; gitignored; README explains purpose and access model |
| OC-004 | Update Crumb spec §9 with hardening requirements and current CVE context | `#writing` | Medium | This spec peer-reviewed | Spec §9 reflects current threat landscape, dedicated user model, and vault access architecture |
| OC-005 | Test Node.js version compatibility (Claude Code vs OpenClaw) | `#research` | Medium | Studio available | Both tools work with Homebrew Node (≥22.12.0); wrapper script adds `/opt/homebrew/bin` to PATH for launchd |
| OC-006 | Create `_system/docs/openclaw-crumb-reference.md` (referenced in spec but never created) | `#writing` | Medium | This spec + OC-004 | Reference doc covers integration architecture, exchange formats, use case allocation, vault access model |
| OC-007 | ~~Document messaging platform kill-switch procedures~~ **DONE** — written inline in §Messaging Platform Kill-Switch Runbook | `#writing` | Low | OC-001 | Per-platform steps: revoke session, rotate bot token, deregister device for each connected platform |
