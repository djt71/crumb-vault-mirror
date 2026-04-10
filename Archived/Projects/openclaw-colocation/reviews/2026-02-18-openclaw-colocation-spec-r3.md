---
type: review
review_mode: full
review_round: 3
prior_review: Projects/openclaw-colocation/reviews/2026-02-18-openclaw-colocation-spec-r2.md
artifact: docs/openclaw-colocation-spec.md
artifact_type: spec
artifact_hash: ff3d823c
prompt_hash: f50c2cde
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
  max_tokens_openai: 8192
  max_tokens_google: 8192
  max_tokens_perplexity: 65536
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  note: "Generic secrets pattern matched '/newtoken' (Telegram BotFather command) and 1Password CLI example — both false positives, downgraded."
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 57991
    attempts: 1
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-openai-r3.json
  google:
    http_status: 200
    latency_ms: 49623
    attempts: 3
    note: "gemini-3-pro-preview returned 503 (high demand) after 3 attempts. Fell back to gemini-2.5-pro — complete response (STOP)."
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-google-r3.json
  perplexity:
    http_status: 200
    latency_ms: 101616
    attempts: 1
    note: "First round 3 review at max_tokens 65536 — complete response (stop). No truncation."
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-perplexity-r3.json
tags:
  - review
  - peer-review
  - security
  - openclaw
---

# Peer Review Round 3: OpenClaw + Crumb Colocation Specification

**Artifact:** `docs/openclaw-colocation-spec.md`
**Mode:** full
**Round:** 3 (prior: `_system/reviews/2026-02-18-openclaw-colocation-spec-r2.md`)
**Reviewed:** 2026-02-18
**Reviewers:** OpenAI GPT-5.2, Google Gemini 2.5 Pro, Perplexity Sonar Reasoning Pro
**Review prompt:** Round 3 full review of updated spec. Asked reviewers to evaluate (1) internal consistency after two rounds of revisions, (2) implementation readiness for a solo operator, (3) security model coherence, (4) operational sustainability, (5) new issues from R2 revisions.

---

## OpenAI GPT-5.2

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: **LaunchAgent “starts at boot without login” claim is internally inconsistent / likely incorrect as written.**
- [Why]: The spec says to “use `launchctl bootstrap gui/$(id -u openclaw)` … at system startup” to start the LaunchAgent without interactive login. On macOS, `gui/<uid>` domains generally exist when that user has a GUI login session; at true boot time there may be no GUI session for `openclaw`, so the agent won’t run until login. This contradicts the “always-on daemon via launchd” goal and may lead to a false sense of availability/security controls.
- [Fix]: Decide and document one supported always-on method:
  - **Option 1 (preferred for always-on)**: Use a **LaunchDaemon** running as the **`openclaw` user** (not root) with `UserName`/`GroupName` in the daemon plist, plus a hardened environment (no TCC permissions, minimal PATH, wrapper script). Clarify that “LaunchDaemon ≠ root” if configured with `UserName`.  
  - **Option 2**: Keep LaunchAgent but explicitly require **auto-login** (and document why it’s less preferred and how to mitigate).  
  - **Option 3**: Use `loginwindow`/`EnableSessions` style approaches—if you choose this, provide tested commands and constraints.
  Also update all references that imply “boot start” for a LaunchAgent.

- [F2]
- [Severity]: CRITICAL
- [Finding]: **`nvm` installation steps are incomplete/incorrect for a new user context (and contradict prerequisites).**
- [Why]: The runbook says prerequisite “nvm is installed (`brew install nvm`)” and then runs `sudo -u openclaw bash -c 'source ~/.nvm/nvm.sh …'`. On a fresh `openclaw` user, `~/.nvm/nvm.sh` won’t exist just because Homebrew installed `nvm` for the primary user. This will fail during installation and also undermine the wrapper-script approach.
- [Fix]: Make the Node installation approach explicit and per-user:
  - If using Homebrew `nvm`: add steps to create `/Users/openclaw/.nvm`, install/symlink `nvm.sh`, and ensure permissions. Example: install Homebrew for `openclaw` (heavy) **or** source a system-wide `nvm.sh` path if you standardize it.
  - Consider a simpler, more “launchd-friendly” approach: install Node 22 via **mise**, **asdf**, or a **fixed Node binary path** for the `openclaw` user, and keep the wrapper script but remove `nvm` complexity.
  - At minimum: add a “validate nvm works for `openclaw`” command and a clear “if this fails, do X” branch.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: **Contradiction/tension between “workspace is outside vault” and “OpenClaw reads vault through a skill, not raw filesystem access.”**
- [Why]: The spec correctly notes the vault skill is a *curation layer, not a boundary*, and that OS permissions permit raw reads. But Tier 1 item #4 says “OpenClaw reads the vault through a dedicated vault skill … not through unrestricted file access,” which can be read as a stronger guarantee than actually exists. This can cause operators to under-estimate what a compromised skill can read (any readable vault file).
- [Fix]: Rephrase Tier 1 #4 to match the later architecture section, e.g. “Workspace remains outside vault; **vault access is present at OS level (read-only)**, and the vault skill is used for data minimization.”

- [F4]
- [Severity]: CRITICAL
- [Finding]: **Vault permission commands risk breaking primary-user workflows and/or are under-specified (ACLs, existing modes, ownership, Obsidian behavior).**
- [Why]: `chmod -R g+rX,g-w ~/crumb-vault` and recursive `chgrp -R` can:
  - unintentionally change execute bits / modes on scripts and tooling,
  - interfere with existing per-directory permission intent,
  - collide with macOS ACLs, extended attributes, or prior group setups,
  - create maintenance burden (new files created by the primary user may not inherit group as expected without setgid bit).
- [Fix]: Make the permissions model precise and durable:
  - Use **setgid** on vault directories that should inherit group: `chmod g+s` on `~/crumb-vault` (and/or specific subtrees).
  - Specify a **umask** or default ACL strategy for the primary user so new files remain group-readable where intended.
  - Add explicit guidance: “Do not apply these commands until you’ve confirmed vault has no custom ACLs; snapshot current permissions first (`ls -leR` to a file).”
  - Provide a rollback snippet.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: **Kill-switch `launchctl` identifiers assume a specific label/path that the runbook never standardizes.**
- [Why]: Commands reference `com.openclaw.daemon` and `~/Library/LaunchAgents/com.openclaw.daemon.plist`, but the installation step says “Choose LaunchAgent installation… update plist ProgramArguments…” without confirming the exact label OpenClaw generates. If the label differs, emergency stop/restart instructions will fail under stress.
- [Fix]: Add a step to record and standardize the LaunchAgent label:
  - After onboarding: `sudo -u openclaw launchctl print gui/$(id -u openclaw) | grep -i openclaw` (or `launchctl list | grep openclaw`) and write the exact label into the runbook.
  - Recommend renaming the plist to a fixed name you control, and set `<key>Label</key>` explicitly.

- [F6]
- [Severity]: MINOR
- [Finding]: **Some commands likely need Full Disk Access to succeed, but the spec also says “never grant FDA.”**
- [Why]: The permission test suite includes reading `~/Library/Keychains/`. Depending on macOS version and protections, even listing may be blocked or behave inconsistently under privacy protections; this can create confusing “false failures.” It’s good to test, but the expected outcome may not reliably be “Permission denied” vs “Operation not permitted.”
- [Fix]: Adjust the test suite to focus on plain Unix-permission boundaries you control (e.g., `.config/crumb/.env`, `.ssh`, vault write attempts), and treat Keychains as an informational check with version-dependent outcomes.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: **Egress allowlist is underspecified and may break real platform connectivity; also contradicts “block all other outbound from the OpenClaw process” feasibility.**
- [Why]: Services like Discord/Slack often use multiple domains/CDNs; WhatsApp/Baileys can touch additional endpoints; LLM providers may use multiple hostnames. A too-tight allowlist will cause instability, leading operators to disable the control entirely.
- [Fix]: Reframe as “default-deny with an onboarding learning period”:
  - Start in **alert mode** to observe required domains for 48–72 hours, then lock down.
  - Provide guidance for maintaining the list (where to look in logs, how to add domains safely).
  - Distinguish OpenClaw process vs child processes (Chromium) explicitly.

