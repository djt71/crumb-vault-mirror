---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: docs/openclaw-colocation-spec.md
artifact_type: spec
artifact_hash: 2ea2bcec
prompt_hash: 6a82a110
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
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 61403
    attempts: 1
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-openai.json
  google:
    http_status: 200
    latency_ms: 37547
    attempts: 1
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-google.json
  perplexity:
    http_status: 200
    latency_ms: 43476
    attempts: 1
    note: "Round 1 refused (injection wrapper false positive). Re-sent with soft wrapper — succeeded."
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-openclaw-colocation-spec-perplexity-r2.json
tags:
  - review
  - peer-review
  - security
  - openclaw
---

# Peer Review: OpenClaw + Crumb Colocation Specification

**Artifact:** `docs/openclaw-colocation-spec.md`
**Mode:** full
**Reviewed:** 2026-02-18
**Reviewers:** OpenAI GPT-5.2, Google Gemini 2.5 Pro, Perplexity Sonar Reasoning Pro
**Review prompt:** Security-focused review of colocation spec. Asked reviewers to evaluate threat model completeness, hardening tier calibration, workspace-only over-reliance, migration runbook practicality, and assumption/unknown classification.

---

## OpenAI GPT-5.2

- [OAI-R1] **STRENGTH**: Clear problem framing and good prioritization of OpenClaw risk drivers (CVE cadence, malicious skill ecosystem, infostealer targeting). The spec correctly sets "security as the primary design driver."

- [OAI-R2] **SIGNIFICANT**: Threat model is missing macOS/daemon-specific vectors: launchd persistence/plist tampering, local privilege escalation chaining, secrets in logs/crash dumps, backup exfiltration path, and toolchain crossover risk (shared shells, PATH poisoning, compromised npm global packages).

- [OAI-R3] **SIGNIFICANT**: Network threat coverage is incomplete: SSRF, DNS rebinding, webhook spoofing, and "loopback is not always local-only" edge cases. Other local processes can connect to 127.0.0.1. Messaging connectors may introduce inbound webhooks.

- [OAI-R4] **CRITICAL**: Workspace-only restrictions are treated as a primary boundary but are application-enforced, not OS-enforced. Over-reliance means a single OpenClaw vulnerability becomes full vault/credential compromise. Recommends reframing as defense-in-depth and adding at least one OS-level boundary (separate macOS user) in the "reasonable hardening" path.

- [OAI-R5] **SIGNIFICANT**: Internal tension between A5 ("share the same vault directory") and the recommendation to keep OpenClaw workspace outside the vault + "read-only vault access." Need a precise access model.

- [OAI-R6] **SIGNIFICANT**: Spec under-specifies how "read-only vault access" is achieved on macOS. TCC is not a general-purpose per-directory sandbox. Without a concrete mechanism, the plan is not actionable.

- [OAI-R7] **SIGNIFICANT**: C1 ("Single-user macOS: No multi-user separation without significant complexity") is overstated. A dedicated standard user is often simpler than containers. Recommends moving dedicated macOS user from Tier 3 to Tier 2.

- [OAI-R8] **SIGNIFICANT**: Hardening tiers not fully calibrated. Some Tier 3 items are "reasonable," some Tier 1 items are vague. Recommends: move dedicated macOS user to Tier 2, keep Docker in Tier 3, add Tier 1 verification steps (`lsof`, config flag checks).

- [OAI-R9] **MINOR**: chmod 700/600 is good but incomplete on macOS (ACLs, inheritance, backup copies can re-expose secrets).

- [OAI-R10] **SIGNIFICANT**: Missing treatment of keychain usage vs plaintext tokens. If infostealers target specific filenames, reducing plaintext secrets reduces impact.

- [OAI-R11] **SIGNIFICANT**: Supply chain risk mitigation is light. "Official npm" is not a strong control. Recommends pinning exact versions, lockfile integrity, SBOM snapshot.

- [OAI-R12] **SIGNIFICANT**: Messaging platform risks omit account takeover paths (SIM swap, session export, bot token leakage blast radius). Biggest realistic impact may be impersonation.

- [OAI-R13] **SIGNIFICANT**: Browser automation correctly disabled in Tier 1 but no re-enable criteria or containment strategy. Recommends enablement checklist.

