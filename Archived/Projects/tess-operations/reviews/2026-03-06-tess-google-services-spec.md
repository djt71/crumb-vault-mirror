---
type: review
review_mode: diff
review_round: 2
prior_review: Projects/tess-operations/reviews/2026-02-26-tess-google-services-spec.md
artifact: Projects/tess-operations/design/tess-google-services-spec.md
artifact_type: specification
artifact_hash: "af9c636b"
prompt_hash: "a793f217"
base_ref: HEAD
project: tess-operations
domain: software
skill_origin: peer-review
created: 2026-03-06
updated: 2026-03-06
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "5 lines contain /Users/ path (expected in spec context)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 58792
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-03-06-tess-google-services-spec-openai.json
  google:
    http_status: 200
    latency_ms: 51260
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-03-06-tess-google-services-spec-google.json
  deepseek:
    http_status: 200
    latency_ms: 168870
    attempts: 2
    raw_json: Projects/tess-operations/reviews/raw/2026-03-06-tess-google-services-spec-deepseek.json
  grok:
    http_status: 200
    latency_ms: 34864
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-03-06-tess-google-services-spec-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Tess Google Services Spec (gogcli to gws migration)

**Artifact:** Projects/tess-operations/design/tess-google-services-spec.md
**Mode:** diff (vs HEAD -- gogcli to gws tooling migration)
**Reviewed:** 2026-03-06
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
**Review prompt:** Diff review focused on: gws CLI accuracy, missed gogcli assumptions, credential export flow, Model Armor framing, helper command docs, unidentified migration risks

---

## OpenAI (gpt-5.2)

- **[F1]**
  - **Severity:** CRITICAL
  - **Finding:** Appendix B “raw API” syntax likely wrong for `gws` for methods that require path parameters (`userId`, `id/messageId`, `calendarId`, etc.). Examples shown omit required positional args and instead put them in `--params` (e.g., `gws gmail users messages modify --params '{"id":"<messageId>"}'`).
  - **Why:** If `gws` mirrors Discovery/REST method signatures, most of these identifiers are **path parameters**, not query parameters. Putting them in `--params` will fail or hit the wrong endpoint. This breaks wrapper scripts and undermines the safety gates (draft vs send) because the “known-good” reference commands won’t run.
  - **Fix:** Update Appendix B to match `gws`’s actual invocation style for path params. Concretely:
    - Run and paste `gws schema gmail.users.messages.modify` / `...send` / `calendar.events.insert` / `drive.files.create` output into the spec and derive the canonical command lines from that.
    - If `gws` expects positional args (common in generated CLIs), document them explicitly, e.g. `gws gmail users messages modify <userId> <id> --json ...` (exact form depends on `gws schema`).

- **[F2]**
  - **Severity:** CRITICAL
  - **Finding:** The spec claims “Output: Structured JSON by default” and also uses `--format json` on helpers. That combination is inconsistent/unclear, and may be wrong for `gws`.
  - **Why:** If default output is not JSON (many CLIs default to human tables), cron/LLM parsing will break silently. Conversely, if JSON is default, `--format json` is redundant and suggests uncertainty.
  - **Fix:** Verify with `gws --help` / `gws gmail +triage --help` what the actual output defaults are and standardize:
    - Either: “Default output is JSON; use `--format text/table` for humans”
    - Or: “Default output is human-readable; use `--format json` (or `--json`) for automation”
    - Then update all example commands to consistently force machine output (recommended).

- **[F3]**
  - **Severity:** CRITICAL
  - **Finding:** The “headless credential export” flow is underspecified and may be incorrect as written: it implies Danny runs `gws auth export` on his machine and writes directly to `/Users/openclaw/...` on the service host.
  - **Why:** In most real deployments those are different machines/users. Even if same machine, writing decrypted creds to another user’s home path is a high-risk step and may not be feasible without `sudo`/ACL changes. If it’s a different host, the spec is missing the secure transfer step entirely.
  - **Fix:** Rewrite §2.5 as an explicit **two-host** (or one-host) procedure with secure transport:
    1. Danny runs `gws auth login` then `gws auth export > credentials.json` on *his* machine.
    2. Transfer to the OpenClaw host using `scp`/`sftp`/Tailscale/USB, then `install -m 600 -o openclaw credentials.json /Users/openclaw/.config/gws/credentials.json`.
    3. Document rotation/revocation steps (delete file on Danny machine after transfer; revoke tokens in Google account if leaked).

- **[F4]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec asserts `gws` stores credentials at `~/.config/gws/credentials.enc` and that `gws auth export` prints “decrypted credentials to stdout”. This may be inaccurate in path/format, and may omit whether export includes refresh token, client secret, or only access token.
  - **Why:** If export output is not a stable, importable credential bundle (or lacks refresh token), headless operation will fail after token expiry. If the on-disk paths differ, ops runbooks and health checks won’t work.
  - **Fix:** Replace hardcoded paths/claims with verified behavior:
    - Add a “Verified on version X.Y.Z” block.
    - Document exact files produced by `gws auth login` and exact env var(s) `gws` honors for overriding credential location (and whether it supports both encrypted and plaintext JSON).

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Environment variable `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` is asserted as the mechanism for headless creds, but may not be the real name (or may not exist).
  - **Why:** One wrong env var name bricks the entire integration and encourages insecure workarounds (running browser auth as `openclaw`, sharing keychains, etc.).
  - **Fix:** Confirm the supported env var(s) in `gws auth export --help` / docs and update. If `gws` uses a config setting or `--credentials <path>` flag instead, document that canonical approach and bake it into wrapper scripts.

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** `gws auth setup` is described as “creates GCP project, enables APIs, creates OAuth credentials automatically”. That’s a strong claim and likely conditional on `gcloud` being installed + logged in + having billing/permissions.
  - **Why:** If `auth setup` can’t actually create projects or OAuth desktop creds (very common restriction), Phase 0 will stall and the spec will mislead operators.
  - **Fix:** Qualify and gate it:
    - “If `gws auth setup` is available on your version and you have permission to create projects/enable APIs…”
    - Provide explicit fallback steps and the required IAM roles/billing prerequisites.

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Helper commands `+triage`, `+send`, `+agenda`, `+insert`, `+upload`, and workflow helpers are presented as if they definitely exist and have those flags (`--max`, `--query`, `--labels`, `--calendar`, `--start/--end`, etc.). High chance of drift or mismatch.
  - **Why:** These helpers are central to the “prefer helpers” guidance; if they don’t exist or flags differ, the whole Appendix B becomes untrustworthy.
  - **Fix:** Add a verification note and a discovery mechanism:
    - “List helpers: `gws gmail --help` (or `gws gmail + --help` if supported)”
    - For each helper in Appendix B, include the exact `--help` synopsis captured from the pinned version.

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec carries a gogcli-era assumption that CLI-level features exist: `--dry-run` and `--page-all` are claimed as general flags.
  - **Why:** If these flags are not global (or not implemented for helper commands), scripts will fail. Pagination especially matters for label/message listings and People API connections.
  - **Fix:** Verify whether flags are global vs per-command. If per-command, document per-command examples and add wrapper-layer pagination as fallback.