- [F8]
- [Severity]: CRITICAL
- [Finding]: **No explicit statement of what “OpenClaw uses whatever models are configured” means for secret placement; risk of accidentally reusing Crumb’s Anthropic key.**
- [Why]: You strongly separate key stores, but the operational reality is that operators may reuse keys for convenience. The spec doesn’t include an explicit “create separate API keys/projects” step, nor verification that OpenClaw cannot read Crumb’s env or shell.
- [Fix]: Add a concrete “separate keys” procedure:
  - Create dedicated API keys/projects per provider for OpenClaw.
  - Verify no provider keys exist in the primary user environment visible to OpenClaw (already partially tested), plus verify OpenClaw config contains only its own keys.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: **Resource limits are referenced but not made actionable (no sample plist keys/values, no tested limits).**
- [Why]: T9 mitigation relies on `HardResourceLimits/SoftResourceLimits`, but solo operators need ready-to-apply examples; otherwise this remains aspirational.
- [Fix]: Provide a minimal, tested plist snippet (CPU, file descriptors, memory if applicable) and a “start conservative / adjust” note. If macOS launchd limits are insufficient, say so and point to alternative controls (e.g., `ulimit` in wrapper, or `taskpolicy`).

- [F10]
- [Severity]: MINOR
- [Finding]: **Stale / inconsistent references remain (“spec §9” vs this doc, “docs/openclaw-crumb-reference.md referenced but never created”).**
- [Why]: You note OC-006, but within this spec there are multiple references to “spec §9” (Crumb spec) while also embedding an “updated” §9 excerpt. This can confuse what is canonical.
- [Fix]: Add an explicit “Source of truth” note: which document governs vault integration right now, and what must be updated in Crumb spec to mirror this. Consider changing “from spec §9” headings to “proposed §9 patch content”.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: **“Do not use LaunchDaemon — it runs as root” is an overgeneralization that may have been introduced by revisions and can lead to worse outcomes.**
- [Why]: If LaunchAgent cannot meet always-on requirements, forbidding LaunchDaemon categorically pushes operators toward auto-login or other weaker choices. LaunchDaemons *can* run as a non-root user using `UserName`; the security posture can still be strong (and sometimes stronger operationally).
- [Fix]: Replace the absolute rule with a policy:
  - “Do not run OpenClaw as root. Prefer LaunchAgent when acceptable; otherwise use LaunchDaemon configured to run as `openclaw` user.”

- [F12]
- [Severity]: STRENGTH
- [Finding]: **Two-layer model (dedicated OS user + workspaceOnly) is explained correctly as defense-in-depth, not reliance on app controls.**
- [Why]: The spec repeatedly clarifies that `workspaceOnly` is unaudited and not a primary boundary, and that OS-level isolation is the backstop. This is coherent and aligns mitigations with the key risk (credential theft/lateral movement).
- [Fix]: None.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: **Vault read access for `openclaw` user is a major intentional exposure, but the threat model doesn’t clearly rate/accept “vault content exfiltration” as a first-class risk.**
- [Why]: Even if credentials are protected, a compromised skill/prompt injection can exfiltrate private notes/specs from the vault (which may contain sensitive information even without API keys). The model currently focuses heavily on credential theft, less on privacy/data leakage of notes.
- [Fix]: Add a distinct threat entry (e.g., “T12 Vault content exfiltration (MEDIUM/HIGH depending on vault sensitivity)”) with mitigations: minimization via vault skill, egress controls, and possibly splitting the vault into “shareable context” vs “private” vault not group-readable.

- [F14]
- [Severity]: MINOR
- [Finding]: **Backup scope guidance is good but incomplete regarding secret material.**
- [Why]: You propose later moving secrets to Keychain/1Password to keep them out of backups, but currently `/Users/openclaw/.openclaw/openclaw.json` (with tokens) will be captured by Time Machine. That’s acceptable if backups are encrypted, but it should be stated.
- [Fix]: Add: “Ensure Time Machine backups are encrypted” and/or exclude specific files if desired (with trade-offs). Provide an explicit stance.

- [F15]
- [Severity]: STRENGTH
- [Finding]: **Kill-switch runbook includes containment, forensics capture before rotation, and restart procedure—operationally realistic.**
- [Why]: The sequencing is correct (stop → contain → preserve artifacts → rotate). This is a practical solo-operator playbook.
- [Fix]: Add one small hardening: store incident artifacts under a root-owned directory with restricted perms (e.g., `/var/tmp/...` with `chmod 700`) to avoid accidental exposure.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: **Some installation commands will fail due to missing directories and ownership assumptions (e.g., logs dir, workspace dir, plist path).**
- [Why]: The spec assumes paths like `~/.openclaw/logs/` exist, and that the plist is in `~/Library/LaunchAgents/…` for `openclaw`. In practice, operators need explicit “create directory” steps and validation commands.
- [Fix]: Add a “create required directories” step for `/Users/openclaw/.openclaw/{workspace,logs}` and confirm the actual plist location after `openclaw onboard`.

- [F17]
- [Severity]: MINOR
- [Finding]: **Tiering and cadence are mostly coherent, but “patch within 48h for first 60 days” may be operationally brittle.**
- [Why]: Solo operators may miss a 48h SLA; failing to meet it can cause guilt-driven abandonment of the whole process. Better to define escalation criteria (RCE vs low severity) and an achievable routine.
- [Fix]: Make the SLA conditional: e.g., “RCE/credential exposure advisories: 48h; others: next weekly window,” while keeping P2 intent.

Overall: the document is broadly coherent after round 2 (notably: TCC correction, wrapper script for launchd+nvm, clarified vault access model, corrected `launchctl` usage). Implementation readiness is close, but hinges on resolving the **always-on LaunchAgent vs boot reality**, and tightening the **Node/nvm per-user install** plus **permissions durability**. Security model is coherent, but should explicitly acknowledge/mitigate **vault content exfiltration** as distinct from credential compromise. Operational sustainability is reasonable if you make egress controls and updates more “operator-proof” with observation periods and concrete, tested snippets.

---

## Google Gemini 2.5 Pro

Excellent. This is a comprehensive and well-structured specification that has clearly benefited from previous review rounds. The security posture is strong, the layering of defenses is sound, and the operational considerations are thorough. My evaluation finds it to be very close to implementation-ready, with a few critical gaps in the runbook and some areas where risk could be stated more explicitly.

Here is a structured review based on your evaluation criteria.

---

### 1. Internal Consistency

The specification is largely internally consistent. Decisions made in one section (e.g., dedicated user) are reflected properly in others (e.g., runbook, threat model, vault access model). However, a few minor inconsistencies and ambiguities remain.

-   **[F1]**
    -   **Severity**: MINOR
    -   **Finding**: The System Map diagram's "Shared Vault (~/)" label is slightly ambiguous and inconsistent with the more precise text. The vault physically resides at `~/crumb-vault/` under the primary user, not at the root of their home directory (`~`).
    -   **Why**: A diagram is often the first thing an implementer internalizes. This slight inaccuracy could create a momentary misconception, although the detailed text clarifies the correct path.
    -   **Fix**: Update the diagram's text to be more specific, for example: `Shared Vault (~/crumb-vault/)`.

