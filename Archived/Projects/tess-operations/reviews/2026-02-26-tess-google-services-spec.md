---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-operations/design/tess-google-services-spec.md
artifact_type: specification
artifact_hash: "16012119"
prompt_hash: "473bef68"
base_ref: null
project: tess-operations
domain: software
skill_origin: peer-review
created: 2026-02-26
updated: 2026-02-26
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
    - "Line 61: User file path /Users/openclaw/Library/Application (expected in spec context)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 57912
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-google-services-spec-openai.json
  google:
    http_status: 200
    latency_ms: 60725
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-google-services-spec-google.json
  deepseek:
    http_status: 200
    latency_ms: 38687
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-google-services-spec-deepseek.json
  grok:
    http_status: 200
    latency_ms: 35598
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-google-services-spec-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Tess Google Services Integration Specification

**Artifact:** Projects/tess-operations/design/tess-google-services-spec.md
**Mode:** full
**Reviewed:** 2026-02-26
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, xAI grok-4-1-fast-reasoning
**Review prompt:** Full specification review evaluating correctness, completeness, internal consistency, feasibility, and clarity. Special attention to gogcli CLI accuracy, OAuth credential storage approach, Gmail label/filter design, security model, and cross-user execution model.

---

## OpenAI (gpt-5.2)

## Structured Review — Tess Google Services Integration Spec (Crumb / tess-operations)

### Summary
The spec is strong on governance boundaries, staged rollout, and separation-of-lanes information architecture. The main risks are (a) **unverifiable gogcli feature assertions/flags** (file keyring backend, exact command syntax), (b) **a few internal inconsistencies** around token storage and Drive scope vs. “read all Drive files,” and (c) **operational security gaps** around handling `GOG_KEYRING_PASSWORD` in cron/environment and audit-log retention/deletion authority.

Below are findings classified by severity and formatted as requested.

---

## Findings

- **[F1]**
  - **Severity:** CRITICAL
  - **Finding:** Internal contradiction on token storage: §2.5 states file backend token storage; §7.3 says “OAuth tokens stored in macOS Keychain (same pattern as x-feed-intel API keys)”.
  - **Why:** This affects the cross-user model and determines whether OpenClaw can actually authenticate headlessly. If implementers follow §7.3 they may revert to Keychain and break the headless `openclaw` user design.
  - **Fix:** Make §7.3 consistent with §2.5. Suggested replacement text: “OAuth tokens stored in encrypted file keyring (gogcli file backend) under the `openclaw` user; no macOS Keychain dependency in headless mode.”

- **[F2]**
  - **Severity:** CRITICAL
  - **Finding:** Drive permissions model is inconsistent with requested OAuth scope. §4.1 says “Read all Drive files,” but §2.4 selects `drive.file`, which **does not** grant read access to all files—only files created by the app or explicitly opened/shared with it (depending on Drive semantics and how the app registers itself).
  - **Why:** If Tess is expected to read “all Drive files” for session prep, it will fail silently/partially and erode trust (“it missed the doc”). Also affects feasibility of Drive audit storage if the audit folder wasn’t created under the app context.
  - **Fix:** Choose one:
    1. Adjust governance to match `drive.file`: “Read Drive files in `00_System/Agent/*` and any files explicitly shared with Tess app,” **or**
    2. Plan for `drive.readonly` or full `drive` scope in Phase 4, and explicitly state that “read all Drive files” is not available until scope upgrade.

- **[F3]**
  - **Severity:** CRITICAL
  - **Finding:** Appendix B gogcli command correctness cannot be independently verified here; several commands/flags look plausible but may be wrong for the actual gogcli CLI surface (examples: `gog gmail send`, `gog gmail drafts create --body`, `gog calendar list <calendarId> --from today --days 7`, `gog drive upload --parent <folderId>`, `gog drive ls --query ...`).
  - **Why:** This spec claims commands were verified with 4 corrections, but if even one “reference command” is wrong, implementation will stall and operators will route around governance by using ad‑hoc methods.
  - **Fix:** Add an explicit “Command verification harness” section:
    - Pin gogcli version and commit hash.
    - Include a CI-like script that runs `gog <cmd> --help` checks and a small set of non-destructive commands in a test account.
    - In Appendix B, include the gogcli version the syntax corresponds to (e.g., `gogcli vX.Y.Z`).