- **[F9]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Gmail label modification example uses `addLabelIds:["Label_<@Agent/IN>"]` which reflects gogcli-ish thinking (human label names) and likely isn’t correct for Gmail API (expects label IDs like `Label_123` or system labels).
  - **Why:** Label state machine is core to governance. If Tess can’t reliably apply labels by ID/name, triage and approvals break.
  - **Fix:** Document the correct approach:
    - Resolve label IDs once (`gws gmail users labels list`) and maintain a mapping file in `_openclaw/config/gmail-label-ids.json`.
    - Wrapper scripts accept semantic names (`@Agent/IN`) and translate to IDs.

- **[F10]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Drive upload raw API command `gws drive files create --params '{"uploadType":"multipart"}' --upload ./file.pdf` assumes an `--upload` flag exists and that multipart is automatic.
  - **Why:** Drive uploads are finicky; wrong upload method leads to broken audit log writes and failed attachment archiving.
  - **Fix:** Validate Drive upload mechanics for `gws` and document one canonical method. If helper `gws drive +upload` exists, prefer it and specify how to set parent folder / mimeType / name.

- **[F11]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Calendar helper `+insert` uses `--calendar "<staging-calendar-id>"` while earlier you name calendars by display name (“Agent — Staging”). There’s an implicit assumption helper accepts either name or ID.
  - **Why:** Mis-targeting calendars is a governance risk (writing to Primary by accident) and an operational risk (events go nowhere).
  - **Fix:** Make calendar targeting explicit and safe:
    - Store canonical calendar IDs in `_openclaw/config/google-calendars.json`.
    - Wrapper scripts require an enum (`staging|followups|primary`) and map to IDs; never accept arbitrary free-text calendar identifiers for mutation calls.

- **[F12]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Model Armor integration is asserted: `gws` supports `--sanitize <TEMPLATE>` and requires `cloud-platform` scope.
  - **Why:** If `--sanitize` isn’t real (or requires different configuration), this becomes a false sense of protection or wastes time. Also, requesting `cloud-platform` is a major scope expansion and risk.
  - **Fix:** Confirm actual `gws` sanitization support and requirements. If true, keep as defense-in-depth but:
    - Explicitly call out that enabling Model Armor requires expanding scopes (and thus a Phase-gated approval).
    - Provide a fallback: local content scanning / prompt-injection heuristics if Model Armor isn’t available.

- **[F13]**
  - **Severity:** STRENGTH
  - **Finding:** Model Armor is framed as additive (“second-line defense…does not replace query-level exclusion”), and the `-label:@Risk/High` invariant is emphasized and centralized.
  - **Why:** This is the right security posture: structural exclusion + defense-in-depth rather than trusting a classifier/sanitizer.
  - **Fix:** None—retain this framing. Consider also making the exclusion invariant a unit test in wrapper scripts (“fail closed if missing”).

- **[F14]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The migration removed gogcli’s “manual code” auth flow and assumes browser-based `gws auth login` is workable, but doesn’t address what happens if the OAuth consent screen/app verification blocks consumer Gmail or if “testing mode” constraints bite.
  - **Why:** OAuth for consumer accounts is often the hardest part (scope limits, publishing status, sensitive scope restrictions). This is a key migration risk.
  - **Fix:** Add a dedicated “OAuth gotchas” section:
    - Consent screen in Testing mode, test users list, publishing status.
    - Which scopes are “sensitive/restricted” and may require verification.
    - A procedure for re-consenting when scopes change (Phase 3 adds `gmail.send`).

- **[F15]**
  - **Severity:** SIGNIFICANT
  - **Finding:** “Pre-built agent skills: 89 agent skills… Symlink to OpenClaw” is very specific and assumes a local `skills/` directory layout and compatibility with OpenClaw skill format.
  - **Why:** If this is wrong, Phase 0 will waste time and may introduce ungoverned behaviors if skills perform sends/edits without the spec’s invariants.
  - **Fix:** Reframe as an optional evaluation with explicit safety checks:
    - Verify where skills live after install, how to list them, and their execution semantics.
    - Require a review checklist: does the skill enforce `-label:@Risk/High`? does it ever send? does it mutate Primary calendar?

- **[F16]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Multi-account limitation note (“v0.7.0 removed…”) may be accurate but is version-specific and currently unsupported by citations in-spec; it also conflicts with the suggested “use per-invocation credential files” without confirming `gws` supports per-invocation credential selection.
  - **Why:** If `gws` can’t switch creds cleanly, future Workspace expansion could be blocked.
  - **Fix:** Pin the spec to a tested `gws` version and add: “If multi-account is needed, validate `gws` supports `--credentials-file` (or equivalent) per invocation; otherwise run separate containers/users.”