-   **[F2]**
    -   **Severity**: MINOR
    -   **Finding**: The runbook section "Updates to Existing Phases" suggests that "Phase 2 (Brew packages): Node version may need to be ≥22 for OpenClaw." This contradicts the more robust decision made elsewhere to use NVM to manage Node versions for both users.
    -   **Why**: This creates a conflicting instruction. An operator might install Node 22 via Homebrew, creating potential PATH conflicts with the primary user's environment, whereas the rest of the spec correctly pushes for NVM as the centralized tool for managing Node versions.
    -   **Fix**: Reword the instruction to be prescriptive about using NVM for both users. Change it to: "**Phase 2 (Brew packages):** Ensure `nvm` is installed. Do not install `node` via Homebrew. All Node.js versions for both the primary user and the `openclaw` user should be managed via `nvm` to prevent version conflicts."

### 2. Implementation Readiness

The spec is highly implementation-ready, with detailed commands and verification steps. However, there is one critical error in the runbook that would cause the setup to fail.

-   **[F3]**
    -   **Severity**: CRITICAL
    -   **Finding**: The runbook command to install Node.js for the `openclaw` user is out of order. Step 2 (`sudo -u openclaw bash -c 'source ~/.nvm/nvm.sh && nvm install 22'`) attempts to source `nvm.sh` before NVM has been installed for that user, which will fail. The `nvm` installation for the new user is missing.
    -   **Why**: The operator following the runbook will encounter a "command not found" or "no such file or directory" error, blocking the entire installation.
    -   **Fix**: Modify the runbook's "Setup" section. The installation of NVM must be done for the `openclaw` user *before* it can be used.

    **Suggested Correction for Runbook Step 2:**
    ```diff
    - 2. Install Node.js ≥22 for the openclaw user:
    -    sudo -u openclaw bash -c 'source ~/.nvm/nvm.sh && nvm install 22'
    + 2. Install NVM and Node.js ≥22 for the openclaw user:
    +    # Run a shell as the 'openclaw' user to install nvm
    +    sudo -u openclaw bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
    +    # Use another shell to install Node.js using the newly installed nvm
    +    sudo -u openclaw bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install 22'
    ```
    *Note: The NVM version in the URL may need to be updated to the latest stable release at the time of implementation.*

-   **[F4]**
    -   **Severity**: MINOR
    -   **Finding**: In the runbook (Step 4), the instruction `Update plist ProgramArguments to call /Users/openclaw/launch-openclaw.sh` after running `openclaw onboard` is ambiguous. It doesn't specify *how* the operator should do this.
    -   **Why**: A less experienced operator might not know whether `onboard` provides an interactive editor, or if they need to manually find and edit the generated plist file (e.g., `~/Library/LaunchAgents/com.openclaw.daemon.plist`) with a text editor or `plutil`.
    -   **Fix**: Add a more explicit instruction. For example: "After `onboard` completes, manually edit `/Users/openclaw/Library/LaunchAgents/com.openclaw.daemon.plist` to change the `ProgramArguments` key to point to the wrapper script. You can use a text editor or `plutil`."

-   **[F5]**
    -   **Severity**: MINOR
    -   **Finding**: The `launchctl bootout / bootstrap` commands in the Kill-Switch runbook are functional but less modern and idempotent than `launchctl enable / kickstart`.
    -   **Why**: While the provided commands work, using the more modern `enable/disable/kickstart` verbs is generally considered better practice on recent macOS versions, as they align more closely with the service management model and can be more resilient.
    -   **Fix**: Add a note or replace the commands.
    ```bash
    # Alternative modern restart sequence
    OC_UID=$(id -u openclaw)
    # Ensure the service is enabled to run at login
    sudo -u openclaw launchctl enable gui/$OC_UID/com.openclaw.daemon
    # Stop the current instance and immediately restart it
    sudo -u openclaw launchctl kickstart -k gui/$OC_UID/com.openclaw.daemon
    ```
    This is a minor point of operational preference but improves the long-term maintainability.

### 3. Security Model Coherence

The security model is coherent, robust, and well-reasoned. The two-layer isolation is the correct architecture. Mitigations are well-matched to threats.

-   **[F6]**
    -   **Severity**: SIGNIFICANT
    -   **Finding**: The risk of a compromised OpenClaw instance exfiltrating the *entire contents* of the Crumb vault is acknowledged but understated. The spec states "vault content (notes, specs, docs) is readable; credentials are not." This is a massive attack surface.
    -   **Why**: While credentials are protected (the primary goal), the vault could contain sensitive PII, private thoughts, strategic plans, or intellectual property. A compromised skill could silently exfiltrate all of this data. The current framing presents this as an accepted design choice, but the severity of the potential data loss is not fully conveyed.
    -   **Fix**: Elevate the visibility and gravity of this accepted risk. Add a bolded paragraph in the "Vault Access Model" section:
        "**WARNING: Risk Acceptance of Vault Read Access.** The `openclaw` user is granted read access to the *entire* `~/crumb-vault/`. This is by design to provide context to the agent. However, this means a successful prompt injection or malicious skill that bypasses the `workspaceOnly` control **can read and exfiltrate all non-credential data within the vault.** This is the primary architectural trade-off. The operator must not store any data in the vault that they are unwilling to risk being exposed by a compromised OpenClaw instance."

-   **[F7]**
    -   **Severity**: STRENGTH
    -   **Finding**: The defense-in-depth model is exceptionally well-articulated. The spec correctly identifies OS-level user separation as the primary security boundary and application-level controls (`workspaceOnly`) as a secondary, untrusted mitigation.
    -   **Why**: This is the most important architectural decision, and the spec gets it right. It prevents a single application-level vulnerability (which is likely in a system like OpenClaw) from becoming a catastrophic host compromise.

-   **[F8]**
    -   **Severity**: STRENGTH
    -   **Finding**: The permission isolation test suite in the runbook is an outstanding feature.
    -   **Why**: It provides a concrete, automatable way for the operator to empirically verify that the core security boundary (filesystem isolation) is working as intended. This moves the security from theoretical to testable, which is critical for implementation confidence.

### 4. Operational Sustainability

The spec demonstrates strong foresight for long-term maintenance by a solo operator.

-   **[F9]**
    -   **Severity**: STRENGTH
    -   **Finding**: The Messaging Platform Kill-Switch Runbook is detailed, platform-specific, and provides clear, actionable steps for incident response.
    -   **Why**: For an always-on agent with messaging interfaces, this kind of runbook is not a "nice-to-have"; it's essential. It transforms a potential panic situation into a methodical procedure, which is invaluable for a solo operator.

-   **[F10]**
    -   **Severity**: STRENGTH
    -   **Finding**: The plan for secrets management, with a practical baseline (`chmod 600`) and a clear path to a more secure future state (Keychain/1Password CLI), is realistic and demonstrates maturity.
    -   **Why**: It avoids over-engineering the initial setup while acknowledging and planning to mitigate the risk of plaintext secrets on disk in the long term.

### 5. New Issues Introduced by Round 2 Revisions

The round 2 revisions were highly effective and introduced no significant new security flaws. The main new issue is the implementation error in the runbook that stemmed from the (correct) decision to use a wrapper script.

-   **[F11]**
    -   **Severity**: MINOR (Side effect of a good change)
    -   **Finding**: The R2 decision to use a wrapper script for `launchd` and NVM was correct, but its translation into the runbook introduced the critical implementation bug identified in **[F3]**.
    -   **Why**: This highlights a common pattern where a high-level architectural decision is sound, but the low-level implementation details introduce new errors. The concept was an improvement; the execution in the draft spec was flawed.
    -   **Fix**: See **[F3]**.

