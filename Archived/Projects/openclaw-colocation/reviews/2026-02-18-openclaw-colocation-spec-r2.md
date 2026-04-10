---
type: review
review_mode: full
review_round: 2
prior_review: Projects/openclaw-colocation/reviews/2026-02-18-openclaw-colocation-spec.md
artifact: docs/openclaw-colocation-spec.md
artifact_type: spec
artifact_hash: dab496e0
prompt_hash: 9f82e0e3
base_ref: null
project: openclaw-colocation
domain: software
skill_origin: peer-review
created: 2026-02-18
updated: 2026-02-18
reviewers:
  - openai/gpt-5.2
  - google/gemini-2.5-pro
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: 4096
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  note: "Generic secrets pattern matched '/newtoken' (Telegram BotFather command) — false positive, downgraded."
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 56931
    attempts: 1
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-openai-r2.json
  google:
    http_status: 200
    latency_ms: 46441
    attempts: 1
    note: "Re-sent with max_tokens 8192 — complete response (STOP). Replaces truncated initial attempt."
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-google-r2b.json
  perplexity:
    http_status: 200
    latency_ms: 46167
    attempts: 1
    note: "Truncated at MAX_TOKENS — 6 findings (3 CRITICAL, 3 SIGNIFICANT). Soft injection wrapper used."
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-perplexity-r2b.json
tags:
  - review
  - peer-review
  - security
  - openclaw
---

# Peer Review Round 2: OpenClaw + Crumb Colocation Specification

**Artifact:** `docs/openclaw-colocation-spec.md`
**Mode:** full
**Round:** 2 (prior: `_system/reviews/2026-02-18-openclaw-colocation-spec.md`)
**Reviewed:** 2026-02-18
**Reviewers:** OpenAI GPT-5.2, Google Gemini 2.5 Pro, Perplexity Sonar Reasoning Pro
**Review prompt:** Round 2 full review of updated spec. Asked reviewers to evaluate (1) whether round 1 findings were addressed, (2) new issues from revisions, (3) remaining gaps, (4) implementation readiness.

---

## OpenAI GPT-5.2

(16 findings — 2 CRITICAL, 6 SIGNIFICANT, 3 MINOR, 3 STRENGTH, 1 overall readiness assessment. Complete response.)

- [OAI-F1] **STRENGTH**: Round 1 "isolation over hardening" is now the backbone. Dedicated macOS user, permission test suite, and explicit defense-in-depth framing are well-integrated.

- [OAI-F2] **STRENGTH**: Operational readiness materially improved — Tier 1 verification, update cadence, SBOM snapshot, kill-switch runbook prevent "paper hardening."

- [OAI-F3] **CRITICAL**: Vault permission model is internally inconsistent. Step 6 sets `chmod 750` on vault root but doesn't ensure read+traverse on all subdirectories. Missing explicit enforcement of "read-only everywhere except `_openclaw/`." Risk: either OpenClaw can't read vault (breaking design) or permissions are loosened too broadly.

- [OAI-F4] **CRITICAL**: Spec says vault reads happen through a "dedicated OpenClaw skill" (mediated), but grants OS-level read access to the entire vault. A malicious skill can still read vault via Node APIs regardless of `workspaceOnly`. Recommends either: (a) strict model — curated "context mirror" directory with no direct vault access, or (b) relaxed model — acknowledge mediated skill is not a security control and tighten P1 accordingly.

- [OAI-F5] **SIGNIFICANT**: Dedicated user approach doesn't address Keychain/TCC/privacy entitlements. LaunchAgents accumulate permissions over time. Compromised OpenClaw could social-engineer TCC grants (Screen Recording, Accessibility).

- [OAI-F6] **SIGNIFICANT**: launchd + nvm guidance is brittle — hardcoded versioned path breaks on every Node update. npm global bin path may not be where the spec assumes. Recommends fixed symlink or Homebrew Node for daemon user.

- [OAI-F7] **SIGNIFICANT**: Tier numbering duplicated (Tier 1 and Tier 2 both have item "11."). "LaunchDaemon" vs "LaunchAgent" terminology confused — could accidentally increase privileges.