- **[F17]**
  - **Severity:** MINOR
  - **Finding:** Appendix B says helpers “handle RFC encoding, pagination, and parameter formatting automatically.”
  - **Why:** Overpromising helper behavior can create hidden data-loss bugs (e.g., missing pages) or malformed emails if RFC2822 encoding isn’t actually handled.
  - **Fix:** Tone down to “may handle…” unless verified; or cite the exact behavior from helper `--help` output/tests.

- **[F18]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Migration risks not fully identified: dependency chain changes (npm/global install), supply-chain and update control, and runtime requirements (Node vs single static binary) are not addressed.
  - **Why:** For a headless service user, global npm installs can be brittle (PATH, permissions, node version drift). This is a real operational regression vs Homebrew/cargo binary pinning.
  - **Fix:** Add a “Packaging & pinning” subsection:
    - Prefer pinned standalone binary or Nix flake for reproducibility.
    - If npm is used, document node version pinning and where the binary lands (`/Users/openclaw/.local/bin`), and ensure cron PATH includes it.

- **[F19]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec assumes `gws schema <service>.<resource>.<method>` exists and is “critical,” but doesn’t provide a fallback if schema introspection is incomplete/offline.
  - **Why:** If discovery/schema requires network or breaks for some APIs, developers will be blocked.
  - **Fix:** Add fallback: link to Google REST docs + store a minimal set of “known-good request templates” in the repo for the endpoints you rely on (list, modify labels, drafts create, events insert, files list/upload).

- **[F20]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Credential export introduces a new high-impact secret (plaintext OAuth refresh token JSON) but the spec doesn’t add compensating controls beyond chmod 600.
  - **Why:** If the OpenClaw host is compromised, attacker gets long-lived access to Gmail/Calendar/Drive. This is inherent, but should be explicitly recognized as a major risk introduced by the new flow.
  - **Fix:** Add mitigations:
    - Store creds in an OS keyring on the *service host* if possible, or encrypt-at-rest with host secret (age/sops) and decrypt just-in-time.
    - Monitor token usage / Google security events.
    - Document revocation procedure (Google Account → Security → Third-party access / revoke OAuth client).

Overall: the migration improves clarity and removes gogcli’s keyring-passphrase complexity, but Appendix B and §2.5 contain multiple “looks plausible” `gws` claims that need verification against a pinned `gws` version’s `--help`/`schema` output; otherwise Phase 0 implementation will fail quickly or—worse—fail in subtle ways that undermine governance.

---

## Google (gemini-3-pro-preview)

Based on the review of the "Tess Google Services Integration" specification diff (migrating from `gogcli` to `gws`), here are the findings:

[F1]
[Severity]: CRITICAL
[Finding]: OAuth Scope Mismatch prevents Model Armor usage.
[Why]: Section 7.1 states that Model Armor requires the `cloud-platform` scope to function (`--sanitize` flag). However, Section 2.4 (OAuth Scope Selection) and the command examples in Section 2.2 explicitly limit scopes to `gmail.modify`, `calendar`, and `drive.file`. The `auth login` examples specifically warn against using presets that include `cloud-platform`. As written, the prompt-injection defense described in 7.1 is impossible to implement with the authorized scopes.
[Fix]: Update Section 2.4 to include `https://www.googleapis.com/auth/cloud-platform` as a required scope if Model Armor is to be enabled, or move Model Armor to Phase 4 (Expansion) and acknowledge the scope expansion risk.

[F2]
[Severity]: CRITICAL
[Finding]: Pre-built agent skills likely violate the Query Exclusion Invariant.
[Why]: Section 4.1 establishes a strict invariant: every Gmail query must include `-label:@Risk/High`. Section 2.1 and Section 12 (Open Questions) suggest adopting pre-built `gws` skills (e.g., `gws-gmail`) to save time. It is highly improbable that generic third-party/vendor skills include this specific, bespoke label exclusion. Using pre-built skills without modification would bypass the system's primary security boundary for high-risk content.
[Fix]: Add a requirement in Section 8 (Phase 0) to "Fork and patch pre-built skills to inject the `-label:@Risk/High` exclusion" or explicitly prohibit the use of `gws-gmail` read-skills in favor of custom wrapper scripts that enforce the invariant.

[F3]
[Severity]: SIGNIFICANT
[Finding]: Headless credential export may lack Client Secrets required for token refresh.
[Why]: Section 2.5 describes the headless flow: `gws auth export > credentials.json`. For an OAuth 2.0 "Desktop app" flow, refreshing an Access Token after 1 hour typically requires the `client_id` and `client_secret` to be present alongside the `refresh_token`. If `gws auth export` only exports the user tokens (Access/Refresh), the `openclaw` user (who does not have the original `~/.config/gws/client_secret.json` from step 2.2 Option B) will fail to refresh the token after the first hour.
[Fix]: Verify if `gws auth export` bundles the client secrets. If not, Section 2.5 must include a step to copy `client_secret.json` to the `openclaw` user's config directory in addition to the exported credentials file.

[F4]
[Severity]: SIGNIFICANT
[Finding]: Raw API commands in wrapper scripts require manual Base64URL encoding.
[Why]: Appendix B distinguishes between Helper commands (`+send`) and Raw API commands (`users messages send`). The Helper is documented to handle RFC2822/Base64. The Raw API example shows passing `{"raw": "..."}`. The spec fails to explicitly warn that when falling back to Raw API commands (as suggested for advanced use cases), the *wrapper script* (shell/Lobster) must strictly handle the RFC2822 construction and Base64URL encoding (not standard Base64) itself. Failing to do so will result in API errors or malformed emails.
[Fix]: Add a note in Appendix B or Section 8: "When using raw Gmail API commands (e.g., `messages send`), the wrapper script is responsible for constructing the RFC2822 string and applying Base64URL encoding before creating the JSON payload."