### Overall Assessment

This is an A-grade specification. It is deeply considered, security-focused, and operationally realistic. After addressing the critical runbook error (**F3**) and clarifying the vault read-access risk (**F6**), a competent solo operator should be able to follow this document to set up a robust and defensible OpenClaw installation. The system is as secure as can be reasonably expected given the inherent risks of running an autonomous agent like OpenClaw. The spec is ready for implementation after these final adjustments.

---

## Perplexity Sonar Reasoning Pro

# Review: OpenClaw + Crumb Colocation Specification (Round 3)

## Executive Summary

The specification demonstrates **strong coherence in the overall security architecture** — the dedicated-user + workspaceOnly + vault isolation model is sound in principle. However, there are **4 CRITICAL gaps in implementation readiness** that would likely cause setup failures for a solo operator, **3 SIGNIFICANT** operational ambiguities that leave the threat model partially unresolved, and **5 MINOR** inconsistencies introduced by Round 2 revisions. The permission isolation test suite is thorough but positioned as optional rather than mandatory, which weakens the security model's empirical validation.

---

## Findings

### CRITICAL

**F1: LaunchAgent plist installation path undefined in runbook**
- **Severity:** CRITICAL
- **Finding:** The runbook directs the operator to run `openclaw onboard`, which presumably creates the LaunchAgent plist. However, the exact path (`/Users/openclaw/Library/LaunchAgents/com.openclaw.daemon.plist`) is never stated, and the subsequent step to update ProgramArguments assumes the plist exists but doesn't say where to find it or confirm it was created.
- **Why:** If onboard fails silently or places the plist in the wrong location, the daemon won't start at boot. The operator won't know why without debugging. For a solo operator, this is a critical path blocker.
- **Fix:** Add an explicit verification step after onboard:
  ```bash
  PLIST="/Users/openclaw/Library/LaunchAgents/com.openclaw.daemon.plist"
  if [ ! -f "$PLIST" ]; then
    echo "ERROR: LaunchAgent plist not found at $PLIST. Onboard may have failed."
    exit 1
  fi
  # Then verify and update ProgramArguments
  plutil -p "$PLIST" | grep ProgramArguments
  ```
  Alternatively, pre-create the plist template as part of the runbook before calling onboard, or confirm that onboard's output explicitly mentions the plist path.

---

