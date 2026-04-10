---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-operations/design/tess-comms-channel-spec.md
artifact_type: spec
artifact_hash: 9b2c96e5
prompt_hash: 28f2a743
base_ref: null
project: tess-operations
domain: software
skill_origin: peer-review
created: 2026-02-26
updated: 2026-02-26
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
    - "User path reference at line 41 (@xfeed_crumb_bot reference)"
    - "localhost reference at line 725 (failure modes table)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 63985
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-comms-channel-spec-openai.json
  google:
    http_status: 200
    latency_ms: 35416
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-comms-channel-spec-google.json
  deepseek:
    http_status: 200
    latency_ms: 43548
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-comms-channel-spec-deepseek.json
  grok:
    http_status: 200
    latency_ms: 25626
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-tess-comms-channel-spec-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Tess Communications Channel Specification

**Artifact:** Projects/tess-operations/design/tess-comms-channel-spec.md
**Mode:** full
**Reviewed:** 2026-02-26
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Full specification review -- correctness, completeness, internal consistency, feasibility, clarity. Special attention to OpenClaw config schemas, cross-context messaging design, multi-agent Discord bot architecture, and security model.

---

## OpenAI (gpt-5.2)

### Overall assessment
The dual-surface architecture (Telegram for real-time + Discord for structured archive) is coherent, operationally motivated, and mostly internally consistent. The main risks are (a) **OpenClaw config-schema drift/assumptions** (multi-account Discord, identity links, retries/reconnect options), (b) **Discord forum/thread semantics + "edit original approval mirror" implementation details**, and (c) **operational security hardening** (2FA, server invite hygiene, intent scopes, least privilege) needing a bit more specificity.

Below are findings by severity.

---

### Findings

- **[F1]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "OpenClaw v2026.2.25 -- Required... Discord channel support, multi-account config, `message send --channel discord` available since v2026.2.17+... CLI commands verified against OpenClaw v2026.2.25."
  - **Why:** The spec's feasibility hinges on exact OpenClaw version capabilities (Discord support, multi-account accounts nesting, thread creation verbs, probing, etc.). If any of these are wrong, Phase 0/1 could stall.
  - **Fix:** Add a short "Schema/CLI conformance table" with: (1) exact `openclaw --version`, (2) a link/commit/hash to the OpenClaw schema reference used, and (3) a Phase 0 validation script that exercises: `channels status --probe`, a Discord send, and forum-thread creation, and then prints the effective merged config keys to confirm they are recognized (not ignored).

- **[F2]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** Proposed `crossContextRoutes` config and "issue #22725".
  - **Why:** S5.3 and S8.4 treat this as an expected near-term capability. If it doesn't exist, the design needs a first-class supported workaround to avoid ad-hoc duct tape.
  - **Fix:** Move `crossContextRoutes` to "future enhancement" language and specify an **explicit supported bridge mechanism** you control now (see F6): e.g., a local "post-to-discord" tool/service with authentication and queueing, with a clear interface contract and failure handling.

- **[F3]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The OpenClaw config blocks appear to mix multiple conceptual schemas (agent bindings, channel accounts, DM policy, exec approvals, retries/reconnect) without a demonstrated authoritative schema reference; several keys may be silently ignored if incorrect.
  - **Why:** Silent-ignore configs are a common failure mode; you may think you have allowlists, DM policies, mention requirements, or retry logic enabled when you don't.
  - **Fix:** For each major config block (S4.2, S6.1, S7.3), add:
    1) a "known-good minimal config" that is confirmed working, and
    2) a "diff" showing optional enhancements.
    Also add a "config lint" step: run whatever OpenClaw provides for schema validation (or add a startup log assertion that enumerates recognized keys). If OpenClaw lacks validation, write a small unit check that loads the config and fails on unknown keys.