[F5]
[Severity]: MINOR
[Finding]: Implicit runtime dependency on Node.js.
[Why]: Section 2.1 lists the install method as `npm install -g ...`. While the tool is described as Rust-based, this distribution method implies a Node.js wrapper. The `openclaw` user prerequisites (Section 8) do not explicitly list Node.js/npm as a requirement, assuming only the binary is needed. If the environment is strict (nix/minimal), `npm` might not be available.
[Fix]: Update Phase 0 prerequisites to include "Ensure Node.js/npm is installed for openclaw user" or switch to the binary/Cargo install method mentioned as an alternative in 2.1.

[F6]
[Severity]: MINOR
[Finding]: Ambiguity in JSON parameter quoting for Shell scripts.
[Why]: The spec uses inline JSON for parameters, e.g., `--params '{"q":"is:unread"}'`. When wrapper scripts need to inject variables (e.g., searching for a specific sender), constructing valid JSON strings inside shell commands is error-prone due to quoting hell (mixing single quotes, double quotes, and shell variables).
[Fix]: Recommend using `jq` to construct JSON payloads in wrapper scripts and passing them to `gws` (if `gws` accepts stdin or files), or provide a specific quoting strategy guide in the "Implementation Phasing" section.

---

## DeepSeek (deepseek-reasoner)

- **F1**
  - **Severity**: SIGNIFICANT
  - **Finding**: The installation command `npm install -g @googleworkspace/cli` is likely incorrect. The GitHub repository `github.com/googleworkspace/cli` is a Rust project; npm installation would require a separate Node.js package, which may not exist or be the same project.
  - **Why**: If the `gws` CLI is Rust-based, the primary installation methods are likely Cargo, pre-built binaries, or package managers like Homebrew. The npm command could fail or install a different tool.
  - **Fix**: Verify the correct installation method from the project's README. Use `cargo install googleworkspace-cli` or download a binary release. Update the spec accordingly.

- **F2**
  - **Severity**: SIGNIFICANT
  - **Finding**: The command for exporting credentials (`gws auth export`) is described but its exact output format (JSON) and required flags are not specified. The spec also does not indicate if the exported file is a single credential or a profile that includes client secrets.
  - **Why**: The headless flow depends on this command producing a portable credential file. If the command requires additional flags (e.g., `--format json`) or outputs a non-standard format, the flow may break.
  - **Fix**: Verify the exact `gws auth export` syntax and output format by checking the tool's documentation. Update the export step in §2.5 and Phase 0 with the correct command.

- **F3**
  - **Severity**: MINOR
  - **Finding**: The spec states `gws` ships 89 agent skills that can be symlinked to OpenClaw (`ln -s $(pwd)/skills/gws-* ~/.openclaw/skills/`). The path to these skills is ambiguous—they may be installed elsewhere (e.g., in a global npm directory).
  - **Why**: This instruction could fail if the skills are not in the current directory. The evaluation of pre-built skills is a good idea, but the symlink step needs a concrete source path.
  - **Fix**: Specify how to locate the installed skills (e.g., `find $(npm root -g) -name "gws-*" -type d`). Alternatively, remove the symlink step and just note that skills should be evaluated for potential adoption.

- **F4**
  - **Severity**: SIGNIFICANT
  - **Finding**: The Model Armor `--sanitize` flag is framed correctly as additive defense-in-depth, but the spec does not mention that enabling it requires a GCP project with Model Armor configured and the `cloud-platform` scope added to OAuth. This is a non-trivial setup step.
  - **Why**: If the team plans to use Model Armor, they need to account for the additional scope and template configuration. The spec treats it as a simple flag.
  - **Fix**: Add a note in §7.1 or §12 that Model Armor requires GCP project configuration and scope expansion, and should be considered a future enhancement, not a Phase 0 requirement.

- **F5**
  - **Severity**: MINOR
  - **Finding**: Helper commands (`+triage`, `+send`, etc.) are documented in Appendix B, but the spec does not indicate whether these helpers are stable or if they might change pre-1.0. Some helpers (like `+triage`) may not support all needed flags (e.g., `-label:@Risk/High`).
  - **Why**: Relying on helper commands for core functionality (like triage) could break with CLI updates. The spec should recommend verifying helper behavior and having fallbacks to raw API commands.
  - **Fix**: Add a note in Appendix B that helpers are convenient but may be less stable than raw API commands. For critical operations, consider using raw API commands directly.

- **F6**
  - **Severity**: CRITICAL
  - **Finding**: The credential export flow (§2.5) assumes `gws auth export` outputs decrypted credentials to stdout that can be written to a file and used directly via an environment variable. However, the spec does not address whether the exported credentials contain a refresh token and if they are long-lived.
  - **Why**: If the exported credentials are short-lived access tokens (not refresh tokens), the headless operation will break within hours. The flow's soundness depends on the exported data including a refresh token.
  - **Fix**: Verify that `gws auth export` includes a refresh token. If not, the flow is flawed and an alternative (like a service account) may be required. Update the spec with this verification.

- **F7**
  - **Severity**: SIGNIFICANT
  - **Finding**: The spec mentions `gws` is "dynamically generated from Google's Discovery Service at runtime," which reduces API version change risk. However, it does not address the risk of the Discovery Service schema itself changing, which could break command generation.
  - **Why**: While dynamic generation helps, it's not a panacea—the CLI tool's parsing of the Discovery Service could have bugs or change. The failure modes table only mentions API version change risk in passing.
  - **Fix**: In the failure modes table (§10), expand the `gws CLI` row to include Discovery Service schema changes as a potential risk, with the same fallback ladder.