**F2: Wrapper script testing before LaunchAgent loading**
- **Severity:** CRITICAL
- **Finding:** The runbook creates `/Users/openclaw/launch-openclaw.sh` and then immediately uses it in the LaunchAgent plist without testing it. If the script has a syntax error, a missing nvm installation, or permission issues, the LaunchAgent will fail silently (launchd logs errors to `~/Library/Logs/` but the operator may not check there). The daemon appears to be running (it's in the plist) but actually exits immediately.
- **Why:** Silent failure is the most dangerous failure mode for a daemon. The operator believes OpenClaw is running when it isn't, missing the entire security architecture.
- **Fix:** Add a pre-load test:
  ```bash
  # Test the wrapper script before loading the plist
  sudo -u openclaw bash /Users/openclaw/launch-openclaw.sh &
  TEST_PID=$!
  sleep 2
  if ! kill $TEST_PID 2>/dev/null; then
    echo "Wrapper script exited prematurely. Check ~openclaw/.bash_history or launchd logs."
    cat /Users/openclaw/Library/Logs/com.openclaw.daemon.log.* 2>/dev/null
    exit 1
  fi
  kill $TEST_PID 2>/dev/null
  ```
  Or simpler: run `sudo -u openclaw /Users/openclaw/launch-openclaw.sh` with a timeout and verify it launches the daemon without immediately exiting.

---

**F3: Permission isolation test suite is optional, not mandatory**
- **Severity:** CRITICAL
- **Finding:** The runbook includes a detailed permission isolation test suite (checks that `openslaw` user can read vault but not `~/.config/crumb/.env`, etc.) positioned as "Tier 1 verification checks" and "permission isolation test suite." However, the main runbook doesn't explicitly require running these tests before proceeding to the next phase. A solo operator might skip them, assuming `chmod` and `dseditgroup` commands worked correctly.
- **Why:** The entire security model depends on the OS-level filesystem boundary being enforced. Without empirical verification that the `openclaw` user **actually cannot** read Crumb credentials, the spec's core claim — "OS-level isolation backstops application-layer `workspaceOnly`" — is unverified. If the test suite is skipped and the permissions are misconfigured, a compromised skill gains full access to all credentials.
- **Fix:** Integrate the permission isolation tests into the main runbook as a **go/no-go checkpoint** between steps 11 and 12 (after hardening is applied but before messaging platforms are connected):
  ```bash
  # Mandatory isolation test — must pass before proceeding
  TESTS_PASSED=0
  PRIMARY_USER=$(logname)
  
  echo "=== PERMISSION ISOLATION TESTS (MANDATORY) ==="
  # Test 1: OpenClaw cannot read Crumb API keys
  if sudo -u openclaw cat /Users/$PRIMARY_USER/.config/crumb/.env 2>&1 | grep -q "Permission denied"; then
    echo "✓ Test 1 PASS: openclaw user blocked from ~/.config/crumb/.env"
    ((TESTS_PASSED++))
  else
    echo "✗ Test 1 FAIL: openclaw user CAN READ ~/.config/crumb/.env — ISOLATION BROKEN"
    exit 1
  fi
  # [... repeat for ~/.ssh, ~/.zshrc, ~/Library/Keychains ...]
  # Test N: OpenClaw CAN read vault
  if sudo -u openclaw cat /Users/$PRIMARY_USER/crumb-vault/CLAUDE.md >/dev/null 2>&1; then
    echo "✓ Test N PASS: openclaw user CAN read vault"
    ((TESTS_PASSED++))
  else
    echo "✗ Test N FAIL: openclaw user cannot read vault (group permissions misconfigured)"
    exit 1
  fi
  
  if [ $TESTS_PASSED -eq $EXPECTED_TESTS ]; then
    echo "=== ALL ISOLATION TESTS PASSED ==="
  else
    echo "=== ISOLATION TESTS FAILED — DO NOT PROCEED ==="
    exit 1
  fi
  ```
  This prevents a solo operator from accidentally skipping the empirical validation.

---

**F4: `signal-cli` binary installation not mentioned in runbook**
- **Severity:** CRITICAL
- **Finding:** The spec lists Signal as a supported messaging platform via `signal-cli` (mentioned in T11, kill-switch runbook, and Tier 2 egress rules). However, the OpenClaw installation phase does not include a step to install `signal-cli`. The OpenClaw `npm` package may include it as a dependency, but this is not explicitly stated. If `signal-cli` is not bundled, the operator will attempt to connect Signal and the connection will fail without a clear error message.
- **Why:** Silent failure or cryptic dependency error breaks the operator's ability to set up messaging platforms as planned.
- **Fix:** Add explicit dependency verification and installation:
  ```bash
  # Verify signal-cli is available (may be bundled with OpenClaw or require separate install)
  if ! command -v signal-cli &> /dev/null; then
    echo "signal-cli not found. Installing via Homebrew..."
    brew install signal-cli
  fi
  ```
  Or document in a "Pre-install" section what external binaries are required (beyond npm packages). Query the current OpenClaw release notes to confirm the dependency model.

---

### SIGNIFICANT

**F5: Operational resolution of Tier 1 vs. Tier 2 controls under T4 (lateral movement) is undefined**
- **Severity:** SIGNIFICANT
- **Finding:** Threat T4 (lateral movement to Crumb credentials) describes the security model as: "(1) `workspaceOnly` at app layer, (2) dedicated user OS-level isolation, (3) restrictive file permissions." The spec correctly identifies `workspaceOnly` as the "primary defense" but unaudited (U3). If it fails, the OS-level user boundary is the backstop. However, the runbook doesn't define what the operator should do if they **detect** a `workspaceOnly` bypass (e.g., a skill reads a file outside workspace). There's no monitoring, alerting, or incident response procedure for this failure mode.
- **Why:** The spec claims the two-layer model makes catastrophic failure non-catastrophic ("failure of one layer = backstop"). But without detection and response procedures, the operator doesn't learn that `workspaceOnly` has failed until **after** the backup is exfiltrated.
- **Fix:** Add a Tier 1 or Tier 1.5 "Detection" layer:
  - **Mandatory logging:** Ensure OpenClaw logs all file access attempts (including failures). Direct logs to `/Users/openclaw/.openclaw/logs/access.log` with immutable permissions.
  - **Periodic log review:** Add to the credential rotation runbook: "Before rotating credentials, review `/Users/openclaw/.openclaw/logs/access.log` for the past 7 days. Filter for reads outside `~/.openclaw/workspace` or `~/crumb-vault/_openclaw/`. If any are found, this indicates a `workspaceOnly` bypass."
  - **Automated alert (optional, Tier 2):** Use `log stream --predicate 'eventMessage contains "PERMISSION DENIED"'` or similar to alert on permission denial attempts.

---

**F6: Phase 2 transition (git write protocol) is not scheduled or gated**
- **Severity:** SIGNIFICANT
- **Finding:** The vault integration architecture (§Vault Integration, Phase 2) describes a complex git write lock-file protocol to prevent index corruption from concurrent writes. However, Phase 2 has no acceptance criteria, no testing procedure, and no clear trigger for when it's "safe" to activate. The spec says "This protocol must be tested under concurrent write load (100+ writes while Crumb performs git operations) before Phase 2 is activated" but does not define who runs the test, when, or what "pass" looks like.
- **Why:** If Phase 2 is activated without testing, Crumb's vault can become corrupted. If it's never activated, OpenClaw's bidirectional research delegation (a key use case per spec §9) will never be implemented.
- **Fix:** Add a Phase 1→Phase 2 approval gate:
  ```markdown
  ### Phase 1→Phase 2 Transition Gate
  
  **Preconditions (all must be true):**
  - OpenClaw has been running stably for ≥30 days without security incidents
  - All credential rotations have been completed once (validates kill-switch runbook)
  - Vault read access is working (OpenClaw can access vault files via dedicated skill)
  
  **Testing (must be completed before Phase 2 activation):**
  1. Create a test concurrent-write harness:
     ```bash
     # Simulate 100 writes from openclaw to _openclaw/outbox/ while Crumb runs git ops
     for i in {1..100}; do
       sudo -u openclaw bash -c "echo 'test' > ~/crumb-vault/_openclaw/outbox/test-$i.txt" &
     done
     # In parallel, in another terminal:
     cd ~/crumb-vault && git add . && git commit -m "test" &
     wait
     # Verify git index is not corrupted
     git fsck --full
     ```
  2. Run 3 times; verify git fsck passes each time
  3. Document test results in `~/crumb-vault/docs/git-write-protocol-test-results.md`
  
  **Approval:**
  - Operator reviews test results
  - If any failures: defer Phase 2, investigate, remediate, re-test
  - If all pass: update `openclaw.json` to enable Phase 2 features (gitignore removal, exchange protocol enable)
  ```

---

**F7: Remote access (Tailscale) threat T8 is disabled indefinitely without Phase 2 gate**
- **Severity:** SIGNIFICANT
- **Finding:** T8 (remote access misconfiguration) describes Tailscale Serve/Funnel as the remote access mechanism, with detailed hardening (identity headers, password auth). The spec then says "Remote access disabled until Phase 2. Do not enable..." But Phase 2 is undefined (F6). There is no criteria for when Tailscale should be enabled or how to test it once enabled. This leaves the remote access threat permanently blocked but also permanently unresolved.
- **Why:** The operator may need remote access to OpenClaw at some point (querying the agent while away from home). If they enable Tailscale Funnel without waiting for Phase 2 documentation, they bypass all the hardening controls listed in T8.
- **Fix:** Create a separate Phase 1.5 or standalone runbook for "OpenClaw Remote Access Enablement" with explicit prerequisites and testing:
  ```markdown
  ### Remote Access Enablement (Phase 1.5, optional)
  
  **Prerequisites:**
  - OpenClaw stable for ≥30 days
  - All Tier 1 + Tier 2 hardening controls verified
  - Messaging platform integration tested and working
  
  **Hardening checklist before enabling:**
  - [ ] Tailscale account 2FA enabled
  - [ ] Tailscale ACLs configured (deny all by default, allow only your client IP)
  - [ ] Password auth enabled in openclaw.json: `"gateway": { "auth": { "mode": "password" } }`
  - [ ] Use Serve mode only (not Funnel): `"tailscale": { "mode": "serve" }`
  
  **Testing after enable:**
  - [ ] Verify binding is loopback: `lsof -iTCP:18789` should show 127.0.0.1 only, not 0.0.0.0
  - [ ] Verify no Funnel: `tailscale status` should show no "Funnel" line
  - [ ] Remote client can connect via Tailscale but NOT via public internet (confirm Funnel is off)
  - [ ] Password auth is required: connection without password is rejected
  ```
  Link this from the main spec so it's discoverable.

---

**F8: Credential rotation automation is manual and high-touch for solo operator**
- **Severity:** SIGNIFICANT
- **Finding:** The spec defines a monthly rotation schedule for messaging platform credentials (60 days) then quarterly. For 4 platforms × 12 times/year (first 60 days) = 48 platform credential rotations in the first 2 months. The kill-switch runbook provides the procedures, but each platform requires different steps (revoke token, generate new, update config, restart daemon). The spec does not provide a `cron` job, calendar reminder, or script to automate or remind the operator of rotations.
- **Why:** Manual monthly rotations are error-prone and easy to forget. If a rotation is skipped, a compromised credential continues to be valid. If the operator gets behind, the operational burden grows.
- **Fix:** Provide a rotation reminder + script:
  ```bash
  # /Users/openclaw/rotate-credentials.sh (not automated, but scaffolded)
  #!/bin/bash
  # Run this script monthly to rotate all messaging platform credentials
  # Usage: sudo -u openclaw ~/rotate-credentials.sh
  
  ROTATION_LOG="$HOME/.openclaw/rotation-log.txt"
  LAST_ROTATION=$(tail -1 "$ROTATION_LOG" 2>/dev/null | awk '{print $1}')
  DAYS_SINCE=$(( ($(date +%s) - $(date -f "$LAST_ROTATION" +%s 2>/dev/null || echo 0)) / 86400 ))
  
  if [ "$DAYS_SINCE" -lt 28 ] && [ "$DAYS_SINCE" -gt 0 ]; then
    echo "Last rotation was $DAYS_SINCE days ago. Rotation not due yet."
    exit 0
  fi
  
  echo "=== CREDENTIAL ROTATION RUNBOOK ==="
  echo "Follow these steps for each platform (see main spec for details):"
  echo "1. Telegram: @BotFather /revoke, /newtoken"
  echo "2. Discord: Developer Portal → Bot → Reset Token"
  echo "3. Signal: signal-cli -u +1XXXXXXXXXX unregister && register"
  echo "4. Slack: Revoke Tokens, reinstall app"
  echo ""
  read -p "Confirm all credentials rotated and updated in openclaw.json: (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - All credentials rotated" >> "$ROTATION_LOG"
    # Restart daemon
    launchctl bootout "gui/$(id -u)/com.openclaw.daemon"
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.openclaw.daemon.plist"
    echo "Daemon restarted with new credentials."
  fi
  ```
  And add a macOS calendar reminder or a weekly cron check. Alternatively, use `launchd` to run a plist on a monthly schedule that alerts the operator.

---

### MINOR

**F9: `logname` command in runbook may fail in non-interactive contexts**
- **Severity:** MINOR
- **Finding:** The permission isolation test suite uses `PRIMARY_USER=$(logname)` to determine the primary user. The `logname` command returns the login name of the invoking user, which works in an interactive terminal. However, if the runbook is executed via a script, `ssh` session, or automation tool, `logname` may return `root` or fail entirely (returning a blank string or "logname: not a tty" error).
- **Why:** The test would then try to verify permissions on `/Users//crumb-vault/` (missing username), failing silently or with a confusing error. A solo operator running the runbook might not catch this.
- **Fix:** Use a more robust approach:
  ```bash
  # Determine the primary user (more reliable)
  if [ -z "$SUDO_USER" ]; then
    PRIMARY_USER=$(whoami)
  else
    PRIMARY_USER="$SUDO_USER"
  fi
  # Fallback if still empty
  if [ -z "$PRIMARY_USER" ]; then
    echo "ERROR: Could not determine primary user. Set PRIMARY_USER manually."
    exit 1
  fi
  ```

---

**F10: Inconsistent guidance on macOS user auto-login vs. launchctl bootstrap**
- **Severity:** MINOR
- **Finding:** The spec recommends using `launchctl bootstrap gui/$(id -u openclaw)` to load the LaunchAgent at boot without interactive login. It then says "or enable auto-login for the openclaw user (less preferred)." However, the runbook doesn't say which approach is actually used during setup. If the operator tries auto-login and the `openclaw` user doesn't have a login shell configured, the bootstrap may not happen as expected.
- **Why:** Ambiguity about which mechanism is in effect creates uncertainty about whether the daemon will actually start at boot.
- **Fix:** Pick one and make it explicit:
  ```bash
  # RECOMMENDED: Use launchctl bootstrap (no auto-login needed)
  OC_UID=$(id -u openclaw)
  launchctl bootstrap gui/$OC_UID ~/Library/LaunchAgents/com.openclaw.daemon.plist
  
  # Verify it's registered
  launchctl list | grep com.openclaw.daemon
  ```
  Document that auto-login is NOT recommended (adds attack surface: if someone gains physical access, they log in as `openclaw` without a password).

---

**F11: Unresolved dependencies between Round 2 wrapper script and existing nvm setup**
- **Severity:** MINOR
- **Finding:** Round 2 introduced the wrapper script (`launch-openclaw.sh`) to decouple Node version from the plist. However, the runbook assumes `nvm` is installed for the `openclaw` user (step 2: "Install Node.js ≥22 for the openclaw user"). If nvm is not installed, the wrapper script will fail at `source $NVM_DIR/nvm.sh`. The runbook doesn't verify that nvm is installed **before** creating the wrapper script.
- **Why:** Silent failure of the wrapper script (not sourcing nvm) leaves the `openclaw` user with no Node.js at all, and the daemon exits immediately.
- **Fix:** Add an nvm installation check for the `openclaw` user:
  ```bash
  # Ensure nvm is installed for the openclaw user
  NVM_DIR="/Users/openclaw/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    echo "Installing nvm for the openclaw user..."
    sudo -u openclaw bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'
  fi
  ```

---

**F12: Secrets management upgrade path (Phase 2+) is vague about 1Password CLI**
- **Severity:** MINOR
- **Finding:** The spec suggests 1Password CLI as a future enhancement for loading secrets at runtime: `export TELEGRAM_BOT_TOKEN=$(op read op://openclaw-secrets/telegram/bot-token)`. However, `op` is a proprietary tool that requires a 1Password account, and the spec doesn't address: (1) cost/licensing, (2) whether Keychain is sufficient instead, (3) how to set up the 1Password vault for this pattern, or (4) fallback if 1Password is unavailable. This is positioned as a "Phase 2+" enhancement but is under-specified.
- **Why:** A solo operator reading this might assume 1Password is required or recommended, when a simpler macOS Keychain approach might be adequate for Phase 1.
- **Fix:** Clarify the Secrets Management section:
  ```markdown
  ## Secrets Management
  
  ### Phase 1 (Current): File-based with Unix Permissions
  - Credentials stored in `~/.openclaw/openclaw.json` with `chmod 600` (readable only by openclaw user)
  - Sufficient when combined with dedicated-user isolation
  - Trade-off: credentials visible in plaintext to OpenClaw process
  
  ### Phase 2+ (Future): Runtime Secret Injection
  Evaluate **one** of the following:
  - **macOS Keychain (free, built-in):** Use `security find-generic-password -w` in wrapper script
  - **1Password CLI (paid, external):** Requires 1Password account ($4.99/mo individual)
  - **HashiCorp Vault (self-hosted, complex):** Only if Studio becomes a shared infrastructure
  
  Recommended for Phase 2: macOS Keychain (no additional cost, native to macOS).
  ```

---

**F13: Backup timing and conflict with concurrent OpenClaw writes**
- **Severity:** MINOR
- **Finding:** The spec notes that `vault-backup.sh` tars the entire `~/crumb-vault/` including `_openclaw/`, and "Time Machine" should include `/Users/openclaw/`. However, there's no discussion of backup timing relative to OpenClaw's write operations. If OpenClaw is writing to `_openclaw/` while the backup is reading, the backup could capture a partially-written file or corrupt state.
- **Why:** A restore from a corrupted backup could introduce subtle data loss.
- **Fix:** Add a backup coordination note:
  ```markdown
  ## Backup Timing
  
  - Schedule backups during off-hours when OpenClaw is unlikely to be writing (e.g., 2 AM)
  - Or pause OpenClaw during backup: `sudo -u openclaw launchctl bootout gui/$OC_UID/com.openclaw.daemon` before backup, `bootstrap` after
  - Or use Time Machine's built-in safe-snapshot mechanism (Time Machine automatically pauses active writes)
  ```

---

**F14: `npm audit` vulnerability handling is mentioned but not proceduralized**
- **Severity:** MINOR
- **Finding:** Tier 2 recommendation mentions running `npm audit` after updates and monitoring GitHub security advisories. However, the spec doesn't define what to do **if** `npm audit` reports vulnerabilities that OpenClaw hasn't fixed yet (e.g., a transitive dependency has a 0-day). Should the operator skip the OpenClaw update? Report a bug to the OpenClaw maintainers? This is left as an implicit decision.
- **Why:** A solo operator encountering this situation doesn't know whether it's safe to proceed.
- **Fix:** Add a decision tree:
  ```markdown
  ## Handling npm Audit Findings
  
  1. Run `npm audit` after each OpenClaw install/update
  2. If vulnerabilities found:
     a. Check severity (critical, high, medium, low)
     b. If **critical or high** and **OpenClaw is the direct package** (not transitive): defer update, file issue on openclaw/openclaw GitHub
     c. If **transitive dependency**: file issue upstream, use `npm audit --audit-level=critical` to ignore medium/low findings
     d. If **low severity and not exploitable in your use case** (e.g., debug package in test dependencies): documented waivers in `~/.openclaw/npm-audit-waivers.txt`
  3. Keep the SBOM snapshot (`npm ls --all > ~/.openclaw/sbom-$(date +%Y%m%d).txt`) for forensics after an incident
  ```

---

## Summary Table

| ID | Severity | Category | Issue | Impact |
|----|-----------|-----------|---------| --------|
| F1 | CRITICAL | Impl. | LaunchAgent plist path not explicitly stated | Daemon may not start; operator won't know why |
| F2 | CRITICAL | Impl. | Wrapper script not tested before loading plist | Silent daemon failure (appears running, actually dead) |
| F3 | CRITICAL | Impl. | Permission isolation tests are optional, not mandatory | Security model unverified; isolation boundary may be misconfigured |
| F4 | CRITICAL | Impl. | `signal-cli` binary not mentioned in runbook | Signal connectivity fails; dependency unclear |
| F5 | SIGNIFICANT | Security | No detection/response for `workspaceOnly` bypass | Operator doesn't learn of isolation failure until after exfiltration |
| F6 | SIGNIFICANT | Ops | Phase 2 transition (git protocol) has no gate or test procedure | Phase 2 may be activated unsafely OR never activated (vault corruption risk) |
| F7 | SIGNIFICANT | Ops | Remote access threat (T8) disabled indefinitely without Phase 2 criteria | Remote access may be enabled unsafely, or operator enables it out-of-spec |
| F8 | SIGNIFICANT | Ops | Credential rotation is manual, high-touch, no automation/reminder | Rotations may be skipped; credential compromise persists |
| F9 | MINOR | Impl. | `logname` fails in non-interactive contexts | Test suite may fail silently in automated environments |
| F10 | MINOR | Impl. | Ambiguity: bootstrap vs. auto-login for daemon startup | Operator may pick the wrong mechanism; startup may be unreliable |
| F11 | MINOR | Impl. | Wrapper script assumes nvm installed but doesn't verify | Daemon exits immediately if nvm not found for `openclaw` user |
| F12 | MINOR | Impl. | Secrets management Phase 2+ vague; 1Password positioning unclear | Operator may assume 1Password is required; Keychain alternative not explained |
| F13 | MINOR | Ops | Backup timing not coordinated with OpenClaw writes | Backup could capture corrupted state; restore may lose data |
| F14 | MINOR | Ops | `npm audit` handling not proceduralized | Operator unsure whether to proceed if vulnerabilities found |

---

## Strengths

**S1: Security layering is well-reasoned**
- The dedicated-user + workspaceOnly model correctly separates OS-level isolation (strong, enforceable) from application-level restrictions (weaker, but provides defense-in-depth). This is the correct approach for the threat landscape described.

**S2: Threat model is thorough and realistic**
- T1-T11 are well-chosen and grounded in actual OpenClaw CVE history (6 advisories in 3 weeks, CVE-2026-25253, malicious skills, infostealers). The model is not hypothetical.

**S3: Kill-switch runbook is comprehensive**
- Per-platform credential rotation procedures are detailed and actionable. This is the right level of specificity for emergency response.

**S4: Vault isolation architecture is coherent post-Round 2**
- The clarification that OpenClaw has read-only access to vault (via group permissions) but write-only to `_openclaw/` is a good design. The curation layer (dedicated vault skill) is correctly positioned as a curation mechanism, not a security boundary.

**S5: Node.js version management via nvm wrapper is a good Round 2 improvement**
- Decoupling the daemon from the versioned Node.js path means updating Node doesn't require plist edits. This reduces toil and error surface.

---

## Recommendations for Next Steps

1. **Before go-live:** Integrate F3's permission isolation tests as a mandatory checkpoint in the runbook (do not mark as optional).
2. **Before go-live:** Resolve F1 and F2 by explicitly testing the LaunchAgent plist creation and wrapper script loading in the runbook itself.
3. **Before Phase 1 merge:** Establish F6's Phase 1→Phase 2 approval gate and document the concurrent-write testing procedure (don't defer to "later").
4. **Before Phase 2 design:** Define F7's remote access enablement runbook as a separate, gated feature (or remove Tailscale from core spec until Phase 2 is scheduled).
5. **Quality-of-life improvements (F8, F11, F12, F13, F14):** These are not blocking but would improve operational sustainability for a solo operator. Prioritize F8 (rotation automation) and F11 (nvm verification) as they prevent common failure modes.