- [OAI-F8] **SIGNIFICANT**: Kill-switch runbook lacks a global emergency stop and post-incident containment checklist. `launchctl restart` may not work as written — should use `bootout`/`bootstrap`/`kickstart`.

- [OAI-F9] **MINOR**: Some mitigations are aspirational without mapping to actual config keys ("disable remote diagnostic/telemetry reporting," "encrypted credential storage").

- [OAI-F10] **SIGNIFICANT**: P1 says "no network calls to non-whitelisted domains" but no mechanism enforces this at Tier 1 or 2. Recommends promoting minimal egress control (Little Snitch/LuLu) to Tier 2.

- [OAI-F11] **MINOR**: Atomic rename + pre-commit check doesn't address Obsidian indexing reacting to `.tmp-*` files. Recommends hidden subdir for temps.

- [OAI-F12] **SIGNIFICANT**: Permission test suite uses `~` expansion which may not work correctly with `sudo -u`. Should use absolute paths. Missing tests for Keychain access.

- [OAI-F13] **STRENGTH**: Browser automation gated by default with concrete enablement checklist — prudent.

- [OAI-F14] **SIGNIFICANT**: "Dedicated vault skill" is underspecified — no allowlist, no redaction rules, no max bytes. Will drift to "read anything helpful."

- [OAI-F15] **MINOR**: A5 tension between "shared vault" and strict security posture. Should be updated to reflect chosen model.

- [OAI-F16] **OVERALL**: Spec is close to implementable for Tier 1 + Tier 2, but needs: (a) vault-read model made consistent and enforceable (F3/F4), (b) launchd + Node strategy made robust (F6/F7), (c) minimal egress control plan (F10).

---

## Google Gemini 2.5 Pro

(10 findings — 1 CRITICAL, 3 SIGNIFICANT, 4 MINOR, 3 STRENGTH. Complete response after re-send with 8192 max_tokens.)

Overall assessment: Very close to implementation readiness. Primary new issue is operational complexity for a solo operator. Main remaining gaps: secrets management beyond `chmod`, brittle nvm path, and potential vetting fatigue. Sound architecture with actionable migration plan.