- **F8**
  - **Severity**: MINOR
  - **Finding**: The spec retains a `gogcli`-specific assumption in §7.4: "wrapper scripts must also enforce technically" but the example uses `gws gmail users drafts create` and `gws gmail users messages send`. This is correct for `gws`, but the surrounding text still references "wrapper scripts" without acknowledging they must be rewritten for `gws`.
  - **Why**: The migration requires rewriting all wrapper scripts. The spec should explicitly call out that existing `gogcli` scripts are obsolete and new `gws` scripts must be created.
  - **Fix**: Add a note in §2.1 or §12 that the migration necessitates rewriting all Google service integration scripts, and this effort should be factored into Phase 0.

- **F9**
  - **Severity**: SIGNIFICANT
  - **Finding**: The spec mentions `gws` has a `--dry-run` flag, but does not specify which commands support it. Dry-run may not be available for all operations (e.g., Gmail send may not have a dry-run mode).
  - **Why**: Relying on dry-run for safety testing could lead to false confidence if certain critical operations lack dry-run support.
  - **Fix**: Verify which `gws` commands support `--dry-run` (especially `gmail users messages send`). If dry-run is not available for sends, note that alternative safety measures (like sending to a test alias) are needed.

- **F10**
  - **Severity**: STRENGTH
  - **Finding**: The spec correctly identifies that the `gws` credential export flow is simpler than the previous `gogcli` approach, reducing moving parts from three (file backend, passphrase, Keychain) to one (credential file).
  - **Why**: This simplification reduces setup complexity and potential failure points, a clear improvement.
  - **Fix**: None. This is a positive observation.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]  
  [SIGNIFICANT]: The `gws auth setup` command is claimed to "creates GCP project, enables APIs, creates OAuth credentials automatically" (Option A in §2.2), but requires `gcloud` CLI installed, and no verification or error-handling steps are specified for cases where `gcloud` auth fails or project creation quotas are hit.  
  [Why]: Automating GCP setup introduces hidden failure modes (e.g., billing not enabled, existing project name conflict) that could block Phase 0, especially since it's "recommended" without fallback details beyond manual Option B. Risks stranding implementers mid-setup.  
  [Fix]: Add explicit prerequisites ("gcloud auth login" required) and post-setup verification commands (e.g., `gcloud projects list | grep Tess`). Warn that it requires billing-enabled account.

- [F2]  
  [CRITICAL]: Appendix B claims helper commands like `gws gmail +triage`, `gws calendar +agenda`, `gws drive +upload`, and workflow helpers (`gws workflow +meeting-prep`) exist with exact syntax/flags (e.g., `--max 10 --query '...' --format json`), but §2.1 distinguishes "pre-built agent skills" (symlinked to OpenClaw) from helpers, creating confusion on whether these are CLI natives or skill wrappers. No install path for skills specified beyond vague `ln -s $(pwd)/skills/gws-*`.  
  [Why]: Implementers can't reproduce without confirming if these are real CLI subcommands or require separate OpenClaw integration. If fictional/missing, Phase 0 skill evaluation fails, delaying rollout. Verbosity note admits raw API is more verbose, undermining helper preference.  
  [Fix]: Clarify in §2.1 and Appendix B: list exact skill locations post-install (e.g., `/usr/local/lib/node_modules/@googleworkspace/cli/skills/`) or confirm via `gws --help`. Add Phase 0 checklist item: `[ ] Run `gws gmail +triage --help` confirms helpers exist`.

- [F3]  
  [SIGNIFICANT]: Auth subcommands (`gws auth login`, `export`, `status`, `setup`) syntax is accurate per claims, but `gws auth export > credentials.json` "prints decrypted credentials to stdout" without mentioning sensitivity (e.g., refresh_token exposure) or rotation policy post-export. §2.5 notes `chmod 600` but no automated rotation or detection of stale exports.  
  [Why]: Exported JSON holds live tokens; manual export risks copy-paste leakage or forgetting re-export after expiry. Mechanic only checks `gws auth status` (file-aware?), not file staleness, risking undetected auth failures in cron.  
  [Fix]: Add to §2.5: "Export weekly or on expiry; add cron to check file mtime >7d and alert." Specify `gws auth export` output schema (e.g., {"client_id":...,"refresh_token":...}).

- [F4]  
  [MINOR]: Raw API examples in Appendix B are mostly accurate (match Gmail/Calendar/Drive v1 REST), but Drive `gws drive files list --params '{"q":"name contains '\''audit'\''","pageSize":10}'` uses shell-escaped single quotes without noting it's bash-specific; fails in sh or quoted cron. Calendar lacks `timeZone` in examples, risking UTC misparse for ET timestamps.  
  [Why]: Copy-paste into cron/scripts breaks, especially multi-line `--json`. Implementers waste time debugging shell quoting during Phase 1.  
  [Fix]: Provide heredoc examples: `gws drive files list --params $'{"q":"name contains \"audit\"","pageSize":10}'` or recommend `--params @file.json`.

- [F5]  
  [SIGNIFICANT]: Missed gogcli assumption: original spec used simpler commands like `gog gmail search 'query'`, `gog gmail send --to ... --body ...` (no base64/raw). New spec requires wrapper scripts to handle RFC2822 base64url encoding for `gws gmail users drafts create/send --json '{"message":{"raw":"<base64>"}}'`, but no sample wrappers provided despite "budget wrapper script authoring time."  
  [Why]: Increases Phase 2 effort (triage → draft); pre-built skills may not enforce governance (e.g., no AID-* check). Risks insecure hacks or fallback to unvetted skills.  
  [Fix]: Add §8 Phase 0: `[ ] Author sample wrapper `~/bin/gws-draft-create.sh` with base64 encode + AID validation.` Link OpenClaw cookbook.

- [F6]  
  [CRITICAL]: Credential export flow is sound for headless (Danny exports to openclaw-shared file, env var points to it), but assumes `openclaw` home perms locked (cross-ref openclaw-colocation spec). No handling if Danny's `gws auth login` uses different GCP project/client_id than openclaw expects, or if export fails due to encryption mismatch.  
  [Why]: Mismatched client_secret.json (Danny vs. openclaw) causes silent auth fail in cron; undetected until prod triage breaks. Personal Gmail OAuth is user-bound, risking token invalidation if Danny revokes app access.  
  [Fix]: §2.5 step 1: "Danny copies `~/.config/gws/client_secret.json` to openclaw's dir first." Add verify: `gws auth status` outputs client_id match check.