---

## Overall Assessment

**Internal Consistency:** 8/10
- The two-layer isolation model is internally consistent post-Round 2.
- Vault access architecture is clarified.
- Minor gaps in daemon startup clarity (F1, F2, F10) suggest the runbook wasn't tested end-to-end.

**Implementation Readiness:** 6/10
- Runbook is 70% complete but has 4 critical gaps that would likely cause a solo operator to either fail setup or deploy an unverified isolation boundary.
- Scripting and verification steps are present but not comprehensive enough for a first-time deployment.

**Security Model Coherence:** 7/10
- Architecture is sound (dedicated user + workspaceOnly + vault isolation).
- Execution is undermined by lack of empirical verification (F3) and no detection/response for isolation bypass (F5).
- Threat model is thorough; residual risks are well-articulated.

**Operational Sustainability:** 6/10
- Manual credential rotation and monitoring are high-touch (F8).
- No automation or reminders for rotation schedule.
- Backup and log management are mentioned but not proceduralized.
- Phase 2 transition lacks a gate (F6), risking that it's never completed or completed unsafely.

**Round 2 Issues:** 2 new issues (F10 ambiguity, F11 nvm assumption), 0 regressions from Round 1. The wrapper script improvement (nvm decoupling) is solid; no degradation of prior hardening controls.