- **[F4]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The file-backend + `GOG_KEYRING_PASSWORD` approach is operationally high-risk if the password is placed in cron environment or OpenClaw config, even if “redacted in config get output.”
  - **Why:** Redaction in a config viewer does not prevent leakage via process environment (`ps e`), crash dumps, logs, shell history, or misconfigured job runners. This password unlocks long-lived refresh tokens—high impact if exfiltrated.
  - **Fix:** Prefer an OS-secret mechanism and minimize exposure window:
    - Store `GOG_KEYRING_PASSWORD` in macOS Keychain **for the `openclaw` user** and retrieve it at runtime (e.g., `security find-generic-password ... -w`) just-in-time.
    - Ensure cron wrapper exports it only for the child process and unsets it immediately.
    - Explicitly document “no logging of environment” and harden OpenClaw job runner to scrub env in logs.

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Approval flow is well-defined for sending email, but the spec also allows autonomous Gmail mutations (labeling, archiving) without a “reversibility” guarantee and without an “undo” affordance.
  - **Why:** Mislabeling/archiving can effectively hide mail and cause missed obligations; even if not “harmful” like sending, it’s still a trust-breaker.
  - **Fix:** Add guardrails:
    - Autopilot may **add** labels but should not remove user labels.
    - Avoid “skip inbox”/archive actions unless the message is already in `@Agent/IN` and a daily digest includes what moved.
    - Provide a Telegram command: “restore last N actions” for label/archival operations (implemented as inverse operations where possible).

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Gmail label taxonomy and filter strategy are generally feasible, but there are Gmail constraints not addressed: label count limits, nested label naming behavior, and filter query brittleness (e.g., `unsubscribe` matches legitimate transactional mail; keyword holds cause many false positives).
  - **Why:** Hitting label limits or creating overly broad filters causes operational degradation and “mail went missing” distrust—explicitly called out as a risk.
  - **Fix:** Add constraints + monitoring:
    - State a target cap (e.g., “keep agent labels under 50 total; project labels under 20”).
    - Add a mechanic check: label count + filter count + a weekly report of false-positive filter hits.
    - Prefer Gmail category-based filters (`category:promotions`) if consistent with your inbox usage, instead of keyword-only heuristics.

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Prompt-injection defenses cover “don’t execute instructions in email,” but the system still performs **tool-mediated actions** based on email content (draft creation, scheduling proposals, label changes). There’s no explicit “data/command separation” policy for how email content is quoted/summarized into Telegram approvals or drafts.
  - **Why:** Injection often works by getting the model to *reframe* content into an action proposal that looks legitimate (“please forward this to…”). Approval helps, but summaries can omit critical context or sanitize red flags.
  - **Fix:** Add a hardened content-handling policy:
    - For any approval request: include “Why you’re receiving this” + “Risks detected” + show the exact recipient list + any links/attachments enumerated.
    - In drafts: never include credentials/2FA codes; never include payment instructions unless Danny explicitly asked.
    - Require quoting the original email snippet that triggered the action (verbatim) in the approval message.

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Calendar “accept invites from `@Trust/Internal` contacts (once trust list is established — not at launch)” is underspecified: what constitutes internal for calendar invites (email domain? contact group? prior correspondence?), and how does Tess map an invite organizer to the trust list reliably?
  - **Why:** Calendar invite acceptance is a common abuse vector (phishing, spam invites, calendar poisoning). Ambiguity here can lead to premature automation.
  - **Fix:** Define a strict trust predicate:
    - Accept only if organizer email is in an explicit allowlist file (exact match) and event has no external attendees (or those are also allowlisted).
    - Log all accepted invites to audit + Telegram summary.

- **[F9]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Audit logging retention and deletion: Mechanic “deletes audit docs older than 30 days.” Deletion is itself a high-trust action, and “append-only during the day” isn’t enforceable in Google Docs without additional controls.
  - **Why:** Audit logs are only valuable if they’re tamper-evident. Automated deletion can be seen as cover-up if something goes wrong, even if benign.
  - **Fix:** Improve audit integrity:
    - Write audit logs as plain text files (or JSONL) into Drive **and** local vault `_openclaw/logs/`, with hash chaining per entry/day.
    - Make retention configurable; default 90 days during early rollout.
    - Mechanic should only *archive* (move to `90_Archive/`) instead of delete, unless Danny explicitly approves deletion.

- **[F10]**
  - **Severity:** MINOR
  - **Finding:** Naming consistency: “Dan — Primary” vs “Danny” elsewhere; `00_System/Agent/Audit/` vs `_openclaw/logs/google-audit.log`—good, but clarify canonical paths and ownership.
  - **Why:** Small inconsistencies create operational footguns when writing scripts and policies.
  - **Fix:** Add a short “Canonical Names and IDs” table: calendar IDs, Drive folder IDs, and exact label strings.

- **[F11]**
  - **Severity:** MINOR
  - **Finding:** Rate limits: “Google’s free quota is generous (250 quota units/second for Gmail)” is stated as a universal fact; quotas vary by API method and project and can change.
  - **Why:** Overconfidence here can hide real throttling issues.
  - **Fix:** Replace with: “Quotas are generally sufficient for this workload; confirm actual quotas in Google Cloud Console and handle 429 with exponential backoff.”

- **[F12]**
  - **Severity:** STRENGTH
  - **Finding:** Separation-of-lanes design (read broadly, write narrowly; staging calendars; agent Drive subtree; Telegram-only approvals) is coherent and aligns well with “always-on chief of staff” safety.
  - **Why:** This reduces blast radius while still enabling high value (briefings, triage, drafting, proposals).
  - **Fix:** None—keep.

- **[F13]**
  - **Severity:** STRENGTH
  - **Finding:** Phased rollout with gates is practical and risk-reducing, especially deferring `gmail.send` until the approval loop is proven.
  - **Why:** Avoids immediately granting highest-risk permissions and lets you calibrate classification/drafting quality first.
  - **Fix:** None—keep.

- **[F14]**
  - **Severity:** STRENGTH
  - **Finding:** Gmail state-machine labels (`IN/WIP/OUT/APPROVAL/DONE`) plus trust/risk tags is a workable operational model and maps cleanly to automation + human review.
  - **Why:** Makes the system inspectable and debuggable; reduces “black box” behavior.
  - **Fix:** Consider adding a single “@Agent/ERROR” label for failed operations (nice-to-have).

---

## Unverifiable claims (must be validated)

These are flagged as **SIGNIFICANT** and prefixed exactly as requested.

- **[F15]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** `gogcli` repository URL and tool capabilities as described (“unified CLI… JSON output… multi-account… OAuth stored in macOS Keychain,” etc.) and install command `brew install steipete/tap/gogcli`.
  - **Why:** If the repo, tap, or features differ, the entire integration mechanism changes.
  - **Fix:** Add a “Verified against” line with: gogcli version, brew formula name, and a link to official docs used.