- [F7]  
  [MINOR]: Model Armor `--sanitize` framed correctly as additive (requires `cloud-platform` scope, second-line after `@Risk/High` exclusion), but §7.1 claims it "scans API responses for prompt injection patterns before passing to agent" without setup steps (create GCP Model Armor template). No Phase 0 integration.  
  [Why]: Unimplemented "defense-in-depth" gives false security assurance; extra scope risks unverified app limits (§2.2).  
  [Fix]: Demote to Open Questions or Phase 4: "Evaluate Model Armor post-Phase 1; requires `gcloud ai model-armor templates create`."

- [F8]  
  [SIGNIFICANT]: Helper docs gap: No mention of output handling (e.g., `+triage` defaults to human-readable? `--format json` only in some examples). Workflow helpers (`+meeting-prep`) undocumented params/outputs; assumes OpenClaw skills handle JSON parsing. No `--sanitize` or `--dry-run` in helpers.  
  [Why]: §2.1 pushes "prefer helpers," but incomplete docs force raw API fallback, negating simplicity. Risks LLM synthesis errors on non-JSON output.  
  [Fix]: Appendix B: Add `--output json` global flag reference; test examples with `| jq .`.

- [F9]  
  [SIGNIFICANT]: Migration risk not identified: gws install via `npm install -g` (unusual for Rust CLI) introduces Node.js dep (v18+?), version pinning issues (npm lockfile per-user?), and potential supply-chain vuln (npm vs. Cargo). No uninstall/upgrade procedure.  
  [Why]: Breaks on Node updates (macOS); conflicts with `--prefix /Users/openclaw/.local`. Homebrew gogcli was simpler. Phase 0 fails if npm not installed.  
  [Fix]: §2.1: Prefer "cargo install googleworkspace-cli" or binary; fallback npm. Add `[ ] npm outdated | grep @googleworkspace/cli; pin via `npm install -g @googleworkspace/cli@0.7.0``.

- [F10]  
  [MINOR]: Missed gogcli assumption: gogcli had `--json`/`--plain` output modes; gws "Structured JSON by default" but Appendix B mixes `--format json` (helpers) with implicit JSON (raw). No global `--output` flag doc'd.  
  [Why]: Script parsing breaks if human-readable sneaks in; cron jobs assume jq-compatible JSON.  
  [Fix]: Confirm/add: "All commands output JSON unless `--format human`."

- [F11]  
  [SIGNIFICANT]: Risks not addressed: gws pre-1.0 + dynamic Discovery Service risks incomplete API coverage (e.g., Gmail labels.modify missing quirks); single-account limits future-proofing (noted but no per-file creds doc). Skills (89 claimed) may not enforce `-label:@Risk/High` invariant (§4.1 mandates in "every query").  
  [Why]: Adopting skills skips custom wrappers, bypassing governance (AID send block, risk exclusion). Breaking changes hit harder without gogcli's stability.  
  [Fix]: §2.1/Phase 0: "Audit skills for invariants; fork if needed." Add fallback: raw curl for critical paths.

- [F12]  
  [MINOR]: §10 Failure Modes updates `gws drive about get --params '{"fields":"storageQuota"}'` but original gogcli `gog drive about --json`; no quota threshold logic in mechanic script. Multi-account removal unaddressed in failures.  
  [Why]: Incomplete migration leaves mechanic unimplemented; quota alert vague.  
  [Fix]: Specify script snippet: `quota=$(gws drive about get ... | jq .storageQuota.limit); if (( quota > 80% )); then ...`

- [F13]  
  [STRENGTH]: Credential flow simplifies from gogcli's 3-part (file-backend + passphrase + Keychain) to 1-part (env-var JSON), correctly noted in §2.5; aligns with headless CI best practices.  
  [Why]: Reduces moving parts, Keychain unlock issues; verified consistent across §2.2/Phase 0/§7.3. Edge: expiry handled via status check.

- [F14]  
  [MINOR]: Open Questions #6/#7 newly added for skills/MCP eval, but no criteria (e.g., "match governance if enforces risk exclusion + AID"). Risks adopting non-governed skills.  
  [Why]: Vague eval leads to insecure shortcut in Phase 0.  
  [Fix]: Define: "Adopt skill if `grep -q "exclude:@Risk/High" skill.sh` and AID param required."

- [F15]
  [STRENGTH]: Raw API syntax accurately mirrors Google REST (e.g., params/json split, base64 raw for send); schema introspection enables scriptable params without docs lookup.
  [Why]: Future-proofs vs. gogcli static commands; verified against Gmail API v1 structure in examples. Edge: pagination `--page-all` reduces script complexity.

---

## Synthesis

### Spike Verification Context

Before this review, a verification spike installed `gws` v0.7.0 and tested all CLI claims. Several reviewer findings below are evaluated against spike results. Findings contradicted by verified behavior are declined with evidence.

### Consensus Findings

**C1. Credential export completeness (refresh token + client secrets)** — OAI-F3, OAI-F4, GEM-F3, DS-F2, DS-F6, GRK-F3, GRK-F6
All 4 reviewers flag this. Does `gws auth export` output a complete credential bundle (refresh_token + client_id + client_secret)? If it only exports an access token, headless operation breaks within 1 hour. Additionally, does the `openclaw` user need a copy of `client_secret.json` alongside the exported credentials? Source code confirms `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` reads standard Google OAuth JSON (`authorized_user` type), but the export output format is unverified. **Highest-priority item — must verify before Phase 0.**