---

## Synthesis

### Consensus Findings

**1. nvm is not installed for the `openclaw` user — runbook will fail on first step** (OAI-F2, GEM-F3, PPLX-F11)
All three reviewers identified this. The runbook's Step 2 runs `sudo -u openclaw bash -c 'source ~/.nvm/nvm.sh && nvm install 22'` but never installs nvm for the `openclaw` user first. Homebrew installing nvm for the primary user doesn't create `~/.nvm/nvm.sh` in `/Users/openclaw`. This is a Day 1 blocker — the setup will fail immediately.

**2. LaunchAgent plist path and label are never verified after `openclaw onboard`** (OAI-F5, PPLX-F1)
The kill-switch runbook and restart commands assume `com.openclaw.daemon` as the label and a specific plist path, but these are never confirmed during setup. If `openclaw onboard` generates a different label, every launchctl command in the spec will fail under stress.

**3. Vault content exfiltration is not treated as a first-class threat** (OAI-F13, GEM-F6)
The spec focuses heavily on credential theft (T4) but understates the risk that a compromised skill can exfiltrate the entire vault — private notes, specs, plans, PII. Gemini recommends an explicit risk acceptance warning. GPT-5.2 recommends a new T12 threat entry.

**4. LaunchAgent boot-time reliability is uncertain** (OAI-F1, OAI-F11, PPLX-F10)
GPT-5.2 flagged that `gui/<uid>` domains may not exist at true boot time without a GUI session. The spec categorically rejects LaunchDaemon, but GPT-5.2 argues LaunchDaemon with `UserName` is viable and may be better for always-on requirements. Perplexity noted the bootstrap-vs-auto-login ambiguity.

**5. Wrapper script is not tested before loading into launchd** (PPLX-F2, GEM-F11)
The runbook creates the wrapper script and immediately loads the plist without a dry-run test. If the script fails (nvm not found, permissions wrong), the daemon fails silently — the operator believes it's running when it isn't.

**6. Permission isolation tests should be a mandatory go/no-go gate** (PPLX-F3)
Perplexity flagged this as CRITICAL — the tests exist in the runbook but aren't positioned as a blocking checkpoint. Without empirical verification, the core security claim is unverified. Gemini praised the test suite (F8 STRENGTH) but didn't flag its optional positioning.