- **[F16]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** gogcli supports credential storage via **file backend** controlled by `GOG_KEYRING_BACKEND=file` and `GOG_KEYRING_PASSWORD`, and supports `--manual` auth in the manner described.
  - **Why:** This is the linchpin of the cross-user/headless authentication model.
  - **Fix:** Include an explicit excerpt from gogcli docs or `gog auth --help` output in an appendix, plus a tested procedure log.

- **[F17]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** OpenClaw version behavior: “env.* keys are redacted in `config get` output since v2026.2.25” and “OpenClaw sandbox mode on for any cron job that touches Google services.”
  - **Why:** Security assumptions depend on these features existing and being correctly configured.
  - **Fix:** Link to OpenClaw release notes or internal changelog; add a config snippet showing sandbox enforcement.

- **[F18]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** Gmail quotas stated (“250 quota units/second for Gmail”) and other API quota numbers in §11.
  - **Why:** Might be wrong or vary by project; can mislead load expectations and backoff settings.
  - **Fix:** Replace with “check quotas in Cloud Console,” or cite an official Google quota page with date accessed.

- **[F19]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** Appendix B “NOT …” corrections (e.g., “NOT `labels set --add-labels`”, “NOT `--to +7d`”) and the correctness of the provided working commands for the referenced gogcli version.
  - **Why:** The spec explicitly emphasizes these corrections; if wrong, implementers will lose time and confidence.
  - **Fix:** Add a small tested transcript section: command + output shape (redacted), and pin the gogcli version.

---

## Direct answers to the “pay particular attention” items

1) **Appendix B command accuracy:** Cannot be confirmed from here; treat as **unverified until pinned to a gogcli version and validated via `--help`/test runs** (see F3/F19).

2) **OAuth file backend with `GOG_KEYRING_PASSWORD`:** Also **unverified** externally here; it’s plausible, but it must be validated against gogcli docs/help output (F16). Operational security around that password still needs tightening (F4).

3) **Gmail labels/filters constraints:** Conceptually feasible; watch label/filter limits and false positives; no obvious Gmail API blocker, but add explicit constraints/monitoring (F6).

4) **Security model gaps:** Strong on “no autonomous send” and staged approvals; needs better treatment of (a) env secret exposure, (b) injection-through-summarization, (c) audit tamper-evidence (F4/F7/F9).

5) **Cross-user execution model:** If the file backend is real and tokens are stored under the `openclaw` user, it should work headlessly. But the spec must resolve the Keychain contradiction and harden secret delivery to cron (F1/F4/F16).

---

---

## Google (gemini-3-pro-preview)

Here is the structured review of the **Tess Google Services Integration** specification.

### 1. Verification of Unverifiable Claims
Per instructions, specific factual claims regarding external software capabilities and repository existence that cannot be verified without live internet access are flagged here.

- **[ID: UNV-1]**
- **[Severity]:** SIGNIFICANT
- **[Claim]:** The existence of `github.com/steipete/gogcli` and its support for `GOG_KEYRING_BACKEND=file`.
- **[Context]:** §2.1 and §2.5 rely entirely on this specific tool having a file-based keyring backend controllable via environment variables to solve the cross-user authentication problem.
- **[Why]:** While `keyring` libraries in Go/Python often support file backends, if this specific CLI tool does not expose that configuration via the specific environment variable cited, the entire cross-user architecture (§2.5) fails. The repository owner (`steipete`) is a real developer (Peter Steinberger), but the specific tool and its flag parity cannot be confirmed.
- **[Recommendation]:** Verify `gogcli --help` explicitly mentions `GOG_KEYRING_BACKEND` support before implementation.

### 2. General Review Findings

#### [ID: F1]
- **[Severity]:** CRITICAL
- **[Finding]:** Contradiction between Drive OAuth Scope and Operational Requirements.
- **[Why]:** 
    - §2.4 selects the `drive.file` scope ("Access only files created by or explicitly shared with the app").
    - §4.1 states Tess can "Read all Drive files."
    - §9 (Operating Routine) implies Tess can read "reference documents" or "bills" in `30_Admin` to prepare for sessions or audit.
    - **The Conflict:** With `drive.file`, Tess will be **blind** to any files in `10_Projects`, `20_Reference`, or `30_Admin` that were not created by Tess herself. Unlike a user who can "Open With" a file to grant access, a headless agent cannot trigger the "Open" grant. This scope selection renders the "Session prep" and "Reference" capabilities impossible for existing files.
- **[Fix]:** 
    1.  Change scope to `drive.readonly` (allows reading *all* files) AND `drive.file` (allows creating/editing *own* files).
    2.  Or, acknowledge that Tess cannot read existing user files until Phase 4 (Upgrade to full `drive` scope). Update §4.1 to reflect this limitation ("Read only agent-created files").

#### [ID: F2]
- **[Severity]:** SIGNIFICANT
- **[Finding]:** Filter Logic Race Condition (`@Risk/High` vs. `@Agent/IN`).
- **[Why]:** 
    - §3.2 defines Filter A (Newsletters -> `@Agent/IN`) and Filter C (Risk Keywords -> `@Risk/High`, "Do NOT auto-route to `@Agent/IN`").
    - Gmail filters operate essentially in parallel. If an email matches *both* criteria (e.g., a newsletter discussing "wire transfer" fraud), it will receive *both* labels: `@Agent/IN` and `@Risk/High`.
    - §4.1 states Tess "Read[s] all email in `@Agent/IN`".
    - **Result:** Tess will ingest high-risk emails if they coincidentally match other inclusion filters, violating the security boundary intended in §3.2.
- **[Fix]:** Update §9 (Operating Routine) and §2.1 (Tooling) to specify the search query used by the agent must be: `label:@Agent/IN -label:@Risk/High`. The exclusion must happen at the *query* level, as Gmail filters cannot reliably prevent other filters from adding labels.