**C2. Pre-built skills violate governance invariants** — OAI-F15, GEM-F2, GRK-F11, GRK-F14
3 reviewers flag that generic `gws` skills won't enforce the `-label:@Risk/High` query exclusion invariant (§4.1) or the AID-* send enforcement gate (§7.4). The spec says "evaluate during Phase 0... skip where they don't match the governance model" but the evaluation criteria are vague. Skills that bypass the query exclusion invariant break the primary security boundary.

**C3. Model Armor requires scope expansion that §2.4 prohibits** — GEM-F1, DS-F4, GRK-F7
3 reviewers identify a real contradiction: §2.4 limits scopes to `gmail.modify`, `calendar`, `drive.file`, while §7.1 says Model Armor requires `cloud-platform` scope. The `--full` flag (which includes `cloud-platform`) is explicitly warned against in §2.2 for testing-mode apps. As written, Model Armor is impossible to enable with the authorized scopes.

**C4. npm distribution introduces Node.js dependency** — OAI-F18, GEM-F5, DS-F1, GRK-F9
All 4 reviewers flag npm as unusual for a Rust CLI. **Spike verification:** `npm install -g @googleworkspace/cli` works correctly and installs a pre-built binary (not a Node.js wrapper). However, the reviewers' concern about npm-as-distribution-for-openclaw-user is valid — Node.js must be available, PATH must include the binary, and version pinning via npm lockfile in a global install context is non-standard.

**C5. Helper output format inconsistency** — OAI-F2, GRK-F8, GRK-F10
`+triage` help confirms "Defaults to table output format." Raw API commands default to JSON. The spec says "Structured JSON by default" (§2.1) which is true for raw API but not helpers. Cron scripts parsing helper output without `--format json` will break.

**C6. Raw API Gmail commands need RFC2822/Base64URL encoding** — GEM-F4, GRK-F5
2 reviewers flag that raw Gmail API commands (`messages send`, `drafts create`) require the caller to construct RFC2822 and apply Base64URL encoding. The `+send` helper handles this automatically. The spec doesn't warn about this for raw API usage. Significant because the send enforcement wrapper (§7.4) uses raw API, not the helper.

**C7. `gws auth setup` prerequisites underspecified** — OAI-F6, GRK-F1
2 reviewers flag that `gws auth setup` requires `gcloud` CLI authenticated with project-creation permissions. Already has Option B fallback, but Option A is labeled "recommended" without noting its prerequisites.

### Unique Findings

**U1. Gmail label IDs vs names** — OAI-F9
Appendix B shows `addLabelIds:["Label_<@Agent/IN>"]` which mixes human-readable names with API IDs. Gmail API requires label IDs (e.g., `Label_123`), not display names. **Genuine insight** — wrapper scripts need a label name-to-ID mapping. This would silently fail in triage.

**U2. Calendar ID vs name targeting** — OAI-F11
Calendar helper uses `--calendar "<staging-calendar-id>"` but the spec names calendars by display name ("Agent -- Staging"). The `+agenda` helper accepts `--calendar <NAME>` (name filter) but `+insert` uses `--calendar <ID>` (calendar ID). **Genuine insight** — wrapper scripts should maintain a calendar ID mapping in config.

**U3. OAuth consent screen / testing mode risks** — OAI-F14
The migration removed gogcli's `--manual` code-based auth flow. Consumer Gmail OAuth in testing mode has: ~25 scope limit, test users list requirement, sensitive scope restrictions. The spec mentions scope filtering but doesn't cover the consent screen setup procedure. **Genuine insight** — worth a note in Phase 0.

**U4. Credential file revocation procedure** — OAI-F20, GRK-F3
Plaintext credential file is a new high-impact secret. The spec notes `chmod 600` but doesn't document: (a) deleting the export from Danny's machine after transfer, (b) revoking tokens if leaked (Google Account > Security > Third-party access), (c) rotation cadence. **Genuine insight** — worth adding to §7.3.

**U5. Discovery Service schema change risk** — DS-F7
Dynamic generation could break if Discovery Service schema changes. **Low-value** — already covered by the fallback ladder in §10.