- [OAI-R14] **SIGNIFICANT**: Node version management conflict (22 vs 18) acknowledged but no concrete approach. Common Day 1 failure mode on macOS.

- [OAI-R15] **MINOR**: Vault backup automatically captures `_openclaw/` which may be undesirable initially (sensitive message content, media). Recommends excluding until Phase 2 or encrypting.

- [OAI-R16] **SIGNIFICANT**: A1 ("will not install untrusted skills") should be treated as policy with enforcement, not assumption. "Vetted" is undefined.

- [OAI-R17] **SIGNIFICANT**: A2 ("prompt security patching") is vague. No operational SLA. Recommends measurable policy.

- [OAI-R18] **MINOR**: Git contention analysis misses broader concurrency (Obsidian/Crumb/OpenClaw all writing same directory). Recommends import protocol.

- [OAI-R19] **SIGNIFICANT**: Remote access section should explicitly state "disabled until Phase 2."

- [OAI-R20] **STRENGTH**: Tier 1 defaults (disable browser, pairing mode, loopback binding) are high-value and well-calibrated.

- [OAI-R21] **SIGNIFICANT**: Day 1 vs phased options implied but not concretely spelled out in actionable steps.

- [OAI-R22] **MINOR**: Unknowns need validation hooks (command, file, link) and decision outcomes.

---

## Google Gemini 2.5 Pro

(Note: Response truncated at MAX_TOKENS — 5 complete findings, 1 partial)

- [GEM-F1] **SIGNIFICANT**: Missing DoS/resource exhaustion threat. Compromised agent could perform resource-intensive operations degrading Crumb availability.

- [GEM-F2] **SIGNIFICANT**: Missing indirect data exfiltration via logs/diagnostics. Prompt injection could embed sensitive file content in error logs, bypassing workspace-only restrictions.

- [GEM-F3] **CRITICAL**: Security architecture over-relies on `workspaceOnly`. This is the single point of failure preventing T4. Its failure would be catastrophic. Recommends elevating residual risk language.

- [GEM-F4] **MINOR**: A1 is framed as an assumption but functions as a critical mandatory security policy. Recommends re-categorizing to "Core Security Policies."

- [GEM-F5] **MINOR**: Node.js version conflict needs a concrete implementation task, not just a research task. Recommends nvm and a new task OC-007.

- [GEM-F6] **MINOR** (partial/truncated): Missing backup-related threat vector — compromised OpenClaw could write malicious content to backup scope.

---

## Perplexity Sonar Reasoning Pro

(Note: Initially refused in round 1 due to injection-resistance wrapper false positive. Re-sent with soft wrapper — succeeded. Response truncated at MAX_TOKENS — 3 CRITICAL + 5 SIGNIFICANT findings, S5 partial.)

- [PPLX-C1] **CRITICAL**: Future-dated spec — dependency verification incomplete. CVE-2026-25253, GPT-5.2, Gemini 2.5 Pro, and OpenClaw versions cannot be verified against Perplexity's training data (April 2024 cutoff). Recommends adding a dated verification section with output from `npm list`, `git log`, etc.

- [PPLX-C2] **CRITICAL**: OpenClaw, Crumb, and ClawHub existence unverified. Core products are not in Perplexity's training data. Recommends providing authoritative source URLs or clarifying if internal/prototype.

- [PPLX-C3] **CRITICAL**: Circular dependency on unvalidated assumptions. P1 (manual vetting) and P2 (stable channel) lack operational definitions. "Manually vetted" has no checklist, no time limit, no recording process. Prompt injection acknowledged as unsolved but no explicit risk acceptance statement. Recommends concrete vetting checklist (reject patterns, time limit, audit trail) and explicit risk acceptance for messaging prompt injection.

- [PPLX-S1] **SIGNIFICANT**: Git conflict handling strategy underexplored. T5 rated LOW but Phase 2 adds `_openclaw/` to git tracking without a file-locking protocol, retry logic, or conflict resolution strategy. Recommends atomic-rename write pattern with lock files, or keeping `_openclaw/` out of git permanently.

- [PPLX-S2] **SIGNIFICANT**: Node.js version management fragility. launchd plist must reference exact nvm binary path, but nvm requires a login shell to source. Spec lacks exact plist configuration and verification step. Recommends providing exact `ProgramArguments` plist XML with hardcoded nvm node path.