- **[F4]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Discord forum/thread behavior is slightly conflated: "forum channels ... each post auto-creates a named thread," and then using `message send` to a forum channel with "title = first line".
  - **Why:** Discord "Forum Channels" are *posts* that behave like threads, but APIs/libraries differ on whether you "send a message" vs "create a forum post" with a title field. If OpenClaw doesn't implement native forum-post creation, sending a plain message may fail or land incorrectly.
  - **Fix:** Specify the exact Discord object you are creating:
    - If OpenClaw supports "forum post create," use an explicit command/endpoint and require a `title` field.
    - If not, switch to **standard text channel + explicit threads** (`message thread create`) for reliability, and keep forum channels as a later optimization.

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Approval mirroring requires message editability and stable message IDs ("edit the Discord `#approvals` message to reflect the decision"), but the spec doesn't define how message IDs are captured/stored or correlated across Telegram approval IDs.
  - **Why:** Without deterministic correlation (approval-id -> discord-message-id), you can't reliably edit the original mirror; you'll end up posting follow-ups, losing the clean audit UX.
  - **Fix:** Define an "Approval Record" schema persisted in a small store (SQLite/JSONL) with fields:
    - `approval_id`, `created_at`, `telegram_message_id`, `discord_channel_id`, `discord_message_id`, `status`, `decided_at`, `decision`.
    Then require the Discord post call to return message ID, and store it.

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The webhook/RPC fallback in S5.3 is plausible but underspecified and introduces security/operational risks (auth, replay, queueing, idempotency).
  - **Why:** A local tool endpoint that can post into Discord is effectively a privileged capability; if not authenticated and rate-limited, it becomes an internal escalation vector.
  - **Fix:** Specify the fallback as a local-only service on loopback with:
    - mTLS or at minimum a shared secret + HMAC signature,
    - idempotency keys (use the approval/output ID),
    - an on-disk queue (so Telegram session can enqueue even when Discord is down),
    - explicit "at least once" delivery semantics and dedupe on Discord side.

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Discord privileged intents guidance may be broader than required ("Server Members Intent recommended"), and "Message Content Intent required" is only true if you need to read message bodies (e.g., `#sandbox`). For purely outbound archival bots, you can avoid privileged intents.
  - **Why:** Minimizing intents reduces risk and compliance surface; Discord is increasingly strict about privileged intents for larger bots, and it's good hygiene even for small private bots.
  - **Fix:** Split bot profiles:
    - **Outbound-only bots** (mechanic posting heartbeats) should not request Message Content or Members intents if not needed.
    - **Interactive bot** (tess-bot in `#sandbox`) may need Message Content; document exactly why and ensure it's enabled only for that bot.

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Security model omits hardening steps for the *human* Discord account (Danny) and server invite surface (2FA requirement, audit of active invites, disabling "Create Invite" perms).
  - **Why:** The server is "private" only insofar as invites and account security remain tight. A compromised user account defeats all bot least-privilege work.
  - **Fix:** Add to S8.1:
    - Require **2FA** on Danny's Discord account.
    - Server setting: **disable/limit invites**, delete all existing invites, restrict "Create Invite" permission.
    - Consider enabling Discord "Require 2FA for moderation actions" (even if bots have no mod perms, it's a good baseline).
    - Document periodic review: members list should contain only Danny + bots.

- **[F9]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec states "No public endpoints, no SSL certificates" as a requirement; the webhook/RPC workaround may violate the spirit unless guaranteed loopback-only.
  - **Why:** A common failure is accidentally binding a local service to `0.0.0.0` or enabling port forwarding, undermining the NAT/no-public-surface posture.
  - **Fix:** Explicitly require the fallback service bind to `127.0.0.1` only, and include a verification command in Phase 0/3 (e.g., `lsof -iTCP -sTCP:LISTEN | grep <port>`).

- **[F10]**
  - **Severity:** MINOR
  - **Finding:** The DM policy / allowlist language is inconsistent across channels: Discord has both guild-channel allowlists and DM allowlists, but also `requireMention` gating. The interaction of these controls isn't fully spelled out.
  - **Why:** Misconfiguration could cause Tess responding unexpectedly in channels or ignoring intended messages.
  - **Fix:** Add a short "Event acceptance matrix" for Discord:
    - In-guild message handling requires: allowed channel AND (if `requireMention`) mention present.
    - DM handling requires: DM enabled AND allowlist match.
    - Outbound posting requires only channel allowlist (if enforced) and bot permissions.

- **[F11]**
  - **Severity:** MINOR
  - **Finding:** Discord rate limiting mitigation is high-level; doesn't specify concrete limits or the queuing strategy in OpenClaw (if any).
  - **Why:** Under bursty outputs (triage + briefing + logs), you may hit rate limits and lose ordering.
  - **Fix:** Define a "Discord Post Queue" policy: max messages/minute, per-channel sequencing, and backoff behavior; or point to OpenClaw's built-in queue if it exists.

- **[F12]**
  - **Severity:** MINOR
  - **Finding:** Message length mismatch is handled, but attachments/files aren't discussed beyond "file exchange requirement."
  - **Why:** Some outputs (exports, PDFs, images) may exceed message chunking and should be attachments.
  - **Fix:** Add a guideline: when to attach files vs paste text; file size limits; naming conventions; and where files should be archived in vault with Discord link.

- **[F13]**
  - **Severity:** MINOR
  - **Finding:** "Telegram messages are not end-to-end encrypted (bot API limitation)" is correct in spirit, but the privacy comparison to Discord could be tightened: Telegram Bot API is server-side; Discord is also server-side; but the threat models differ (metadata, retention, account compromise vectors).
  - **Why:** Security section is otherwise strong; this is mostly phrasing/precision.
  - **Fix:** Adjust S8.3 to explicitly state: both are server-visible; both have different retention/search/disclosure policies; the choice is operational not privacy-improving.

- **[F14]**
  - **Severity:** STRENGTH
  - **Finding:** Clear separation of concerns: Telegram for "type into" and Discord for "browse," with a delivery matrix and phased gates that are measurable.
  - **Why:** This reduces cognitive load and makes the system evolvable without forcing a premature "one channel to rule them all."

- **[F15]**
  - **Severity:** STRENGTH
  - **Finding:** Multi-agent identity via separate Discord bots is a practical, user-visible separation mechanism, and channel allowlists per bot are the right control plane conceptually.
  - **Why:** Prevents cross-talk and makes audit trails legible ("who said what").

- **[F16]**
  - **Severity:** STRENGTH
  - **Finding:** Failure modes section is broad and operationally oriented (connectivity, rate limits, token revocation, chunking, identity linking).
  - **Why:** This is often missing from comms specs; it will save time during rollout.

### Additional UNVERIFIABLE CLAIM flags (SIGNIFICANT)

- **[F17]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "Discord WebSocket gateway instability -- documented zombie connection issues..."
  - **Why:** Could be true, but without a cited incident report or library issue it's hard to gauge likelihood; also impacts whether Discord can be used for approvals.
  - **Fix:** Add references (library/version, issue links) or rephrase to "observed in our deployment" + include observed frequency and mitigation validation.

- **[F18]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "Discord `execApprovals` system ships with built-in `Allow once / Always allow / Deny` button UI."
  - **Why:** This sounds like an OpenClaw feature, not a native Discord concept. If it's not actually implemented, the approvals UX expectations for Discord could be wrong.
  - **Fix:** Clarify: is `execApprovals` an OpenClaw feature? Link to its docs/release note; specify exact config keys and an example interaction.

- **[F19]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "OpenClaw multi-channel identity linking (`identityLinks`) ensures shared session context across Telegram and Discord."
  - **Why:** Cross-channel context sharing is non-trivial; if not real, `#sandbox` expectations and "vice versa" history claims may fail.
  - **Fix:** Add an explicit Phase 0 test procedure and acceptance criteria (send a fact on Telegram, ask on Discord, verify recall; then reverse).

### Targeted focus areas

1. **OpenClaw config JSON correctness (S4.2, S6.1, S7.3):** Cannot confirm schema correctness; several keys are plausible but not verifiable. Practical risk: OpenClaw may ignore unknown keys. Recommendation: treat JSON as aspirational, add schema validation / "print effective config" step (F3), plus minimal-known-good configs.
2. **Cross-context messaging design (S5.3):** Feasible conceptually but depends on platform support. The fallback is realistic if implemented as a local, authenticated, queued tool (F6), not as an ad-hoc webhook without guardrails.
3. **Multi-agent Discord bot architecture (S4.1):** Multiple bots in a private server is generally fine; Discord supports many bots per guild. Watch permissions per channel/thread, rate limits if multiple bots burst, intents minimization (F7). No fundamental Discord API limitation prevents this design.
4. **Security model (S8):** Good baseline: allowlists, least-privilege bot perms, token hygiene. Gaps: human account hardening, invite control, explicit "no public bind" for fallback bridge, and clarifying which intents are truly necessary.

---

## Google (gemini-3-pro-preview)

This is a review of the **Tess Communications Channel Specification**.

### 1. General Assessment
The specification presents a robust, user-centric architecture for splitting high-volume AI outputs between a high-signal notification channel (Telegram) and a structured archival channel (Discord). The rationale is sound, particularly regarding the limitations of single-stream chat for complex operations. The use of Discord Forum channels for daily briefings is a strong UX pattern.

However, the specification relies heavily on specific, future-dated software features ("OpenClaw v2026.2.25", "Issue #22725") and assumes a specific configuration schema for multi-bot instantiation that may not exist. There is also a critical logical gap in the "Approval Mirror" pattern regarding state persistence.

### 2. Findings

#### [F1] CRITICAL | Missing State Persistence for Cross-Channel Edits
**Finding:** In **S5.2 (Approval Mirror)**, the flow requires Tess to "edit the Discord `#approvals` message to reflect the decision" after Danny taps a button on Telegram. There is no mechanism defined to store the correlation between the Telegram interaction (Callback Query ID) and the Discord Message ID.
**Why:** Without storing the Discord Message ID associated with a specific approval request, the agent cannot locate the specific message in `#approvals` to edit it when the Telegram button is pressed later. The audit log will fail to update.
**Fix:** Define a state persistence layer (e.g., a lightweight KV store or the agent's active memory) to map `approval_id` -> `{ telegram_message_id, discord_message_id, discord_channel_id }`.

#### [F2] SIGNIFICANT | UNVERIFIABLE CLAIM: Software Versions and Features
**Finding:** The spec predicates its architecture on **OpenClaw v2026.2.25** and references GitHub issue **#22725** regarding `crossContextRoutes`. It also references **Haiku 4.5** and **qwen3-coder:30b**.
**Why:** These are future-dated or fictional versions that cannot be verified against current documentation. If the actual OpenClaw version available does not support the assumed `crossContextRoutes` or multi-account JSON schema, the architecture fails.
**Fix:** Treat `crossContextRoutes` as non-existent. Elevate the "fallback" webhook solution to the primary implementation plan in S5.3, or define the required plugin development work to enable this feature.

#### [F3] SIGNIFICANT | Unverified Multi-Account Config Schema
**Finding:** **S4.2** defines a configuration block where `channels.discord.accounts` contains multiple named keys (`tess-discord`, `mechanic-discord`). Most bot frameworks (and likely OpenClaw's underlying implementation) typically instantiate a single client per token at the root level.
**Why:** If the OpenClaw runtime does not support iterating through an `accounts` object to spawn multiple independent WebSocket clients, the "Multi-Agent Routing" architecture described in S4.1 is impossible without running multiple Gateway instances.
**Fix:** Validate the configuration schema immediately. If not supported, restructure the architecture to use a single "System Bot" that manages all channels, using overrides for the avatar/username (via Webhooks) to simulate multiple agents, rather than actual separate bot accounts.

#### [F4] SIGNIFICANT | Discord "Zombie" Connection Risk
**Finding:** **S2.3** notes Discord's "WebSocket gateway instability" and **S7.3** prescribes a reconnect strategy. However, the spec does not address the "zombie" state where the socket remains open but stops receiving events (a known Discord Gateway issue).
**Why:** Standard reconnect logic only handles closed connections. A zombie connection results in silent failure where Tess is online but unresponsive to `#sandbox` commands.
**Fix:** In S7.3, mandate an application-level heartbeat (not just WebSocket ping/pong). The Mechanic agent should periodically send a message to a test channel and verify receipt; if it fails, force a Gateway restart.

#### [F5] MINOR | Message Chunking Logic Ambiguity
**Finding:** **S7.5** mentions using `chunkMode: "newline"` to handle Discord's 2000-char limit.
**Why:** "Newline" chunking can still fail if a single paragraph exceeds 2000 characters (e.g., a long email body in a triage thread).
**Fix:** Clarify configuration to `chunkMode: "smart"` or define a fallback hard-split at 1900 chars if no newline is found.

#### [F6] MINOR | Forum Channel Tagging Strategy
**Finding:** **S3.3** mentions optional tags for forum threads but defers decision.
**Why:** Retroactively tagging Discord forum threads is manual and tedious. Defining a basic taxonomy now (e.g., `[Urgent]`, `[Routine]`, `[Report]`) improves immediate browsability.
**Fix:** Define an initial set of 3-4 high-value tags in S3.3.

#### [F7] STRENGTH | Separation of Concerns
**Finding:** The distinction between **Telegram (Interaction)** and **Discord (Archive)** is clearly defined in S2.2 and S2.3.
**Why:** This solves the "infinite scroll" problem effectively while maintaining the low-latency requirements of a personal assistant. The pattern allows the system to be verbose (in Discord) without spamming the user (in Telegram).

#### [F8] STRENGTH | Usage of Discord Forum Channels
**Finding:** Using Forum channels for **Briefings** and **Session Prep** (S3.1).
**Why:** This is an excellent mapping of UI to data structure. It inherently solves the threading/context grouping problem that makes standard chat channels messy for long-form content.

### 3. Summary of Unverifiable Claims
- **OpenClaw v2026.2.25**: Referenced in Context, S1b, S4.2 note.
- **Issue #22725 (`crossContextRoutes`)**: Referenced in S5.3, S8.4, S13.
- **Haiku 4.5**: Referenced in S1b, S4.1, S11.
- **qwen3-coder:30b**: Referenced in S1b, S4.1, S11.
- **OpenClaw feature `execApprovals`**: Referenced in S2.3.

### 4. Recommendation
The specification is **APPROVABLE WITH AMENDMENTS**.
1. **Mandatory:** Address [F1] by defining how the Telegram callback links to the specific Discord message ID for editing.
2. **Mandatory:** Verify the JSON schema in [F3]. If the multi-account object structure is hypothetical, rewrite S4 to use a proven configuration pattern (or Webhooks).
3. **Advisory:** Assume the "fallback" webhook method for cross-context routing is the primary method until the platform capability [F2] is confirmed.

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
- [Fix]: Verify the correct `gog calendar list` syntax against official documentation or CLI help.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The proposed solution for cross-user credential storage relies on `gogcli` features `GOG_KEYRING_BACKEND=file` and `GOG_KEYRING_PASSWORD`. The existence and behavior of these specific environment variables and the `--manual` auth flow for the `openclaw` user cannot be independently verified.
- [Why]: The entire credential isolation strategy for the headless `openclaw` user depends on this functionality being present and working as described. If these are not real `gogcli` features, the integration model is blocked.
- [Fix]: Confirm the supported keyring backends and authentication flows for `gogcli` by reviewing its official documentation or source code (github.com/steipete/gogcli). If the file backend is not supported, an alternative strategy (e.g., a dedicated user keychain with cross-ACL tweaks, or a proxy service running in the user's session) must be designed.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: The specification states that the `openclaw` user's cron jobs will pass `GOG_KEYRING_PASSWORD` via an environment variable. Storing a credential passphrase in a plaintext environment variable or in a cron file is a security risk, even if OpenClaw's `config get` redacts it.
- [Why]: Environment variables can be leaked via process listing, core dumps, or in shell history. This weakens the security model outlined in S7.3.
- [Fix]: Amend S2.5 and S7.3. The passphrase should be stored in and read from the `openclaw` user's macOS Keychain (as a generic password) at runtime by the cron script, using a command like `security find-generic-password -a openclaw -s gogcli -w`. This maintains isolation while using the native secure store for the `openclaw` user.

- [F5]
- [Severity]: MINOR
- [Finding]: Internal inconsistency in audit log retention policy. S6 states retention is "30 days" and criticizes the original 7-day plan as "too aggressive." However, the Failure Modes table (S10) for "Drive audit" lists a fallback to a local log file, stating "Drive audit is nice-to-have, not the only copy." This slightly undermines the importance of the 30-day policy.
- [Why]: While not a critical contradiction, it creates ambiguity about the criticality of the Drive audit log system.
- [Fix]: Clarify the text in S6 or S10. For example, in S10, state that the local fallback log also follows the 30-day retention policy, rotated by the mechanic agent.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: The Gmail filter strategy (S3.2) includes "Filter C -- High-risk keyword hold-back" which matches phrases like "wire transfer" and applies the `@Risk/High` label. The spec notes this will cause false positives but deems it acceptable. However, it does **not** specify that this filter should "Skip Inbox." This is a critical omission.
- [Why]: If the filter applies `@Risk/High` but does not skip the inbox, the email still appears in Danny's primary view, potentially leading to manual interaction before Tess's triage, which could be dangerous if it *is* phishing. The filter's purpose is to "hold-back" from agent triage, but the user could still interact with it directly.
- [Fix]: Add "Skip Inbox" to the actions for Filter C. The intended flow is: high-risk keyword email -> `@Risk/High` label applied, skips inbox -> only appears under that label for manual, deliberate review by Danny.

- [F7]
- [Severity]: MINOR
- [Finding]: The specification mentions using a "plus-address" (`<danny>+agent@gmail.com`) for explicit agent routing (Filter B). While Gmail supports this, not all external senders or mailing lists handle plus-addresses correctly, and some systems may strip them.
- [Why]: This could lead to missed emails intended for Tess if a sender's email system modifies the address. It's a reliable signal only for senders who control their own infrastructure or for Danny's own sends.
- [Fix]: Acknowledge this limitation in a footnote. Position the plus-address as a useful but imperfect signal, and note that primary routing will still rely on content-based filters (A, C, D) and agent-side classification.

- [F8]
- [Severity]: STRENGTH
- [Finding]: The information architecture and governance boundaries are exceptionally well-designed. The principle of "separation of lanes" (read broadly, write narrowly) is consistently applied across Gmail (label taxonomy, `@Agent/*` surface), Calendar (staging vs. primary), and Drive (`00_System/Agent/` sandbox). The clear matrices in S4 defining autonomous actions, approvals, and prohibitions create a robust safety framework.
- [Why]: This thoughtful design minimizes risk by providing Tess with structured workspaces and explicit guardrails, enabling useful assistance without granting uncontrolled access to Danny's primary data surfaces.

- [F9]
- [Severity]: STRENGTH
- [Finding]: The implementation phasing plan (S8) is logical and risk-averse. Starting with read-only integration, adding triage, then approval flows, and finally Drive operations allows for validation and trust-building at each step. The explicit "gates" between phases are a strong project management practice.
- [Why]: This incremental approach mitigates risk, allows for course correction based on real-world use, and aligns with the "proven stable" prerequisite stated in the phase description.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: The security model's prompt-injection defense (S7.1) states "Tess never opens links or downloads attachments from email unless Danny explicitly requests it." However, the capability for Tess to "Prep me for the [meeting name] meeting" is described as reading "calendar event + related email threads + vault dossier." Accessing "related email threads" may require parsing links or attachment content mentioned within those threads.
- [Why]: There is a potential conflict between the strict security rule and a desired capability. The rule might be overly broad and hinder functionality.
- [Fix]: Refine the rule. A more nuanced policy could be: "Tess does not autonomously *initiate* network requests to links or download attachments found in emails. She may, however, summarize the *textual content* of emails and attachments (like PDFs) that are already accessible via the Gmail API, as this does not require outbound network calls to untrusted destinations." Clarify the "session prep" capability accordingly.

- [F11]
- [Severity]: MINOR
- [Finding]: The Open Question (#4) regarding trusted sender list management proposes storing the list in a vault note. The mechanic agent would then read it. This adds a dependency between the Google triage system and the vault, and requires the mechanic agent (which uses a free model for health checks) to parse a config file.
- [Why]: This adds complexity. Using a Google Contact group, while mixing concerns, would be directly queryable via the same `gog` toolchain used for all other operations, simplifying the architecture.
- [Fix]: Recommend starting with the Google Contact group approach for simplicity and consistency of access (`gog contacts`). The operational config concern can be mitigated by creating a contact group named something explicit like `z-Trusted-Agent`. This can be revisited if managing contacts via API becomes problematic.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The "Cost Analysis" (S11) estimates costs for Haiku 4.5 model usage but does not provide the basis for the per-call cost or token count estimates (e.g., input/output tokens per triage operation). The total monthly cost of "$2.50-6/month" is presented as a fact but is not independently verifiable.
- [Why]: Cost estimates are critical for project feasibility. Unsubstantiated estimates reduce the spec's utility for decision-making.
- [Fix]: Add a brief methodology footnote. For example: "Estimate based on ~5,000 input tokens + 500 output tokens per daily triage of ~20 emails (Haiku 4.5 @ ~$0.12/1M input, $0.48/1M output), and similar scaling for drafts." This clarifies the assumption.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
  [Severity]: SIGNIFICANT
  [Finding]: Multiple OpenClaw configuration JSON blocks (S4.2, S6.1, S7.3, etc.) use keys and nesting like `channels.discord.accounts.<name>.guilds.<guild-id>.channels.<channel-id>.requireMention`, `execApprovals.target`, `identityLinks`, `crossContextRoutes`, `dmPolicy: "allowlist"`, and CLI commands like `openclaw message send --channel discord --target channel:<id> --message` or `openclaw message thread create`. These are presented as factual schema matches but cannot be independently verified against OpenClaw documentation or source.
  [Why]: Config errors would break deployment in Phase 0, halting the entire spec. Unverified claims risk propagating invalid setups to sibling specs (e.g., Google/Apple approvals relying on channel routing).
  [Fix]: Prefix all such blocks with "UNVERIFIABLE CLAIM: OpenClaw config schema assumed based on v2026.2.25 docs." Append verification step to Phase 0 gate: "Run `openclaw config validate` (if exists) or manual probe each key via CLI."

- [F2]
  [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: OpenClaw v2026.2.25 required for "Discord channel support, multi-account config, `message send --channel discord`" (S1b), with upgrade from v2026.2.17+. Also, "multi-account pattern (`channels.discord.accounts` with named sub-accounts)" vs. "simpler single-bot pattern" verification note (S4.2). No public docs or changelog cited.
  [Why]: If version lacks multi-account support, Phase 0 fails (as noted), but spec assumes it works post-upgrade without fallback defined beyond "separate config profiles." Blocks mechanic-bot rollout.
  [Fix]: Add to Phase 0: "If multi-account unsupported, deploy single-bot with agentId routing and note in mechanic config." Cite OpenClaw changelog URL or commit hash.

- [F3]
  [Severity]: CRITICAL
  [Finding]: S4.2 Discord config lists specific `<channel-id>`s for tess-discord (e.g., `<morning-briefing-id>`, `<audit-log-id>`), but S3.1 server layout has #audit-log under Approvals & Audit, while matrix S5.5 routes "Audit log entry" to #audit-log (ok), but mechanic-bot config excludes #audit-log entirely. Contradiction: S4.1 table says Tess bound to #audit-log implicitly, but who posts audit logs? Tess or all agents?
  [Why]: Audit logs from multiple agents (e.g., mechanic vault-ops) have no clear routing -- mechanic-bot can't post there per config, Tess might overload. Breaks S2.3 multi-agent separation promise.
  [Fix]: Clarify: Add #audit-log to all agent bots' channel allowlists with `requireMention: false`. Or split to agent-specific audit channels (e.g., #tess-audit). Update table S4.1 and config example.

- [F4]
  [Severity]: SIGNIFICANT
  [Finding]: Cross-context messaging (S5.3) relies on unmerged "crossContextRoutes config (issue #22725)", with webhook/RPC fallback to "Gateway's tool invoke endpoint" or "hook script mirrors". UNVERIFIABLE CLAIM: Issue #22725 existence/proposal; no OpenClaw GitHub link. Webhook assumes Gateway exposes RPC -- unverified.
  [Why]: Primary pattern for session prep/agent-initiated posts fails without native support, forcing brittle fallback. Delays Phase 3; risks data loss if mirror incomplete.
  [Fix]: UNVERIFIABLE CLAIM prefix. Define fallback explicitly: "Shell script: `openclaw message send --channel discord --target <id> --message $(echo $CONTENT | openclaw agent tess --prompt 'format for Discord')` triggered via filesystem event from Telegram session."

- [F5]
  [Severity]: SIGNIFICANT
  [Finding]: Multi-agent Discord bots (S4.1, S7.2): Each bot needs separate Developer Portal app/token, but spec assumes unlimited bots in one private server. Discord has no hard limit for private servers, but OAuth invite per bot risks permission creep if not scoped; S7.2 permissions include "Manage Threads" broadly. No mention of bot overlap risks (e.g., duplicate posts if bindings misfire).
  [Why]: Feasible but incomplete -- adding 3+ bots (Tess, Mechanic, Feed-Intel) increases token management overhead (S8.5), and broad perms violate least-privilege if a bot hacks another channel.
  [Fix]: Add to S7.2: "Use Discord's channel-specific overrides post-invite to revoke perms outside allowlists." Limit to 3 bots max; table S4.1 as cap.

- [F6]
  [Severity]: SIGNIFICANT
  [Finding]: Security model (S8.1-8.2): Private server ok, but bots need "Server Members Intent" (S7.2) which exposes member list (just Danny + bots). No handling for Discord audits/ToS compliance (bots simulating users ok for personal, but "execApprovals" as "built-in" unverified). E2EE comparison to Telegram accurate, but ignores Discord's data retention policy (indefinite).
  [Why]: Gaps expose to Discord-side scraping/bans if patterns look automated. S8.3 risk assessment downplays: LLM providers see content transiently, Discord persistently.
  [Fix]: Add S8.6: "Discord ToS check: Confirm personal server + bots allowed (link policy)." Mitigation: "Enable Discord auto-moderation rules to flag anomalies." Periodic export (S13.6).

- [F7]
  [Severity]: MINOR
  [Finding]: Discord server layout S3.1 lists #dispatch-log under Infrastructure, but S1b/crumb-tess-bridge routes exclusively there -- no Telegram escalation defined except "unless Danny waiting" (S5.4). Naming: "Tess Ops" generic; channels lowercase-hyphen consistent but #weekly-review lacks forum despite self-contained outputs.
  [Why]: Minor UX/naming inconsistency; weekly reviews could benefit from forum like briefings for browsability.
  [Fix]: Make #weekly-review [forum]; rename server "Crumb Tess Ops" to match project. Define dispatch Telegram alert: "If dispatch >5min pending, notify Telegram."

- [F8]
  [Severity]: SIGNIFICANT
  [Finding]: Delivery matrix S5.5: "Approval result" -> Discord edit original, but Discord edits require message ID retention across sessions/agents. Unclear how Tess retains Discord msg ID from Telegram-originated mirror for later edit. Mechanic/Discord-only outputs fine, but cross-agent audit?
  [Why]: Edit fails silently if ID lost (common in multi-session), leaving stale audit. Breaks S2.3 permanent reference promise.
  [Fix]: Change to "Reply to mirror with update" (no ID needed). Or store msg IDs in shared vault with ID=actionID.

- [F9]
  [Severity]: MINOR
  [Finding]: Phasing gates (S9) measurable (e.g., >=90% delivery, 5 days), but Phase 0 "Test: Send message in #sandbox" assumes interactive works pre-cron. No metrics tooling defined (e.g., how measure 95% success?). Rollback S12 clean, but no "success criteria" for full rollout.
  [Why]: Gates good but operational gap -- manual spot-checks unscalable.
  [Fix]: Add "Mechanic monitors delivery success via API probes, logs to #audit-log." Define post-Phase 3: "Promote to status: operational if gates pass x2 cycles."

- [F10]
  [Severity]: CRITICAL
  [Finding]: S10.3 failure modes miss core: If Telegram down (S10.3 row), fallback to Discord DM -- but S2.3 says Discord unstable for interaction, and config S4.2 has `dm.enabled: true` but `execApprovals.target: "dm"` unverified. No voice notes/DM button support on Discord. Contradicts "Telegram primary, irreplaceable."
  [Why]: Single point of failure for approvals/voice -- complete outage scenario unmitigated, despite "both down" row.
  [Fix]: Add row: "Telegram down | Approvals/voice blocked | Add Discord slash commands for approve/<id> via mechanic cron-poll. WebChat as voice fallback (local)."

- [F11]
  [Severity]: MINOR
  [Finding]: Cost analysis S11 low ($0.90-1.80/mo) ignores Discord API rate-limit backoffs potentially inflating LLM retries, or Haiku token burn from dual-format gen. No baseline (pre-Discord cost).
  [Why]: Underestimates; dual-delivery doubles prompts.
  [Fix]: Revise: "Doubles briefing prompts: +$1-2/mo. Monitor via OpenClaw billing export."

- [F12]
  [Severity]: SIGNIFICANT
  [Finding]: Open questions S13 defer too much: #2 forum thread limits (Discord ~50 active threads/channel soft-limit, archives ok but search degrades); #5 mechanic independence changes Telegram path undefined. No owner/timeline for resolution.
  [Why]: Risks Phase 3 surprises (e.g., 365 briefings -> channel clutter).
  [Fix]: Assign: "Phase 1 gate: Verify <50 active threads. #5: Defer to mechanic spec."

- [F13]
  [Severity]: STRENGTH
  [Finding]: Channel selection rationale (S2) comprehensive table/matrix, accurately weighs Telegram (stable long-poll, buttons) vs. Discord (hierarchy, forums). Rejections (WhatsApp ban risk, etc.) grounded.
  [Why]: Clear, feasible dual-channel split addresses problem statement limits directly. Edge: Discord instability mitigated by Telegram primacy.

- [F14]
  [Severity]: STRENGTH
  [Finding]: Server layout S3.1 logical hierarchy (categories -> forum/text), forum use for self-contained outputs perfect for Discord UX. Naming conventions consistent/scalable.
  [Why]: Directly solves "no topical organization" problem; multi-agent via bots visual. Edge: Scalable to new channels (S4.3).

- [F15]
  [Severity]: STRENGTH
  [Finding]: Delivery patterns S5 (cron dual, approval mirror) and matrix S5.5 precise, covering 16 output types without gaps. Phased rollout (S9) ties to chief-of-staff phases.
  [Why]: Complete, consistent with real-time/archive split. Measurable gates ensure feasibility.

---

## Synthesis

**Note:** DeepSeek reviewed the wrong artifact — all 12 findings reference gogcli, Gmail filters, Google Calendar, GOG_KEYRING_PASSWORD, and other Google Services spec content. DeepSeek's response is excluded from synthesis entirely. Synthesis is based on 3 of 4 reviewers: OpenAI (GPT-5.2), Gemini (Gemini 3 Pro Preview), and Grok (Grok 4.1 Fast Reasoning).

### Consensus Findings

**1. Approval mirror message ID persistence (CRITICAL)**
OAI-F5, GEM-F1, GRK-F8 — All three reviewers independently identified that the approval mirror pattern (S5.2) requires editing a Discord message after a Telegram button press, but no mechanism exists to store or correlate the Discord message ID with the Telegram approval ID. Without this, edits fail silently and the audit trail breaks. Gemini rated this CRITICAL; OpenAI proposed an Approval Record schema with SQLite/JSONL; Grok suggested a simpler "reply instead of edit" alternative.

**2. OpenClaw config schema unverifiable (SIGNIFICANT)**
OAI-F1/F3, GEM-F3, GRK-F1/F2 — All three flagged that the multi-account config structure (`channels.discord.accounts` with named sub-accounts), identity links, DM policy keys, and other config blocks cannot be verified against public OpenClaw documentation. Silent-ignore of unknown keys is a real risk. OpenAI recommended schema validation + known-good minimal configs; Gemini suggested a webhook/avatar-based fallback if multi-account is unsupported.

**3. crossContextRoutes / issue #22725 dependency (SIGNIFICANT)**
OAI-F2, GEM-F2, GRK-F4 — All three flagged that S5.3 treats cross-context routing as an expected near-term capability, but issue #22725 is unverified and may not ship. Consensus: elevate the webhook/local bridge fallback to the primary implementation path and demote crossContextRoutes to "future enhancement."

**4. Discord zombie connection risk (SIGNIFICANT)**
OAI-F17, GEM-F4 — Two reviewers identified that standard WebSocket reconnect logic doesn't handle the "zombie" state (socket open but not receiving events). Gemini proposed an application-level heartbeat: Mechanic sends a test message and verifies receipt, forcing a Gateway restart on failure.

**5. Multi-agent bot permissions (SIGNIFICANT)**
OAI-F7, GRK-F5 — Two reviewers flagged that bot intents and permissions are broader than necessary. OpenAI recommended splitting intent profiles (outbound-only bots don't need Message Content Intent); Grok flagged permission creep risk and suggested channel-specific overrides post-invite.

### Unique Findings

**GRK-F3 (CRITICAL) — Audit-log channel routing gap:** mechanic-bot's config excludes #audit-log, but audit logs come from multiple agents. This is a genuine configuration contradiction — S4.1 implies Tess handles #audit-log but doesn't specify multi-agent audit routing. **Genuine insight.**

**GRK-F10 (CRITICAL) — Telegram-down fallback contradicts architecture:** S10.3 specifies Discord DM as Telegram fallback, but S2.3 explicitly calls Discord "unstable for interaction." Using DM for approvals/voice when the architecture says Discord isn't reliable for interaction is contradictory. Grok proposed Discord slash commands for approvals + local WebChat for voice. **Genuine insight.**

**OAI-F8 (SIGNIFICANT) — Human account hardening missing:** Security model (S8) focuses on bot permissions but omits Danny's Discord account (2FA, invite hygiene, "Create Invite" permission lockdown). A compromised user account defeats all bot least-privilege work. **Genuine insight.**

**OAI-F4 (SIGNIFICANT) — Forum/thread semantics conflated:** Discord "Forum Channel" posts are distinct from thread creation via `message send`. If OpenClaw doesn't support native forum-post creation, messages may fail or land incorrectly. **Genuine insight** — this is a concrete API-level risk.

**GRK-F6 (SIGNIFICANT) — Discord ToS/data retention:** Security model doesn't address Discord's indefinite data retention or ToS compliance for automated bots. **Genuine insight** — brief note warranted.

**GRK-F12 (SIGNIFICANT) — Open questions defer without ownership:** Open questions (S13) lack assigned owners and timelines. Forum thread limits (Discord soft-limits ~50 active threads/channel) is a concrete Phase 3 risk. **Partial insight** — thread limit is worth noting; ownership is premature for SPECIFY.

**OAI-F6 (SIGNIFICANT) — Webhook/RPC fallback underspecified:** The fallback needs authentication, idempotency keys, and queueing to avoid becoming an internal escalation vector. **Partial insight** — the security concerns are valid but the proposed mTLS solution is over-engineered for a loopback service on a personal machine.

**GEM-F6 (MINOR) — Forum channel tagging deferred:** Defining 3-4 basic tags now (Urgent, Routine, Report) saves retroactive effort. **Noise** — tagging can be decided during Phase 1 with real content.

**GRK-F7 (MINOR) — #weekly-review as forum channel:** Would benefit from forum format like briefings. **Partial insight** — reasonable UX improvement.

### Contradictions

**1. Fallback mechanism complexity:** OAI-F6 proposes mTLS + HMAC + on-disk queue with at-least-once delivery semantics for the cross-context bridge. GRK-F4 proposes a simple shell script: `openclaw message send --channel discord --target <id>`. These represent fundamentally different complexity tiers. **Flag for human judgment** — the right level depends on how much the operator values defense-in-depth on a single-user loopback machine.

**2. Approval edit vs. reply:** OAI-F5 proposes a full Approval Record schema (SQLite/JSONL with message ID correlation). GRK-F8 proposes simply replying to the original mirror message instead of editing it (no ID persistence needed). **Flag for human judgment** — reply is simpler but produces noisier audit; edit is cleaner but requires state persistence.

### Action Items

**Must-fix:**

- **A1** (OAI-F5, GEM-F1, GRK-F8) — **Define approval state persistence or adopt reply-based pattern.** The approval mirror in S5.2 cannot work without either (a) a message ID correlation store mapping approval_id → discord_message_id, or (b) switching from edit-in-place to reply-with-update. Choose one approach and document it.

- **A2** (GRK-F3) — **Fix audit-log channel routing.** Add #audit-log to mechanic-bot's channel allowlist (and any future agent bots), or split into per-agent audit channels. Update S4.1 table and S4.2 config.

- **A3** (GRK-F10) — **Replace Discord DM as Telegram-down fallback.** The current fallback contradicts the architecture's own assessment of Discord for interaction. Define a viable alternative: Discord slash commands for approval flows, local WebChat for voice, or explicit "approvals blocked — queue until Telegram recovers."

**Should-fix:**

- **A4** (OAI-F1/F3, GEM-F3, GRK-F1/F2) — **Add Phase 0 config schema validation step.** Include a "print effective config" verification that confirms all specified keys are recognized (not silently ignored). Add known-good minimal config baseline alongside the aspirational full config.

- **A5** (OAI-F2, GEM-F2, GRK-F4) — **Elevate webhook/local bridge to primary cross-context mechanism.** Demote crossContextRoutes (issue #22725) to "future enhancement" language. Define the fallback as a local loopback service with shared-secret auth, idempotency keys (use approval/output ID), and basic queueing.

- **A6** (OAI-F17, GEM-F4) — **Add application-level Discord heartbeat.** Standard reconnect doesn't catch zombie connections. Mechanic should periodically send a test message to a monitor channel and verify receipt; force Gateway restart on failure.

- **A7** (OAI-F8) — **Add human account hardening to S8.** Require 2FA on Danny's Discord account, disable/limit "Create Invite" permission, delete existing invites, and document periodic member-list review.

- **A8** (OAI-F7, GRK-F5) — **Minimize Discord bot intents per bot profile.** Outbound-only bots (mechanic) should not request Message Content or Server Members Intent. Interactive bot (tess in #sandbox) documents exactly why it needs each intent. Add channel-specific permission overrides post-invite.

- **A9** (GRK-F6) — **Add Discord ToS/data retention note to S8.** Brief note that Discord retains data indefinitely (vs. Telegram Bot API's server-side), and confirm personal server + bot usage is ToS-compliant.

**Defer:**

- **A10** (OAI-F4) — **Clarify forum/thread API semantics.** Specify whether OpenClaw uses forum post creation or standard thread creation. Deferrable because Phase 0 validation will catch this empirically.

- **A11** (GRK-F7) — **Consider #weekly-review as forum channel.** Minor UX improvement; can be decided during Phase 1 setup.

- **A12** (GRK-F12) — **Note Discord forum thread soft limit (~50 active/channel).** Add to open questions with Phase 1 gate verification. Ownership/timeline assignment is premature for SPECIFY phase.

### Considered and Declined

- **OAI-F6** (mTLS/HMAC for fallback bridge): `overkill` — mTLS for a loopback-only service on a single-user machine adds complexity without proportional security benefit. Shared-secret auth is sufficient; folded into A5.
- **OAI-F9** (explicit loopback bind requirement): `constraint` — the chief-of-staff spec already establishes loopback-only architecture. Adding a `lsof` verification command is reasonable but covered by A5's validation step.
- **OAI-F10** (DM policy / event acceptance matrix): `overkill` — the config already specifies allowlists and requireMention per channel. A separate matrix document adds maintenance burden for a 3-bot private server.
- **OAI-F11** (rate limiting strategy): `overkill` — Discord rate limits are per-channel/per-user. With 3 bots in a private server producing <50 messages/day, hitting rate limits is implausible. Monitor in production.
- **OAI-F12** (file attachment handling): `out-of-scope` — file exchange is explicitly deferred to Phase 3 in the spec. The gap is known and intentional.
- **OAI-F13** (privacy comparison phrasing): `overkill` — current phrasing is accurate enough for operational decisions. Both are server-visible; the point is made.
- **OAI-F18** (execApprovals unverifiable): `constraint` — already flagged for Phase 0 verification in §4.2 note added during Crumb review.
- **OAI-F19** (identityLinks unverifiable): `constraint` — already flagged for Phase 0 verification in §4.2 note.
- **GEM-F5** (chunking edge case for >2000-char paragraphs): `overkill` — operational messages rarely produce single paragraphs exceeding 2000 characters. Monitor in production.
- **GEM-F6** (forum tagging taxonomy now): `overkill` — tagging decisions are better made with real content during Phase 1. Retroactive tagging in a private server is trivial.
- **GRK-F9** (metrics tooling for gate verification): `overkill` — manual spot-checks are appropriate for Phase 1-2 scale (single user, 3 bots). Automated monitoring can be added in Phase 3.
- **GRK-F11** (cost underestimate from dual-format): `incorrect` — Discord messages are reformatted templates, not separate LLM calls. The formatting overhead is negligible.