**U6. Wrapper script rewrite note** — DS-F8
No gogcli wrapper scripts exist yet (Phase 0 hasn't started). **Noise** — there's nothing to rewrite.

### Contradictions

**D1. npm install validity** — DS-F1 vs spike results
DeepSeek claims `npm install -g @googleworkspace/cli` is "likely incorrect" for a Rust project. **Resolved by spike:** the install works. It's a common pattern — Rust binary distributed via npm with platform-specific prebuilds.

**D2. Helper existence** — OAI-F7 vs spike results
OpenAI suggests helpers "may not exist" and flags "high chance of drift or mismatch." **Resolved by spike:** all helpers verified via `--help` with exact flags matching Appendix B.

**D3. --dry-run / --page-all scope** — OAI-F8 vs spike results
OpenAI questions whether flags are global vs per-command. **Resolved by spike:** both flags appear on every service and helper command's `--help` output. They are global.

**D4. Path parameter handling** — OAI-F1 vs spike results
OpenAI claims path params in `--params` will "fail or hit the wrong endpoint." **Partially resolved by spike:** `gws schema gmail.users.messages.modify` shows `id` is `location=path, required=True` and `userId` is `location=path, default=me`. The `--params` flag accepts both path and query params — `gws` routes them based on the schema. The syntax in Appendix B is correct. However, `id` has no default and is required, so `--params '{"id":"<messageId>"}'` must always include it.

### Action Items

**A1 (must-fix).** Verify `gws auth export` output format. Source: C1 (OAI-F3, OAI-F4, GEM-F3, DS-F2, DS-F6, GRK-F3, GRK-F6).
Run `gws auth login` (requires GCP project setup) then `gws auth export` and inspect: does output include `refresh_token`, `client_id`, `client_secret`? Does `openclaw` also need `client_secret.json`? **This blocks Phase 0 confidence.** Cannot fully verify without authentication — add as explicit Phase 0 step: "Verify exported credential format includes refresh_token and client secrets before proceeding."

**A2 (must-fix).** Resolve Model Armor scope conflict. Source: C3 (GEM-F1, DS-F4, GRK-F7).
§2.4 limits scopes; §7.1 requires `cloud-platform` for Model Armor. Resolution: defer Model Armor to Phase 4 (or later), gate on explicit scope expansion approval. Update §7.1 to note this dependency and remove the implication it's available at launch.

**A3 (must-fix).** Add explicit skill evaluation criteria for governance invariants. Source: C2 (OAI-F15, GEM-F2, GRK-F11, GRK-F14).
In §2.1 and Open Question #6, replace "evaluate during Phase 0" with concrete criteria: "Adopt pre-built skill only if it (a) supports injecting custom query filters (for `-label:@Risk/High` invariant), (b) does not perform autonomous sends/mutations, and (c) can be wrapped with AID-* enforcement. Fork and patch if criteria partially met. Reject and use custom wrapper if not."

**A4 (should-fix).** Document helper default output format. Source: C5 (OAI-F2, GRK-F8, GRK-F10).
Helpers default to table; raw API defaults to JSON. Add note to §2.1: "Helper commands default to table output; always use `--format json` in cron scripts and wrapper functions." Update Appendix B examples to consistently include `--format json` on all helper commands.

**A5 (should-fix).** Add RFC2822/Base64URL encoding warning. Source: C6 (GEM-F4, GRK-F5).
Add note to Appendix B raw Gmail section: "Raw Gmail send/draft commands require the caller to construct an RFC2822 message and apply Base64URL encoding (not standard Base64). The `+send` helper handles this automatically — prefer `+send` for simple sends. For raw API, wrapper scripts must handle encoding."

**A6 (should-fix).** Add Gmail label ID mapping requirement. Source: U1 (OAI-F9).
Update §3.1 or Phase 0: after creating labels, run `gws gmail users labels list --format json`, extract label IDs, and store mapping in `_openclaw/config/gmail-label-ids.json`. Wrapper scripts translate semantic names (`@Agent/IN`) to IDs. Fix Appendix B example to show ID-based reference.

**A7 (should-fix).** Add calendar ID mapping requirement. Source: U2 (OAI-F11).
Same pattern as labels: store calendar IDs in `_openclaw/config/google-calendars.json`. Wrapper scripts use enum (`staging|followups|primary`) mapped to IDs. Note that `+agenda --calendar` accepts display names (filter) but `+insert --calendar` requires IDs.

**A8 (should-fix).** Add credential revocation procedure and rotation note. Source: U4 (OAI-F20, GRK-F3).
Add to §7.3: (a) delete exported credential file from Danny's machine after transfer, (b) document revocation path (Google Account > Security > Third-party access), (c) mechanic check for credential file age > 30 days.

**A9 (should-fix).** Qualify `gws auth setup` prerequisites. Source: C7 (OAI-F6, GRK-F1).
Add to §2.2 Option A: "Requires `gcloud` CLI installed and authenticated (`gcloud auth login`) with permissions to create projects and enable APIs."

**A10 (defer).** npm pinning and Cargo alternative. Source: C4 (OAI-F18, GEM-F5, DS-F1, GRK-F9).
npm install works and the openclaw user already has Node.js (for OpenClaw itself). Add version pin note: `npm install -g @googleworkspace/cli@0.7.0`. Cargo alternative already listed in §2.1. Low urgency.

**A11 (defer).** OAuth consent screen walkthrough. Source: U3 (OAI-F14).
Add a brief note about testing mode constraints and consent screen setup to Phase 0 or §2.2. Not blocking — operator will encounter this during setup and can resolve. The scope filtering note already addresses the main gotcha.

### Considered and Declined

| Finding | Justification | Reason |
|---------|--------------|--------|
| OAI-F1 (path params in --params wrong) | Spike verified: `gws` routes path params from `--params` JSON based on schema definition. The syntax works. | `incorrect` |
| OAI-F5 (env var may not exist) | Spike verified: `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` confirmed in `gws --help` output and source code. | `incorrect` |
| OAI-F7 (helpers may not exist) | Spike verified: all helpers confirmed via `--help` with exact flags matching Appendix B. | `incorrect` |
| OAI-F8 (--dry-run/--page-all per-command) | Spike verified: both flags appear on every service and helper command's `--help`. | `incorrect` |
| OAI-F12 (--sanitize may not be real) | Spike verified: `--sanitize <TEMPLATE>` confirmed on all service commands. The scope conflict (A2) is real, but the flag exists. | `incorrect` |
| OAI-F16 (multi-account per-invocation creds) | `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` per invocation effectively enables multi-credential switching. Already noted in spec. | `constraint` |
| OAI-F19 (schema introspection fallback) | Schema works offline (reads cached Discovery docs). Google REST docs are the natural fallback. Adding "known-good templates" is premature. | `overkill` |
| DS-F1 (npm install incorrect for Rust) | Spike verified: `npm install -g @googleworkspace/cli` works. Common pattern for Rust CLI distribution via npm. | `incorrect` |
| DS-F5 (helpers may not support all flags) | Spike verified: all documented flags confirmed. Stability concern addressed by version pinning (§2.1). | `incorrect` |
| DS-F7 (Discovery Service schema change risk) | Already covered by fallback ladder in §10. Adding it separately is redundant. | `out-of-scope` |
| DS-F8 (wrapper script rewrite note) | No gogcli wrapper scripts exist — Phase 0 hasn't started. Nothing to rewrite. | `incorrect` |
| OAI-F17 (helpers "may handle" RFC encoding) | Spike confirmed `+send` help: "Handles RFC 2822 formatting and base64 encoding automatically." Not speculative. | `incorrect` |
| GRK-F12 (quota threshold script logic) | Implementation detail for mechanic wrapper script, not spec-level. Phase 0 handles this. | `out-of-scope` |