- [PPLX-S3] **SIGNIFICANT**: Messaging platform session management underspecified. T11 proposes burner accounts and session rotation but defines no frequency, rotation procedure, mid-rotation message handling, or per-platform kill-switch steps. Recommends per-platform runbook with exact commands (WhatsApp/Baileys QR regeneration, Telegram BotFather token revocation, etc.).

- [PPLX-S4] **SIGNIFICANT**: Vault access permissions model relies on untested OS primitives. Proposed `chmod 750` + group membership + ACLs not tested. Unclear whether write restriction to `_openclaw/` needs explicit ACL commands. Recommends pre-deployment permission verification test suite (`sudo -u openclaw cat ~/.config/crumb/.env` should fail, etc.).

- [PPLX-S5] **SIGNIFICANT** (partial/truncated): `workspaceOnly` bypass scenarios not defined — spec doesn't enumerate what bypass would look like (symlink attack? prompt injection calling shell?). Response truncated before fix recommendation.

---

## Synthesis

### Consensus Findings (updated with Perplexity)

**1. Over-reliance on `workspaceOnly` as primary security boundary** (OAI-R4, GEM-F3, PPLX-S5)
All three reviewers flagged this. The `workspaceOnly` config is application-enforced, unaudited, and represents a single point of failure. Perplexity additionally noted the spec doesn't enumerate specific bypass scenarios (symlink attacks, shell escapes). **Status: APPLIED** — reframed as defense-in-depth with dedicated macOS user as OS-level backstop.

**2. Skill vetting policy needs operational definition** (OAI-R16, GEM-F4, PPLX-C3)
All three reviewers flagged A1 as needing enforcement, not assumption. Perplexity went further: define a concrete checklist (reject patterns, time limit per audit, recorded outcome) and add explicit risk acceptance for residual prompt injection risk. **Status: PARTIALLY APPLIED** — reframed as Core Security Policy P1 with basic definition. Perplexity's vetting checklist and risk acceptance statement are new findings.

**3. Node.js version management needs a concrete plan** (OAI-R14, GEM-F5, PPLX-S2)
All three flagged this. Perplexity added the launchd-specific insight: nvm requires a login shell but launchd doesn't provide one, so the plist must use hardcoded absolute paths to the nvm-managed node binary. **Status: PARTIALLY APPLIED** — nvm plan added but plist specifics not yet addressed.

**4. Missing threat vectors: DoS/resource exhaustion** (GEM-F1) and **log/diagnostic exfiltration** (OAI-R2, GEM-F2)
Two-reviewer consensus. **Status: APPLIED** — added as T9 and T10.

**5. Vault access permissions model untested** (OAI-R6, PPLX-S4)
Two reviewers flagged this. Perplexity provided a concrete verification test suite (`sudo -u openclaw cat ~/.config/crumb/.env` should fail, etc.). **Status: PARTIALLY APPLIED** — access model specified but Perplexity's test suite not yet added.

**6. Messaging session management underspecified** (OAI-R12, PPLX-S3)
Two reviewers flagged messaging platform operational gaps. Perplexity provided per-platform runbook templates (WhatsApp QR regeneration, Telegram BotFather revocation, rotation schedules). **Status: PARTIALLY APPLIED** — T11 added but per-platform runbook not yet written.

### Unique Findings

- **OAI-R3** (Network edge cases: SSRF, webhook spoofing, DNS rebinding): Genuine insight. Worth adding.
- **OAI-R7/R8** (Tier recalibration — dedicated macOS user to Tier 2): Strong recommendation. **Status: APPLIED.**
- **OAI-R10** (Keychain vs plaintext tokens): Valid — worth investigating.
- **OAI-R13** (Browser re-enable checklist): Good forward-planning. **Status: APPLIED.**
- **OAI-R19** (Remote access explicitly disabled in Phase 1): Simple, high-impact. **Status: APPLIED.**
- **PPLX-C3** (Explicit risk acceptance for prompt injection): Genuine insight. The spec acknowledges prompt injection is unsolved but doesn't formally accept the residual risk. A one-line risk acceptance statement would close this gap.
- **PPLX-S1** (Git conflict handling — atomic-rename pattern): Genuine insight. Concrete file-locking protocol (write to `.tmp-*`, atomic rename) is more actionable than the current "lockfile or wait" language.
- **PPLX-S2** (launchd plist needs hardcoded nvm paths): Genuine insight. Practical Day 1 failure mode — launchd doesn't source `.nvm/nvm.sh`.