### Unique Findings

- **OAI-F4** (Vault permission commands risk breaking workflows — ACLs, setgid, umask): Genuine insight. Recursive `chgrp`/`chmod` may have unintended effects on existing permissions, and new files created by the primary user won't inherit group without `setgid` on directories. Real implementation concern for durability of the permission model.
- **OAI-F7** (Egress allowlist underspecified — real services use many domains/CDNs): Valid. A too-tight allowlist will break connectivity, pushing operators to disable the control entirely. Suggests "learning period" approach.
- **OAI-F8** (No explicit API key separation procedure): Genuine gap. The spec says "separate keys" but has no procedure to create dedicated API keys/projects per provider for OpenClaw, nor verification that keys aren't reused.
- **OAI-F9** (launchd resource limits referenced but no sample values): Valid — aspirational without concrete plist keys/values.
- **PPLX-F4** (signal-cli binary not in runbook): Valid if signal-cli is not bundled with OpenClaw npm package. Needs dependency clarification.
- **PPLX-F5** (No detection/response layer for workspaceOnly bypass): Genuine insight. The two-layer model lacks detection — if `workspaceOnly` is bypassed, the operator doesn't learn until after exfiltration. Proposes file access logging and periodic review.
- **PPLX-F8** (Credential rotation is manual and high-touch): Valid operational concern. Monthly rotations across 4-5 platforms is error-prone without automation or reminders.

### Contradictions

**LaunchAgent vs LaunchDaemon:** GPT-5.2 (F1, F11) argues the spec's categorical rejection of LaunchDaemon is an overgeneralization — `UserName` in a daemon plist provides non-root execution with reliable boot-time start. The spec says "Do not use LaunchDaemon — it runs as root," but that's only true without `UserName`. Perplexity (F10) notes the ambiguity but doesn't resolve it. Resolution requires a tested decision: either (a) keep LaunchAgent + document reliable bootstrap mechanism, or (b) allow LaunchDaemon with `UserName` for always-on requirement.

**Permission test suite positioning:** Perplexity rates making tests mandatory as CRITICAL (F3). Gemini praises the tests as a STRENGTH (F8) without noting they're optional. Both are right — the tests are excellent AND should be a gate.

### Action Items

**Must-fix** (critical or consensus):

- **A1.** Add nvm installation step for the `openclaw` user before Node install. Either: (a) install nvm via `curl -o- ...` for the openclaw user, or (b) use a simpler Node version manager (mise, asdf, or a fixed binary path). The wrapper script depends on nvm being present. (Sources: OAI-F2, GEM-F3, PPLX-F11)
- **A2.** Add plist path/label verification step after `openclaw onboard`. Record the actual label (`launchctl list | grep openclaw`) and standardize it. Update all launchctl commands in the spec to reference the verified label. (Sources: OAI-F5, PPLX-F1)
- **A3.** Add wrapper script pre-test before loading the LaunchAgent plist. Run the script manually, verify the daemon starts, then load the plist. (Sources: PPLX-F2, GEM-F11)
- **A4.** Promote permission isolation tests from optional to a mandatory go/no-go checkpoint. Tests must pass before proceeding to messaging platform setup. Add pass/fail gating logic. (Source: PPLX-F3)
- **A5.** Resolve the LaunchAgent vs LaunchDaemon always-on mechanism. Either: (a) keep LaunchAgent + provide tested `launchctl bootstrap` commands that work at boot without GUI session, or (b) allow LaunchDaemon with `UserName openclaw` and update the "do not use LaunchDaemon" guidance. Document the tested mechanism. (Sources: OAI-F1, OAI-F11, PPLX-F10)

**Should-fix** (significant, not blocking):

- **A6.** Add T12: Vault Content Exfiltration threat entry (MEDIUM). Acknowledge that the relaxed vault read model means a compromised OpenClaw can read all non-credential vault content. Add explicit risk acceptance warning in the Vault Access Model section. (Sources: OAI-F13, GEM-F6)
- **A7.** Add vault permission durability measures: `setgid` on vault directories for group inheritance, `umask` guidance for the primary user, ACL snapshot before applying, and rollback snippet. (Source: OAI-F4)
- **A8.** Add explicit API key separation procedure: create dedicated API keys/projects per provider for OpenClaw, verify no key reuse, add to Tier 1 verification checks. (Source: OAI-F8)
- **A9.** Add workspaceOnly bypass detection: mandatory access logging, periodic log review during credential rotation, optional automated alert. (Source: PPLX-F5)
- **A10.** Provide sample launchd resource limit plist values (CPU, file descriptors) with "start conservative / adjust" guidance. (Source: OAI-F9)
- **A11.** Reframe egress allowlist with a "learning period" approach: 48-72h alert mode to observe required domains, then lock down. Include domain maintenance guidance. (Source: OAI-F7)
- **A12.** Fix stale "spec §9" references — add "source of truth" note clarifying which document governs vault integration. (Source: OAI-F10)
- **A13.** Add signal-cli dependency verification to runbook, or confirm it's bundled with OpenClaw. (Source: PPLX-F4)
- **A14.** Add credential rotation reminder mechanism: calendar reminder, cron-based check, or rotation tracking log. (Source: PPLX-F8)

**Defer** (minor or speculative):

- **A15.** Explore `launchctl enable`/`kickstart` as alternative to `bootout`/`bootstrap`. (Source: GEM-F5)
- **A16.** Clarify Keychain vs 1Password options in secrets management section. (Source: PPLX-F12)
- **A17.** Add backup timing coordination note. (Source: PPLX-F13)
- **A18.** Proceduralize npm audit vulnerability handling with decision tree. (Source: PPLX-F14)
- **A19.** Adjust 48h patch SLA to be severity-conditional (RCE: 48h, others: weekly). (Source: OAI-F17)
- **A20.** Add encrypted backup requirement for Time Machine. (Source: OAI-F14)
- **A21.** Fix system map diagram "Shared Vault (~)" label to "Shared Vault (~/crumb-vault/)". (Source: GEM-F1)

### Considered and Declined

- **OAI-F3** (Tier 1 #4 reads as stronger guarantee than exists): `incorrect` — The text says "reads the vault through a dedicated vault skill" which describes the intended access path. The Vault Access Model section already clarifies this is a curation layer, not a security boundary. The language is factually correct; operator misinterpretation risk is addressed by the architecture section.
- **PPLX-F6** (Phase 2 transition has no gate): `incorrect` — The spec already contains a Phase 2 approval gate: "This protocol must be tested under concurrent write load (100+ writes while Crumb performs git operations) before Phase 2 is activated. Document results in a `git_write_protocol_test.md`." Could be more structured, but the gate exists.
- **PPLX-F7** (Remote access disabled indefinitely without Phase 2 criteria): `constraint` — Tailscale is disabled until Phase 2 by design. The spec includes detailed Tailscale configuration for when it's enabled. Defining Phase 2 activation criteria is covered by the existing Phase 2 gate (see PPLX-F6 above).
- **PPLX-F9** (`logname` may fail in non-interactive contexts): `out-of-scope` — The runbook is designed for interactive terminal use by a solo operator. Non-interactive execution is out of scope for Phase 1.
- **GEM-F2** (Runbook Phase 2 Node guidance contradicts nvm): `incorrect` — "Node version may need to be ≥22" is factual context about the compatibility check, not an instruction to install via Homebrew. The nvm approach follows in a later phase.
- **OAI-F6** (Some commands need FDA): `incorrect` — The Keychains test checks that access IS denied. Testing for denial doesn't require FDA — the expected result is "Permission denied" or "Operation not permitted." Both outcomes confirm isolation.