- [GEM-F1] **CRITICAL**: Dedicated macOS user (Recommendation #11) is classified as Tier 2 "recommended" but the spec itself calls it the "single most impactful control" and the backstop that makes `workspaceOnly` failure non-catastrophic. Should be Tier 1 mandatory. Without it, T4 mitigation relies entirely on the unaudited `workspaceOnly`.

- [GEM-F2] **SIGNIFICANT**: Hardcoded nvm Node path in launchd plist is brittle — breaks on every Node update. Solo operator must remember to unload service, edit plist, reload. Recommends wrapper script (`launch-openclaw.sh`) that sources nvm and runs `exec openclaw daemon`, with plist pointing to the script.

- [GEM-F3] **SIGNIFICANT**: Secrets management relies on `chmod 600` (plaintext on disk). If `openclaw` user is compromised, all configured secrets are trivially readable. Also captured in plaintext backups. Recommends macOS Keychain integration or 1Password CLI to load secrets as env vars at runtime via the wrapper script.

- [GEM-F4] **MINOR**: Runbook step 6 hardcodes primary username `dturner`. Not portable. Should use `$(logname)` or a variable.

- [GEM-F5] **MINOR**: Kill-switch runbook launchctl commands assume `sudo` context. LaunchAgent runs under `openclaw` user — should use `sudo -u openclaw launchctl stop/start`. Also notes `restart` is legacy; prefer explicit stop/start.

- [GEM-F6] **MINOR**: Backup strategy's "consider adding" language for `~/.openclaw/` is weak. Should be mandatory — include in Time Machine or equivalent.

- [GEM-F7] **MINOR**: P1 vetting policy's 30-minute time limit is arbitrary. Complex but critical skills may need more. Risk of "vetting fatigue." Recommends reframing around complexity rather than time, and scheduling vetting as a serious security task.

- [GEM-F8] **STRENGTH**: Permission isolation test suite is a standout feature — turns theoretical controls into testable reality.

- [GEM-F9] **STRENGTH**: Three-tier hardening model provides clear, progressive implementation path that prevents operator overwhelm.

- [GEM-F10] **STRENGTH**: Atomic-rename protocol is elegant — solves git write race condition without complex IPC, locking, or message bus. Excellent systems-thinking.

---

## Perplexity Sonar Reasoning Pro

(Note: Response truncated at MAX_TOKENS — 6 findings, 3 CRITICAL + 3 SIGNIFICANT.)

Overall assessment: Conditionally ready for implementation — Tier 1 + dedicated user setup can proceed immediately. Phase 2 should be held pending resolution of git safety (U4) and TCC validation (U5).

- [PPLX-F1] **CRITICAL**: OpenClaw dependency claims unverifiable from Perplexity's training data (April 2024 cutoff). CVEs, feature flags, ClawHub statistics, and GitHub issues cannot be independently confirmed. Recommends pre-implementation verification step.

- [PPLX-F2] **CRITICAL**: Git concurrent write safety (U4) remains unresolved. Phase 2 atomic-rename protocol has race conditions: (a) OpenClaw could write `.tmp-*` after pre-commit check but before tree write, (b) no git index refresh timing specified, (c) no `git gc`/`git repack` interaction considered. Pre-commit hook busy-wait is an anti-pattern. Recommends proper lock file protocol, or separate sync daemon, or holding Phase 2 until tested.

- [PPLX-F3] **CRITICAL**: TCC effectiveness (U5) unvalidated. TCC is user-centric (per-app), not per-Unix-user. File permissions, not TCC, are the actual enforcement mechanism. Spec should clarify that Unix permissions (`chmod`/`chown`) are the control, not TCC. Recommends removing TCC references and adding a pre-implementation isolation test.

- [PPLX-F4] **SIGNIFICANT**: A5 ("shared vault") wording conflicts with actual architecture (separate workspaces, mediated read, sandbox write). Should rewrite to clarify shared read access, separate workspaces.

- [PPLX-F5] **SIGNIFICANT**: Browser automation Phase 3 references "domain allowlist" without defining config location, format, behavior on non-listed domains, or maintenance process.

- [PPLX-F6] **SIGNIFICANT**: LaunchAgent vs LaunchDaemon confusion — LaunchAgent requires user login to run. If `openclaw` user never logs in, daemon won't start at boot. Spec doesn't clarify which is intended or how to handle this. (Truncated before fix.)

---

## Synthesis

### Consensus Findings

**1. launchd + nvm configuration is brittle and will break on Node updates** (OAI-F6, GEM-F2, PPLX-F6)
All three reviewers flagged this. The hardcoded versioned Node path in the plist is guaranteed to fail after any Node update. Both Gemini and GPT-5.2 recommend a wrapper script that sources nvm and uses `exec openclaw daemon`. Additionally, Perplexity and GPT-5.2 flagged the LaunchAgent vs LaunchDaemon confusion — LaunchAgent requires the user to be logged in.

**2. TCC / permission model needs empirical testing** (OAI-F5, PPLX-F3)
GPT-5.2 warns about TCC permission creep. Perplexity says TCC is per-app, not per-Unix-user, and the actual control is Unix permissions. The consensus: the spec should stop invoking TCC as a control, rely explicitly on Unix permissions, and test them empirically on the Studio before deployment.

**3. Vault read access model is internally inconsistent** (OAI-F3, OAI-F4, PPLX-F4)
GPT-5.2 identified the core contradiction: the spec says reads are "mediated through a dedicated skill" but grants OS-level read to the entire vault. Perplexity flagged A5's "shared vault" language as misleading. Either adopt a strict model (curated context mirror, no direct vault read) or acknowledge that OS-level read access is the reality and the "mediated skill" is a convenience layer, not a security boundary.

**4. Dedicated macOS user should be Tier 1 mandatory, not Tier 2 recommended** (GEM-F1)
Gemini flagged this as CRITICAL: the spec itself calls the dedicated user the "single most impactful control" and the backstop for `workspaceOnly` failure, yet classifies it as Tier 2 "recommended." The migration runbook already implements it as part of initial setup — the tiering should match.

**5. LaunchAgent vs LaunchDaemon confusion** (OAI-F7, PPLX-F6, GEM-F5)
All three noted issues with launchctl terminology or commands. LaunchAgent runs in user context (requires login); LaunchDaemon runs system-wide at boot. Kill-switch runbook uses commands that may not work as written.

**6. Secrets management beyond chmod** (GEM-F3, OAI-F3)
Gemini flagged that `chmod 600` leaves secrets in plaintext on disk — compromised `openclaw` user can trivially read them. Recommends macOS Keychain or 1Password CLI to load secrets as env vars at runtime. GPT-5.2's permission model finding also touches on this.

### Unique Findings

- **OAI-F8** (Kill-switch runbook lacks global emergency stop + correct launchctl commands): Genuine operational insight. `launchctl restart` is unreliable; should use `bootout`/`bootstrap`. Need a single "stop everything" path.
- **OAI-F10** (P1 egress control unenforced): Genuine gap. "No non-whitelisted network calls" is policy without mechanism. Little Snitch / LuLu at Tier 2 would provide enforcement.
- **OAI-F14** (Vault skill underspecified — no allowlist, redaction, size limits): Genuine gap. Without guardrails the vault skill will expand to "read everything."
- **PPLX-F5** (Browser domain allowlist undefined): Valid. Phase 3 references "explicit domain allowlist" but defines no config format or behavior.
- **GEM-F4** (Runbook hardcodes `dturner` username): Minor portability issue — use `$(logname)`.
- **GEM-F7** (P1 30-minute vetting time limit is arbitrary): Valid. Complex but critical skills may need more. Reframe around complexity, not clock time.
- **GEM-F10** (Atomic-rename protocol is elegant): STRENGTH — Gemini praised this as excellent systems-thinking. Counterbalances PPLX-F2's criticism of the same protocol. The truth is probably in between: the design is sound for Phase 1 but needs hardening for Phase 2 concurrent write loads.

### Contradictions

**Atomic-rename protocol:** Gemini praised it as "elegant and robust" (GEM-F10). Perplexity called it insufficient with race conditions (PPLX-F2). Resolution: the protocol is sound for the current Phase 1 design (where `_openclaw/` is gitignored and concurrent git operations don't apply). For Phase 2 (when `_openclaw/` enters git tracking), it needs the lock file enhancement Perplexity recommends.

**TCC:** Round 1 Gemini said TCC would block cross-user access and needed pre-authorization (Full Disk Access). Full-response Gemini (this round) didn't raise TCC at all. Perplexity says TCC is irrelevant for Unix-level file operations. Resolution: empirical test on the Studio. This remains U5.

**Vault read model:** GPT-5.2 recommends a strict "context mirror" (no direct vault read). Perplexity's fix is to rewrite A5 to clarify the current model. These are different levels of ambition — the strict model is more secure but more complex to implement.

### Action Items

**Must-fix** (critical or consensus):

- **A1.** Replace hardcoded nvm Node path in launchd plist with a wrapper script (`launch-openclaw.sh`) that sources nvm and runs `exec openclaw daemon`. Both Gemini and GPT-5.2 provided templates. (Sources: OAI-F6, GEM-F2)
- **A2.** Resolve LaunchAgent vs LaunchDaemon: clarify that LaunchAgent is intended, and document how to ensure the `openclaw` user's agent starts at boot without interactive login (e.g., `launchctl bootstrap`). Or switch to LaunchDaemon with explicit "do not run as root" safeguards. Fix kill-switch runbook to use correct launchctl commands (`sudo -u openclaw launchctl stop/start`). (Sources: OAI-F7, PPLX-F6, GEM-F5)
- **A3.** Remove TCC from the spec as a security control. Replace U5 with a pre-implementation test: empirically verify whether TCC blocks the `openclaw` user's cross-user vault access on the Studio. Document result. The actual controls are Unix file permissions. (Sources: OAI-F5, PPLX-F3)
- **A4.** Make the vault read access model consistent. Choose: (a) strict — curated context mirror, no OS-level vault read for `openclaw` user, or (b) relaxed — OS-level read is reality, "mediated skill" is convenience not security. Either way, fix the permissions in the runbook to match and ensure read+traverse on all subdirectories. (Sources: OAI-F3, OAI-F4, PPLX-F4)
- **A5.** Move dedicated macOS user from Tier 2 to Tier 1. The spec already calls it the "single most impactful control" and the runbook implements it at install time — the tier classification should match. (Source: GEM-F1)
- **A6.** Fix Tier numbering (Tier 1 and 2 both have item 11). Normalize LaunchAgent/LaunchDaemon terminology throughout. (Source: OAI-F7)

**Should-fix** (significant, not blocking):

- **A7.** Add global emergency stop section to kill-switch runbook with correct launchctl commands (`bootout`/`bootstrap`), post-incident containment checklist (logs, credential rotation scope, network containment), then per-platform steps. (Source: OAI-F8)
- **A8.** Strengthen Phase 2 git write protocol: add proper lock file mechanism (not busy-wait), specify index refresh timing, or adopt separate sync daemon approach. Hold Phase 2 until tested under concurrent write load. (Sources: OAI-F11, PPLX-F2)
- **A9.** Add minimal egress control to Tier 2: Little Snitch / LuLu rules for the `openclaw` user restricting outbound to messaging + model provider domains. Provide required domains table. (Source: OAI-F10)
- **A10.** Specify vault skill contract: allowlisted paths/globs, denylisted paths, max bytes per request, mandatory redaction patterns for API keys before returning context. (Source: OAI-F14)
- **A11.** Define browser domain allowlist config: location, format, behavior on non-listed domains, maintenance schedule. (Source: PPLX-F5)
- **A12.** Fix permission test suite to use absolute paths instead of `~` expansion. Add tests for Keychain access denial. (Source: OAI-F12)
- **A13.** Rewrite A5 to clarify: shared read access (mediated), separate workspaces, sandbox-only write. (Source: PPLX-F4)
- **A14.** Investigate secrets management beyond `chmod 600`: macOS Keychain or 1Password CLI to load secrets as env vars at runtime via the wrapper script. (Source: GEM-F3)
- **A15.** Strengthen `~/.openclaw/` backup recommendation from "consider" to mandatory. Include in Time Machine or equivalent. (Source: GEM-F6)

**Defer** (minor or speculative):

- **A16.** Map aspirational mitigations to actual OpenClaw config keys or mark as "not yet supported, track upstream." (Source: OAI-F9)
- **A17.** Move `.tmp-*` files to hidden subdir to avoid Obsidian indexing churn. (Source: OAI-F11)
- **A18.** Replace hardcoded `dturner` in runbook with `$(logname)`. (Source: GEM-F4)
- **A19.** Reframe P1 vetting time limit around complexity rather than clock time. (Source: GEM-F7)

### Considered and Declined

- **PPLX-F1 (OpenClaw dependency claims unverifiable):** `constraint` — Perplexity's training data cutoff (April 2024) predates the spec's context. All referenced facts were verified through direct web research during spec creation in round 1. Same finding as round 1 — declined for the same reason.
- **OAI-F4 strict model (curated context mirror):** Not declined outright — listed as option (a) in A4. But the strict model adds significant implementation complexity (who populates the mirror? how often? what's included?) that may be premature for Phase 1. Decision deferred to A4 resolution.
- **GEM-F3 secrets management (Keychain / 1Password CLI):** Not declined — listed as A14 should-fix. But this is an enhancement over the current `chmod 600` baseline, not a gap in the security model. The dedicated user already prevents cross-user access to credential files; secrets management would add defense against compromise of the `openclaw` user itself.