### Contradictions

None identified. All three reviewers are in strong agreement on the major issues.

### Action Items

**Must-fix** (critical or consensus issues):

- **A1.** ~~Reframe `workspaceOnly` as defense-in-depth.~~ **DONE.** (Sources: OAI-R4, GEM-F3, PPLX-S5)
- **A2.** ~~Move dedicated macOS user to Tier 2.~~ **DONE.** (Sources: OAI-R4, OAI-R7, OAI-R8)
- **A3.** ~~Reframe A1 as Core Security Policy.~~ **DONE.** Perplexity adds: define a vetting checklist with reject patterns, time limit, and audit trail. Add explicit risk acceptance statement for messaging prompt injection. (Sources: OAI-R16, GEM-F4, PPLX-C3)
- **A4.** ~~Add T9, T10, T11.~~ **DONE.** (Sources: GEM-F1, GEM-F2, OAI-R2, OAI-R12)

**Should-fix** (significant, not blocking):

- **A5.** ~~Specify vault access model.~~ **DONE.** Add Perplexity's permission verification test suite to runbook. (Sources: OAI-R5, OAI-R6, PPLX-S4)
- **A6.** ~~Add nvm plan.~~ **DONE.** Add exact launchd plist `ProgramArguments` with hardcoded nvm node path. (Sources: OAI-R14, GEM-F5, PPLX-S2)
- **A7.** ~~Convert patching to measurable policy.~~ **DONE** (P2). (Source: OAI-R17)
- **A8.** ~~Add browser re-enable checklist.~~ **DONE.** (Source: OAI-R13)
- **A9.** ~~Make remote access disabled explicit.~~ **DONE.** (Source: OAI-R19)
- **A10.** ~~Add Tier 1 verification steps.~~ **DONE.** (Sources: OAI-R8, OAI-R9)
- **A11.** ~~Strengthen supply chain mitigation.~~ **DONE.** (Source: OAI-R11)
- **A12.** ~~Add Day 1 vs Phased matrix.~~ **DONE.** (Source: OAI-R21)
- **A17.** Add per-platform messaging kill-switch runbook (WhatsApp QR regen, Telegram token revocation, rotation schedule). (Sources: OAI-R12, PPLX-S3)
- **A18.** Add concrete file-locking protocol for Phase 2 git integration (atomic-rename write pattern). (Source: PPLX-S1)
- **A19.** Add explicit risk acceptance statement for residual prompt injection risk via messaging. (Source: PPLX-C3)

**Defer** (minor or speculative):

- **A13.** Investigate macOS Keychain integration. (Source: OAI-R10)
- **A14.** Add validation hooks to Unknowns. (Source: OAI-R22)
- **A15.** Consider excluding `_openclaw/` from backups until Phase 2. (Source: OAI-R15)
- **A16.** Add network hardening items (SSRF, webhook verification, PF rule). (Source: OAI-R3)

### Considered and Declined

- **PPLX-C1/C2 (unverifiable future-dated content):** `constraint` — Perplexity's training data cutoff (April 2024) predates the spec's context. OpenClaw, Crumb, CVE-2026-25253, GPT-5.2, and Gemini 2.5 Pro are real and verified through direct web research during spec creation. This is a limitation of Perplexity's knowledge, not a spec deficiency. The dependency verification addendum Perplexity recommended is reasonable — already addressed by verification commands in Tier 1.
- **OAI-R2/T9 (launchd persistence/plist tampering):** `constraint` — requires initial compromise. Partially addressed by dedicated-user recommendation.
- **OAI-R2/T10 (local privilege escalation chain):** `overkill` — kernel/system exploits outside spec scope.
- **OAI-R2/T13 (toolchain crossover/PATH poisoning):** `constraint` — mitigated by dedicated-user recommendation (separate PATH, npm globals).
- **OAI-R18 (broader concurrency):** `out-of-scope` — exchange-directory design already addresses this.