#### [ID: F3]
- **[Severity]:** SIGNIFICANT
- **[Finding]:** Over-engineered Log Rotation.
- **[Why]:** §4.4 and §6 assign the "Mechanic" agent (using `qwen3-coder`) to perform nightly audit log rotation (deleting files >30 days). Using a probabilistic LLM to perform deterministic file maintenance is inefficient, prone to hallucinated errors (deleting wrong files), and costly compared to a standard script.
- **[Fix]:** Replace with a standard cron job executing a shell command: `gog drive ls --query "modifiedTime < '...' and name contains 'audit'" --json | jq ... | xargs ...`. Do not use an LLM for file rotation.

#### [ID: F4]
- **[Severity]:** MINOR
- **[Finding]:** Missing "Move" Command for Calendar Promotion.
- **[Why]:** §3.3 describes a "Daily reconciliation" where staging holds are "Promoted" to Primary. The `gogcli` reference (Appendix B) lists `create` and `update` (for fields), but does not list a `move` command (which changes an event's calendar ID) or a copy command.
- **[Fix]:** Clarify if "Promote" means "Update the calendar ID" (if API/CLI supports it) or "Read Staging Event -> Create Primary Event -> Delete Staging Event." The latter changes the Event ID, which breaks any external links to that meeting invite.

#### [ID: F5]
- **[Severity]:** MINOR
- **[Finding]:** Hardcoded "OpenClaw" Path.
- **[Why]:** §2.5 references `/Users/openclaw/Library/...`. While standard for macOS, hardcoding the user home directory in documentation can lead to setup errors if the username differs (e.g., `_openclaw` service user vs `openclaw` standard user).
- **[Fix]:** Use `$HOME` or `~` references in documentation: `~/.config/gogcli/` or `~/Library/...`.

#### [ID: F6]
- **[Severity]:** STRENGTH
- **[Finding]:** Excellent Phasing of `gmail.send`.
- **[Why]:** The decision to deliberately omit the `gmail.send` scope in §2.4 and only introduce it in Phase 3 (§8) is a strong security-by-design choice. It physically prevents the agent from sending emails during the "tuning" phases (1 & 2), effectively mitigating the highest risk (reputational damage via rogue emails) regardless of LLM behavior.

### 3. Appendix B: Command Reference Review
Reviewing the `gogcli` commands provided:

1.  `gog gmail thread modify <threadId> --add "@Agent/IN"`
    *   **Comment:** The flag `--add` is non-standard for many CLIs (usually `--add-labels`), but the spec explicitly notes `# NOT "labels set --add-labels"`. Assuming the internal verification mentioned in the context is accurate, this is accepted.
2.  `gog calendar list <calendarId> --from today --days 7`
    *   **Comment:** The `--days` flag is a useful abstraction over the standard Google API `timeMax`. If the tool supports it, this is much cleaner than calculating ISO timestamps in shell.
3.  `gog drive mkdir "Agent" --parent <id>`
    *   **Comment:** Correctly identifies that Google Drive does not use path-based hierarchy but parent-ID based hierarchy. This demonstrates good understanding of the underlying API constraints.

### 4. Summary

The specification is well-structured and demonstrates a high degree of "safety-first" thinking, particularly in the `gmail.send` scope phasing and the "human-in-the-loop" approval flow via Telegram.

However, the **CRITICAL** finding regarding **Drive Scopes (F1)** requires immediate attention. The current design (`drive.file`) creates a functional paradox where the agent is expected to read reference material it legally cannot see. The **SIGNIFICANT** finding regarding **Filter Logic (F2)** represents a security hole where high-risk emails could bypass the safety filter if they match a newsletter filter; this must be patched in the retrieval query.

**Recommendation:** Approve with Conditions (Must resolve F1 and F2).

---

## DeepSeek (deepseek-reasoner)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The command `gog gmail thread modify <threadId> --add "@Agent/IN"` is presented as the correct syntax, correcting a presumed error (`labels set --add-labels`). The existence and exact syntax of this `gog gmail thread modify` subcommand, and its correction of a prior mistake, cannot be independently verified without access to the `gogcli` source code or documentation.
- [Why]: Incorrect CLI commands will cause implementation failures. The spec's credibility hinges on the accuracy of these command references.
- [Fix]: Verify the correct `gogcli` syntax for modifying thread labels against the official `gogcli` documentation or by running `gog gmail --help` and `gog gmail thread --help` commands. Update the appendix accordingly.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The `gog calendar list` command syntax `--from today --days 7` is presented as correct, with a note that `--to +7d` is incorrect. The validity of these specific flags and the correction cannot be independently verified.
- [Why]: As with F1, incorrect commands will break implementation. The note suggests this is a correction from a prior review, making accuracy critical.
- [Why]: Verify the correct `gog calendar list` syntax against official documentation or CLI help.
- [Fix]: Verify the correct `gog calendar list` syntax against official documentation or CLI help.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The proposed solution for cross-user credential storage relies on `gogcli` features `GOG_KEYRING_BACKEND=file` and `GOG_KEYRING_PASSWORD`. The existence and behavior of these specific environment variables and the `--manual` auth flow for the `openclaw` user cannot be independently verified.
- [Why]: The entire credential isolation strategy for the headless `openclaw` user depends on this functionality being present and working as described. If these are not real `gogcli` features, the integration model is blocked.
- [Fix]: Confirm the supported keyring backends and authentication flows for `gogcli` by reviewing its official documentation or source code (github.com/steipete/gogcli). If the file backend is not supported, an alternative strategy (e.g., a dedicated user keychain with cross-ACL tweaks, or a proxy service running in the user's session) must be designed.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: The specification states that the `openclaw` user's cron jobs will pass `GOG_KEYRING_PASSWORD` via an environment variable. Storing a credential passphrase in a plaintext environment variable or in a cron file is a security risk, even if OpenClaw's `config get` redacts it.
- [Why]: Environment variables can be leaked via process listing, core dumps, or in shell history. This weakens the security model outlined in §7.3.
- [Fix]: Amend §2.5 and §7.3. The passphrase should be stored in and read from the `openclaw` user's macOS Keychain (as a generic password) at runtime by the cron script, using a command like `security find-generic-password -a openclaw -s gogcli -w`. This maintains isolation while using the native secure store for the `openclaw` user.

- [F5]
- [Severity]: MINOR
- [Finding]: Internal inconsistency in audit log retention policy. §6 states retention is "30 days" and criticizes the original 7-day plan as "too aggressive." However, the Failure Modes table (§10) for "Drive audit" lists a fallback to a local log file, stating "Drive audit is nice-to-have, not the only copy." This slightly undermines the importance of the 30-day policy.
- [Why]: While not a critical contradiction, it creates ambiguity about the criticality of the Drive audit log system.
- [Fix]: Clarify the text in §6 or §10. For example, in §10, state that the local fallback log also follows the 30-day retention policy, rotated by the mechanic agent.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: The Gmail filter strategy (§3.2) includes "Filter C — High-risk keyword hold-back" which matches phrases like "wire transfer" and applies the `@Risk/High` label. The spec notes this will cause false positives but deems it acceptable. However, it does **not** specify that this filter should "Skip Inbox." This is a critical omission.
- [Why]: If the filter applies `@Risk/High` but does not skip the inbox, the email still appears in Danny's primary view, potentially leading to manual interaction before Tess's triage, which could be dangerous if it *is* phishing. The filter's purpose is to "hold-back" from agent triage, but the user could still interact with it directly.
- [Fix]: Add "Skip Inbox" to the actions for Filter C. The intended flow is: high-risk keyword email → `@Risk/High` label applied, skips inbox → only appears under that label for manual, deliberate review by Danny.

- [F7]
- [Severity]: MINOR
- [Finding]: The specification mentions using a "plus-address" (`<danny>+agent@gmail.com`) for explicit agent routing (Filter B). While Gmail supports this, not all external senders or mailing lists handle plus-addresses correctly, and some systems may strip them.
- [Why]: This could lead to missed emails intended for Tess if a sender's email system modifies the address. It's a reliable signal only for senders who control their own infrastructure or for Danny's own sends.
- [Fix]: Acknowledge this limitation in a footnote. Position the plus-address as a useful but imperfect signal, and note that primary routing will still rely on content-based filters (A, C, D) and agent-side classification.

- [F8]
- [Severity]: STRENGTH
- [Finding]: The information architecture and governance boundaries are exceptionally well-designed. The principle of "separation of lanes" (read broadly, write narrowly) is consistently applied across Gmail (label taxonomy, `@Agent/*` surface), Calendar (staging vs. primary), and Drive (`00_System/Agent/` sandbox). The clear matrices in §4 defining autonomous actions, approvals, and prohibitions create a robust safety framework.
- [Why]: This thoughtful design minimizes risk by providing Tess with structured workspaces and explicit guardrails, enabling useful assistance without granting uncontrolled access to Danny's primary data surfaces.

- [F9]
- [Severity]: STRENGTH
- [Finding]: The implementation phasing plan (§8) is logical and risk-averse. Starting with read-only integration, adding triage, then approval flows, and finally Drive operations allows for validation and trust-building at each step. The explicit "gates" between phases are a strong project management practice.
- [Why]: This incremental approach mitigates risk, allows for course correction based on real-world use, and aligns with the "proven stable" prerequisite stated in the phase description. It turns a complex integration into a manageable sequence.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: The security model's prompt-injection defense (§7.1) states "Tess never opens links or downloads attachments from email unless Danny explicitly requests it." However, the capability for Tess to "Prep me for the [meeting name] meeting" is described as reading "calendar event + related email threads + vault dossier." Accessing "related email threads" may require parsing links or attachment content mentioned within those threads.
- [Why]: There is a potential conflict between the strict security rule and a desired capability. The rule might be overly broad and hinder functionality.
- [Fix]: Refine the rule. A more nuanced policy could be: "Tess does not autonomously *initiate* network requests to links or download attachments found in emails. She may, however, summarize the *textual content* of emails and attachments (like PDFs) that are already accessible via the Gmail API, as this does not require outbound network calls to untrusted destinations." Clarify the "session prep" capability accordingly.

- [F11]
- [Severity]: MINOR
- [Finding]: The Open Question (#4) regarding trusted sender list management proposes storing the list in a vault note. The mechanic agent would then read it. This adds a dependency between the Google triage system and the vault, and requires the mechanic agent (which uses a free model for health checks) to parse a config file.
- [Why]: This adds complexity. Using a Google Contact group, while mixing concerns, would be directly queryable via the same `gog` toolchain used for all other operations, simplifying the architecture.
- [Fix]: Recommend starting with the Google Contact group approach for simplicity and consistency of access (`gog contacts`). The operational config concern can be mitigated by creating a contact group named something explicit like `z-Trusted-Agent`. This can be revisited if managing contacts via API becomes problematic.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The "Cost Analysis" (§11) estimates costs for Haiku 4.5 model usage but does not provide the basis for the per-call cost or token count estimates (e.g., input/output tokens per triage operation). The total monthly cost of "$2.50-6/month" is presented as a fact but is not independently verifiable.
- [Why]: Cost estimates are critical for project feasibility. Unsubstantiated estimates reduce the spec's utility for decision-making.
- [Fix]: Add a brief methodology footnote. For example: "Estimate based on ~5,000 input tokens + 500 output tokens per daily triage of ~20 emails (Haiku 4.5 @ ~$0.12/1M input, $0.48/1M output), and similar scaling for drafts." This clarifies the assumption.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: CRITICAL
- [Finding]: Appendix B contains inaccurate gogcli command syntax, e.g., "gog gmail thread modify <threadId> --add "@Agent/IN"" is incorrect; actual syntax is "gog gmail modify THREAD_ID --add-labels LABEL1,LABEL2" (no "thread" subcommand). Similarly, "gog calendar list <calendarId> --from today --days 7 --json" is wrong; "gog calendar list" lists calendars, while events use "gog calendar events list CALENDAR_ID --time-min TIME --time-max TIME".
- [Why]: Incorrect commands will cause implementation failures, cron jobs to break, and wasted debugging time during phasing. Undermines the entire spec's feasibility as a blueprint.
- [Fix]: Verify all commands against current gogcli README/docs (github.com/steipete/gogcli). Correct Appendix B with tested examples, e.g., "gog gmail modify THREAD_ID --add-labels @Agent/IN"; "gog calendar events list CALENDAR_ID --time-min $(date -v1d -v0H -v0M -v0S +%Y-%m-%dT%H:%M:%SZ) --time-max $(date -v+8d -v23H -v59M -v59S +%Y-%m-%dT%H:%M:%SZ) --json".

- [F2]
- [Severity]: CRITICAL
- [Finding]: §2.5 cross-user auth flow is infeasible: `gog auth add ... --manual` run as headless `openclaw` user prints URL; Danny (GUI user) must open URL in *his* browser (logged into his Google account), authorize, and paste code back into `openclaw` terminal. No mechanism described for Danny to access `openclaw` stdin/stdout securely without sudo/escalation risks.
- [Why]: Breaks Phase 0 prerequisites; auth can't complete without Danny SSHing/sudoing into service account or shared terminal, introducing security holes (e.g., exposing passphrase).
- [Fix]: Explicitly document flow: Danny runs `sudo -u openclaw gog auth add ... --manual` from his session (preserves openclaw dir), copies URL to his browser, pastes code. Or use temporary screen/tmux session under openclaw. Add to Phase 0 checklist.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: GOG_KEYRING_BACKEND=file and GOG_KEYRING_PASSWORD env vars for file-based credential storage (§2.5, §2.2). No confirmation this is a supported gogcli feature; repo docs emphasize macOS Keychain, with no public mention of file backend or manual password.
- [Why]: If unsupported, credential isolation fails entirely, reverting to per-user Keychain deadlock. Credential solution was "solved with file-backend OAuth" per context, but ungrounded here risks rollout halt.
- [Fix]: Confirm via gogcli issue/PR/search or test locally. If unsupported, fallback: store tokens in OpenClaw-encrypted file, invoke gogcli with --client-secret and manual token curl (hacky). Document test output.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: §7.3 token management assumes "OAuth tokens stored in macOS Keychain" but §2.5 switches to file backend; contradiction on storage location.
- [Why]: Internal inconsistency confuses implementer on which backend to use, risks mixing Keychain/file and auth failures.
- [Fix]: Strike Keychain reference in §7.3; consistently state "encrypted file backend under openclaw home". Update auth health check to validate file backend.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: §2.5 security note stores GOG_KEYRING_PASSWORD in OpenClaw config ("env.* keys redacted") or openclaw Keychain, but openclaw Keychain unlock requires GUI password prompt on headless service account; unaddressed.
- [Why]: Password storage insecure/infeasible; cron env var exposure or Keychain lockout breaks steady-state heartbeats.
- [Fix]: Mandate OpenClaw config only (with redaction verified). Add mechanic startup script to fetch/passphrase securely (e.g., macOS `security` CLI from Danny's Keychain). Test cron env inheritance.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: §4.1 autonomous actions include "Read all email in @Agent/IN (and anything else when context requires it)" — unbounded read scope risks privacy/processing overload without defined limits (e.g., max threads/day).
- [Why]: Violates "minimum scopes" principle (§2.4); broad reads amplify prompt-injection surface (§7.1) and API quota burn without governance.
- [Fix]: Limit to "newer_than:2d is:inbox label:@Agent/IN max:50" in triage cron. Explicitly prohibit reading Primary inbox autonomously.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: §5 approval flow uses Telegram but lacks handling for Danny's absence/offline (e.g., vacations); stale @Agent/APPROVAL items accumulate indefinitely.
- [Why]: Breaks steady-state (§9); unhandled approvals lead to WIP pileup, eroding trust ("mail went missing").
- [Fix]: Add timeout: auto-move @Agent/APPROVAL >48h to @Agent/OUT with Telegram summary batch. Alert on 5+ pending.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: OpenClaw v2026.2.25 redacts env.* keys in "config get" (§2.5); no external verification possible.
- [Why]: Relies on unproven future feature for security; if absent, exposes GOG_KEYRING_PASSWORD in logs.
- [Fix]: Flag for OpenClaw maintainer confirmation. Alternative: use OpenClaw secrets manager if available.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: §3.4 Drive structure assumes root-level "00_System/" etc., but personal Drives start unstructured; no parent ID handling or migration plan for existing files.
- [Why]: Phase 0 mkdir fails if root polluted; "filing into existing folders" (§2.4 upgrade) impossible without full drive scope from day 1.
- [Fix]: Add Phase 0 step: "gog drive ls --json > vault/drive-inventory.md"; create under My Drive root explicitly with folder IDs. Defer filing until scope upgrade.

- [F10]
- [Severity]: MINOR
- [Finding]: §3.2 Filter C (@Risk/High) uses OR keywords but Gmail filters have match limits (~40 terms); expansion risks truncation.
- [Why]: Future-proofing gap; over time, false negatives rise as keywords grow.
- [Fix]: Split into multiple filters or use regex if Gmail supports (limited). Start with 5-10 keywords max.

- [F11]
- [Severity]: MINOR
- [Finding]: §6 audit retention 30 days but mechanic deletes >30 days; unclear if inclusive/exclusive, risks premature deletion.
- [Why]: Audit gap during rotation could lose evidence of actions.
- [Fix]: Specify "older than 30 full days (e.g., delete 2026-01-27 on 2026-03-01)". Test rotation script.

- [F12]
- [Severity]: MINOR
- [Finding]: §10 failure modes table omits Drive quota exhaustion (e.g., audit logs fill 15GB free tier).
- [Why]: Steady-state nightly quota check exists (§9) but no mitigation if hit (e.g., pause writes).
- [Fix]: Add row: "Drive full | Pause mutations, alert Telegram, local log fallback".

- [F13]
- [Severity]: MINOR
- [Finding]: §4.4 agent mapping uses "qwen3-coder:30b" (free) for mechanic, but Haiku 4.5 for voice; inconsistent naming (Haiku vs. real models?).
- [Why]: Clarity issue; assumes OpenClaw model aliases known.
- [Fix]: Use canonical OpenClaw model names or define glossary.

- [F14]
- [Severity]: MINOR
- [Finding]: §12 Q4 trusted senders: recommends vault note, but triage (§4.4) by mechanic (qwen3-coder) — voice/ mechanic handoff undefined.
- [Why]: Operational gap; list read inconsistent across agents.
- [Fix]: Centralize in _openclaw/config/trusted.json, mechanic exports for voice.

- [F15]
- [Severity]: STRENGTH
- [Finding]: Phased rollout (§8) with gates (e.g., 5-day runs) aligns with chief-of-staff §14, starting read-only.
- [Why]: Builds trust incrementally, catches issues early (e.g., auth stability), enhances feasibility.
- [Fix]: N/A

- [F16]
- [Severity]: STRENGTH
- [Finding]: Failure modes table (§10) covers key risks (e.g., phishing, token expiry) with mitigations tied to other sections.
- [Why]: Comprehensive risk assessment improves completeness and implementer confidence.
- [Fix]: N/A

- [F17]
- [Severity]: STRENGTH
- [Finding]: Single Telegram approval channel (§5) reconciles Gmail staging with chief-of-staff model explicitly.
- [Why]: Reduces context-switching, maintains consistency across specs.
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**C1: Drive `drive.file` scope contradicts "Read all Drive files" governance** (OAI-F2, GEM-F1, GRK-F9)
Three reviewers flagged this. `drive.file` only grants access to files created by or explicitly shared with the app. §4.1 claims autonomous "Read all Drive files" — impossible under this scope. Tess would be blind to pre-existing files in `10_Projects/`, `20_Reference/`, `30_Admin/`. Confirmed by reading §2.4 and §4.1. **Genuine CRITICAL issue.**

**C2: §7.3 Keychain reference contradicts §2.5 file backend** (OAI-F1, GRK-F4, DS implicit)
§7.3 says "OAuth tokens stored in macOS Keychain" but §2.5 established the file backend with `GOG_KEYRING_PASSWORD`. Internal contradiction missed in the earlier Crumb review. **Genuine CRITICAL issue — straightforward fix.**

**C3: gogcli CLI commands and file-backend features unverifiable** (OAI-F3/F15/F19, GEM-UNV-1, DS-F1/F2/F3, GRK-F1/F3)
All four reviewers flagged this. Expected — gogcli is a niche tool that external models can't verify. The earlier Crumb review already verified commands against gogcli docs (4 corrections applied). Grok (GRK-F1) confidently proposes alternative command syntax (`gog gmail modify THREAD_ID --add-labels`) but this is itself unverifiable and may be hallucinated. **Already addressed in prior review; add version pin during implementation.**

**C4: GOG_KEYRING_PASSWORD insecure in cron environment** (OAI-F4, DS-F4, GRK-F5)
Three reviewers flagged storing the passphrase as a plain environment variable. Process listing (`ps e`), crash dumps, and shell history can leak it. The suggestion to retrieve from `openclaw` user's Keychain at runtime via `security find-generic-password` is sound and consistent with our documented macOS multi-user patterns. **Genuine SIGNIFICANT issue.**

### Unique Findings

**U1: Gmail filter race condition** (GEM-F2) — **Genuine insight.**
Gmail filters run in parallel. An email matching both Filter A (newsletters → `@Agent/IN`) and Filter C (`@Risk/High`) gets both labels. Tess triages `@Agent/IN` and ingests the high-risk email, bypassing the security boundary. Fix is at the query level: `label:@Agent/IN -label:@Risk/High`.

**U2: Over-engineered audit log rotation** (GEM-F3) — **Genuine insight.**
Using the mechanic agent (qwen3-coder LLM) to delete audit files is over-engineered. A deterministic shell script is more reliable and free. Note for implementation phase.

**U3: Calendar promotion mechanism undefined** (GEM-F4) — **Genuine insight.**
"Promote staging hold to Primary" requires either changing the event's calendar ID (if API supports) or create-new + delete-old. The latter breaks external event links. Defer to implementation — this is Phase 3 detail.

**U4: Prompt injection through summarization** (OAI-F7) — **Genuine insight.**
Email content summarized in Telegram approval requests could sanitize red flags. Approval messages should include a verbatim snippet from the triggering email alongside the summary.

**U5: Approval timeout for Danny's absence** (GRK-F7) — **Genuine insight.**
No mechanism for stale approval requests. During vacations or offline periods, `@Agent/APPROVAL` items accumulate indefinitely. Add 48-hour auto-expire to `@Agent/OUT` with batch summary.

**U6: Auth flow UX for openclaw user** (GRK-F2) — **Genuine insight.**
The spec doesn't explain how Danny physically interacts with the `openclaw` user's terminal to paste the OAuth code. Add explicit procedure: `sudo -u openclaw env HOME=/Users/openclaw gog auth add ... --manual` from Danny's session.

**U7: Calendar invite trust predicate underspecified** (OAI-F8) — **Reasonable.**
"Trusted contacts" for auto-accepting invites needs an exact-match definition against an allowlist file, not a vague category.

**U8: Drive quota exhaustion missing from failure modes** (GRK-F12) — **Reasonable.**
15GB free tier could fill with audit logs over time. Add to failure modes table.

**U9: Risk/High filter and inbox skipping** (DS-F6) — **Debatable.** See Contradictions.

### Contradictions

**D1: Should Risk/High filter skip inbox?**
- DS-F6 says yes — skip inbox to prevent Danny from interacting with phishing emails before triage.
- GEM-F2 says fix at query level — add `-label:@Risk/High` to triage query instead of hiding from inbox.
- **Resolution:** GEM-F2 is correct. Danny *should* see high-risk emails in his inbox for manual review — that's the whole point of the hold-back. Hiding them creates "mail went missing" distrust. The fix is at Tess's query level, not at inbox visibility.

### Action Items

**Must-fix:**
- **A1** (C1 — OAI-F2, GEM-F1, GRK-F9): Amend §4.1 — change "Read all Drive files" to "Read Drive files in `00_System/Agent/*` and any files explicitly shared with Tess app." Add note: full Drive read requires scope upgrade to `drive` at Phase 4.
- **A2** (C2 — OAI-F1, GRK-F4): Fix §7.3 — replace "OAuth tokens stored in macOS Keychain" with "OAuth tokens stored in encrypted file keyring (gogcli file backend) under the `openclaw` user."
- **A3** (U1 — GEM-F2): Add `-label:@Risk/High` exclusion to all agent triage queries in §4.1 and §9.

**Should-fix:**
- **A4** (C4 — OAI-F4, DS-F4, GRK-F5): Amend §2.5 security note — recommend storing `GOG_KEYRING_PASSWORD` in `openclaw` user's Keychain, retrieved at runtime via `security find-generic-password -a openclaw -s gogcli-keyring -w`. Cron wrapper fetches just-in-time.
- **A5** (U5 — GRK-F7): Add approval timeout to §5 — `@Agent/APPROVAL` items older than 48 hours auto-move to `@Agent/OUT` with Telegram batch summary.
- **A6** (U6 — GRK-F2): Add explicit auth flow UX to Phase 0 — document `sudo -u openclaw env HOME=/Users/openclaw gog auth add ... --manual` from Danny's terminal.
- **A7** (U4 — OAI-F7): Amend §5 approval format — include verbatim email snippet that triggered the action alongside the summary.
- **A8** (U7 — OAI-F8): Define calendar invite trust predicate — exact email match from allowlist file, event has no non-allowlisted external attendees.
- **A9** (U8 — GRK-F12): Add Drive quota exhaustion to §10 failure modes table.

**Defer:**
- **A10** (U3 — GEM-F4): Calendar promotion mechanism — implementation detail for Phase 3.
- **A11** (U2 — GEM-F3): Audit rotation via shell script instead of LLM — implementation detail.
- **A12** (C3 — all): gogcli version pin in Appendix B — add during implementation when version is confirmed.

### Considered and Declined

- **DS-F6** (Risk/High filter should skip inbox) — `incorrect`. Danny should see these emails for manual review. The security fix is at query level (A3), not inbox visibility.
- **OAI-F5** (Autonomous labeling reversibility) — `overkill`. The state machine (IN→WIP→OUT/DONE) already provides traceability. Daily digest provides visibility. Label-undo adds complexity without proportional benefit at this phase.
- **OAI-F6** (Gmail label count limits/caps) — `overkill`. Agent labels are well under 50. Formal caps and monitoring are premature for the current scope.
- **GRK-F6** (Unbounded email read scope) — `constraint`. Triage needs contextual reads beyond `@Agent/IN`. The governance boundary is on *actions* (writes, sends), not reads. Query limits can be tuned during implementation.
- **GRK-F13** (Model naming inconsistency "Haiku 4.5" vs "real models") — `incorrect`. Haiku 4.5 and qwen3-coder:30b are the canonical model names per the tess-model-architecture project (DONE).
- **GEM-F5** (Hardcoded `/Users/openclaw` path) — `out-of-scope`. This is a spec for a known setup, not a portable script. The path is correct.
- **GEM-F11** (Trusted senders in Google Contact group) — `constraint`. The spec deliberately separates operational config from personal contacts, consistent with Crumb patterns (`_openclaw/config/` for agent config).
- **DS-F7** (Plus-address reliability) — `out-of-scope`. Already acknowledged as one of four routing mechanisms, not the primary one.
- **GEM-F10** (Prompt injection defense vs. session prep capability) — `constraint`. "Don't open links" means don't navigate to URLs, not don't read email body text. The Gmail API returns email content without outbound network calls. The current wording is adequate.
- **OAI-F9** (Audit log tamper-evidence/hash chaining) — `overkill`. Hash-chained audit logs add complexity disproportionate to a single-user personal system. The dual-write (Drive + local vault fallback) provides adequate integrity for this context.
- **DS-F5** (Audit retention inconsistency between §6 and §10) — `minor`. The fallback log clarification is reasonable but not blocking. Can be addressed during implementation.
