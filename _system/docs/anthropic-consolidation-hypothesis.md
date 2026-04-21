---
type: reference
status: hypothesis
domain: software
created: 2026-04-21
updated: 2026-04-21
verification_pass: 2026-04-21
tags:
  - strategy
  - architecture
  - hypothesis
  - tess
  - cowork
  - liberation-directive
---

# Anthropic Stack Consolidation — Hypothesis

**Status:** Hypothesis under evaluation. Not a decision. Do not act on this as if it were settled.

## Context

On 2026-04-21 Danny had an extended strategic conversation with Claude Opus (via claude.ai web) triggered by a Perplexity Personal Computer waitlist email. The conversation moved from "what is Personal Computer" to a broader architectural reframe: consolidate onto the Anthropic stack, sunset Tess, treat Crumb (vault + epistemic structure) as the durable differentiator, treat execution runtimes as commodity.

Crumb reviewed the thread and flagged sycophancy drift, unverified product claims, and unexamined conflict with the active Liberation Directive. Web Opus acknowledged the critique. This note captures the hypothesis so it can be tested against evidence rather than carried forward as a settled conclusion.

## The Hypothesis

1. **Coding harnesses stay differentiated** — Claude Code primary, occasional experiments with Codex and Droid for specific task types. Work properties (tight feedback loops, high per-token stakes) reward specialization.
2. **Life-OS harnesses are converging** — Anthropic, Perplexity, and OpenAI are building structurally similar stacks (harness + skills + plugins + connectors + scheduled execution + dispatch). Marginal improvements from well-funded vendors will outpace solo-dev work on orchestration infrastructure.
3. **Tess infrastructure is racing gravity** — Building a personal always-on orchestrator is a losing position against industry convergence on the same pattern.
4. **The vault is the real moat** — Crumb's epistemic structure (frontmatter, MOCs, phasing, lifecycle conventions) is the part that compounds and that no vendor can ship.
5. **Architecture proposal:** Mac Studio runs Cowork (life-OS execution) plus Claude Code (vault-grounded knowledge work). Laptop is a thin client via Screen Sharing + SSH. Phone dispatches via Dispatch. One Anthropic subscription. Tess winds down.

## Load-Bearing Claims — Verification Results (2026-04-21)

Verified against primary Anthropic documentation. Summary: the three load-bearing claims hold, and two new facts materially soften constraints.

| Claim | Verified? | Source |
|---|---|---|
| Cowork scheduled tasks require Mac awake + Desktop open | **Yes** | [support.claude.com/en/articles/13854387](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork) |
| Cowork single-device lock per account | **Yes** | [GitHub issue #43698](https://github.com/anthropics/claude-code/issues/43698), filed 2026-04-05, open, no Anthropic response yet |
| Claude Code Remote Control exists with full local filesystem + MCP access | **Yes** | [code.claude.com/docs/en/remote-control](https://code.claude.com/docs/en/remote-control) |
| Cowork available on Pro/Max/Team/Enterprise | **Yes** | Scheduled-tasks support article confirms all paid plans |
| Remote Control available on all paid plans (not Max-only) | **Yes** — correction from conversation | Remote Control docs: "Pro, Max, Team, and Enterprise plans. API keys are not supported." |

### New facts that soften earlier framing

1. **Skipped scheduled tasks auto-rerun when the Mac wakes.** Quoting support.claude.com: *"Cowork will skip the task, then run it automatically once your computer wakes up or you open the desktop app again."* Users are notified when a skipped run executes. On a Mac Studio that's always awake, this is moot. On a laptop it's a meaningful mitigation. Reduces the "must stay awake" constraint from hard to soft.

2. **Cloud-hosted scheduled tasks (Routines) exist as a separate path.** The Remote Control docs table shows scheduled tasks can run on "CLI, Desktop, or cloud." Routines sidesteps the Mac-awake constraint entirely for recurring automation. Not evaluated in the conversation — worth investigating as a potential Tess-execution substitute for certain workflows.

3. **Channels mechanism.** Claude Code exposes a Channels feature that forwards Telegram/Discord/iMessage events into a live session. Given Tess's existing Telegram bot integration (`openclaw-ops`), this is a possible integration path rather than a displacement, and may be the more interesting pattern than wholesale sunset.

### Remaining unverified claims (from web Opus conversation — treat as provisional)

- Cowork "data exfiltration vulnerability two days after January 13 launch" — secondary source (devops.com), not verified. Before granting Cowork vault access, check current security posture directly.
- Snyk "13.4% of public Skills have critical vulns" — secondary source blog, directional only.
- Specific connector lists and February 2026 dated additions — third-party blog; verify list currency via Anthropic docs before planning against specific connectors.
- Local MCP availability in Cowork vs. Claude Desktop chat — claim that local MCP is Desktop-chat-only, not Cowork. Worth verifying if Tess-as-MCP-server integration is pursued.

### Practical constraints newly surfaced

- **Remote Control 10-minute network timeout.** If the Mac loses network for more than ~10 minutes while the remote session is idle, it times out and the `claude` process exits. Session must be restarted. Matters for "laptop SSH into Mac Studio" reliability during network flakiness.
- **Ultraplan disconnects Remote Control.** Both occupy the claude.ai/code surface; only one can be active at a time.
- **Single-device lock issue #43698 was filed 2026-04-05, currently has no Anthropic response.** Don't assume imminent resolution. Plan against the current state.

## Conflict With the Liberation Directive

The hypothesis conflicts with the active governing directive (`_system/directives/liberation-directive.md`, v1.1, 2026-03-19) on several points. Naming these explicitly:

1. **Tess's role in the directive is load-bearing.** Tess is the execution surface for Firekeeper Books production (Prompt 1, the single designated execution commitment), the audience-building content calendar (Prompt 5), and the Opportunity Scout daily digest (Prompt 6). Sunsetting Tess without a replacement runtime for daily execution against approved specs breaks the directive's handoff pattern: `Crumb spec → approved → Tess standing order → daily execution`.

2. **Cowork is assigned a narrower role.** In the directive's four-surface model (plus Cowork as polisher and Computer as the fifth), Cowork's job is "polished deliverables" — Word, Excel, PDFs, PowerPoint. Elevating it to always-on orchestrator replacement for Tess is a role expansion the directive doesn't currently sanction.

3. **The directive explicitly keeps Perplexity Computer for research-heavy discovery.** Prompts 2, 3, 4 are Computer-first. "Abandon Perplexity, go Anthropic-only" removes the designated research surface.

4. **"Revenue leads" ≠ infra freeze.** Per memory (`feedback-revenue-leads.md`) and the directive itself: revenue-generating prompts get priority claim, other work continues in parallel. The hypothesis reads closer to infra freeze than priority ordering.

5. **Recent Tess validation contradicts the "racing gravity" framing.** Commits 585c8c90 and d96d1916 show Tess running Kimi K2.6 evaluation (87/100, 0 fabrications) and GPT-5.4 runtime swap — this is a working, recently-validated capability, not an inert artifact. Shelving it is a real capital write-off, not "capturing the thinking in vault docs."

**Implication:** Adopting the hypothesis as-is requires either updating the Liberation Directive or rejecting the hypothesis. The two cannot coexist in their current forms.

## Open Questions / Residuals

- **Scheduled-task reliability on Cowork vs. launchd.** Tess runs as a LaunchDaemon; if Cowork scheduled tasks require Desktop app open + Mac awake, that's a meaningfully weaker substrate for the FIF pipeline, Opportunity Scout, and overnight processing. Mac Studio being always-on mitigates but doesn't eliminate.
- **Vault-standards enforcement outside Claude Code.** Pre-commit hooks (vault-check) enforce mechanically regardless of executor. But CLAUDE.md conventions (ceremony budget, phase gates, spec-before-implement, context-checkpoint-protocol) require the executor to load and honor them. Claude Code does. Does Cowork? How?
- **Hermes stranding accounting.** If Tess sunsets, the Kimi K2.5/K2.6 orchestrator validation, the Hermes runtime, and the routing-by-verifiability mechanization are shelved. Real engineering investment. What's the write-off worth?
- **"One subscription" framing glossed model-selection rationale.** Kimi and Nemotron weren't only cost-optimization choices — they were model-selection choices (Kimi's sequential-tool-call profile, Nemotron's local privacy). Consolidating to Claude-only trades that optionality for cognitive simplicity. Named trade-off, not free lunch.
- **Mac Studio single point of failure.** Crumb + Cowork + Claude Code + vault + credentials + scheduled tasks + Dispatch endpoint all on one machine. Mitigation plan needed, not a hand-wave.
- **Liberation Directive reconciliation.** If the hypothesis advances, the directive needs a v1.2 that either updates surface assignments or explicitly rejects the consolidation case.

## Pilot Design (If Pursued)

If the verification step on load-bearing product claims succeeds, run a bounded pilot before committing:

**Scope:** Install Cowork on the Mac Studio. Leave Tess running. Do not rearchitect anything.

**Pilot workflows (pick 3):**
- One Firekeeper-relevant workflow (document production, research synthesis)
- One daily-execution workflow currently running on Tess (e.g., Opportunity Scout digest, feed-intel triage)
- One vault-touching workflow (e.g., weekly run-log synthesis, knowledge-note creation)

**Duration:** 14–30 days. Shorter if one workflow produces decisive evidence early.

**Measurement dimensions (in Danny's terms):**
- Vault-standards adherence — does Cowork respect frontmatter conventions, phase gates, MOC patterns, the signal-scan-on-kb-tag reflex?
- Ceremony cost — how much prompting/intervention does Cowork require to do what Tess does autonomously?
- Output quality — comparable, better, worse?
- Failure modes — where does Cowork fail, and how is the failure surfaced?
- Liberation Directive alignment — does the pilot free time for revenue-generating prompts, or does it shift it to different infra work?

**Decision criteria:**
- **Green light wind-down:** Cowork handles vault work at parity or better on 2 of 3 workflows, vault-standards adherence is defensible, and the Liberation Directive can be updated coherently.
- **Keep Tess as-is:** Cowork underperforms on vault-standards adherence or scheduled-task reliability, or the Liberation Directive conflicts can't be resolved.
- **Hybrid:** Cowork takes some workflows (likely document production, connector-heavy tasks), Tess stays for launchd-grade scheduled execution.

Hybrid is the most likely outcome given the current evidence.

## Routines and Channels — What the Conversation Missed

The web Opus conversation framed the Anthropic-side always-on story around Cowork-on-Mac-Studio. Primary-source investigation surfaced two research-preview features that change the hypothesis materially. Both were missed in the original thread.

### Routines (cloud-hosted scheduled Claude Code sessions)

Source: [code.claude.com/docs/en/routines](https://code.claude.com/docs/en/routines)

*"Routines execute on Anthropic-managed cloud infrastructure, so they keep working when your laptop is closed."* Available Pro/Max/Team/Enterprise with Claude Code on the web enabled. Research preview.

Triggers: schedule (cron, 1-hour minimum), API (HTTP POST to a per-routine `/fire` endpoint with bearer token), GitHub events (PR/release). Multiple triggers per routine.

**Critical properties for the Tess question:**

| Property | Routines | Cowork scheduled | Desktop Cowork | Tess (current) |
|---|---|---|---|---|
| Requires machine on | **No** | Yes | Yes | N/A (Mac Studio always on) |
| Requires open session | No | No | Yes | N/A |
| Access to local files | **No (fresh git clone)** | Yes | Yes | Yes (live filesystem) |
| MCP servers | Connectors only | Config + connectors | Config + connectors | Local MCP available |
| Autonomous (no approval prompts) | **Yes** | Configurable | Configurable | Yes |
| Minimum interval | 1 hour | 1 minute | 1 minute | Any |

The fresh-clone model is the defining constraint. Routines work against a GitHub repo; they don't have the live local vault. They clone, push `claude/`-prefixed branches, and open PRs. For vault workflows this is a different operational model than Tess — the vault lives in crumb-vault and crumb-vault-mirror, so it's reachable, but Routines writes via PR rather than direct.

**What Tess workflows could plausibly migrate to Routines:**
- Opportunity Scout daily digest (reads feeds, writes artifact via PR)
- Feed intel tier classification and promotion (if pipeline state lives in the repo)
- Firekeeper Books production tasks that produce vault artifacts
- Audience content drafting on cadence
- Weekly/monthly summary syntheses

**What cannot migrate and must stay on Tess / local launchd:**
- Anything requiring local MCP (obsidian-cli, local file tools)
- Anything requiring live filesystem state rather than repo snapshot
- Backup/mirror-sync operations
- LLM health monitoring / service status checks
- Anything requiring launchd-grade scheduling reliability at sub-hour intervals

This reframes the question from "Cowork vs. Tess" to "**Routines handles schedule-triggered vault-artifact production; Tess stays for local-execution-bound work.**" That's a hybrid architecture, not a sunset.

### Channels (events pushed into a running Claude Code session)

Source: [code.claude.com/docs/en/channels](https://code.claude.com/docs/en/channels)

MCP plugin mechanism that pushes events into a running Claude Code session. Official plugins: Telegram, Discord, iMessage. Requires Claude Code v2.1.80+, `--channels` flag, and an active session (background process or persistent terminal for always-on use).

Relevant to Tess because **Tess already uses Telegram as its reporting bridge** (per `memory/openclaw-ops.md`). Channels inverts the direction: it lets Danny text a Telegram bot and have the message arrive in a running Claude Code session. The pair of patterns together (Tess → Telegram outbound; Channels → Telegram inbound into Claude Code) is a full bidirectional mobile bridge without building it.

### Revised hypothesis shape

The conversation's "one subscription, consolidate on Anthropic, sunset Tess" framing collapses when Routines is factored in. The more accurate reframe:

- **Routines** takes a subset of Tess's schedule-triggered workloads (vault-artifact production at ≥1h cadence)
- **Channels** provides the Telegram-inbound bridge that Tess doesn't have
- **Cowork-on-Mac-Studio** handles interactive life-OS execution (document production, connector-heavy work)
- **Remote Control** (Claude Code) handles remote-from-phone interactive vault work
- **Tess (Hermes)** stays for: local-MCP-bound execution, launchd-grade scheduling, sub-hour reliability, live filesystem state, LLM health monitoring, backup/sync

This is a division of labor, not a replacement. It also means the Liberation Directive's four-surface model (Crumb, Tess, Chrome, Comet, plus Computer) expands to include Routines and Channels as additional surfaces, rather than being restructured to drop Tess.

## Residual Recommendation (Revised)

1. **Load-bearing claims verified.** Done 2026-04-21. Architecture sketch from the conversation is product-accurate but incomplete.
2. **The conversation's conclusion doesn't survive the verification pass.** "Sunset Tess and consolidate on Cowork" was based on a partial surface inventory. The correct reframe is division of labor across Routines / Cowork / Remote Control / Tess / Channels, not substitution.
3. **Do not commit** to sunsetting Tess. The Tess-stays case is meaningfully stronger than the conversation allowed.
4. **Pilot design, revised:**
   - **Routines pilot:** Pick one schedule-triggered Tess workflow (Opportunity Scout daily digest is the clean candidate — already produces vault artifacts, has a clear output format, runs at daily cadence). Build it as a Routine against crumb-vault. Compare output quality, PR workflow ergonomics, and cost against Tess's current version for 2–4 weeks.
   - **Channels pilot:** Install the Telegram channel plugin on a persistent Claude Code session on the Mac Studio. Test the inbound flow (text the bot → message arrives in session). Decide whether this complements or replaces any piece of Tess's Telegram integration.
   - **Cowork pilot:** Deferred. The document-production use case is real but lower priority than understanding Routines.
5. **Liberation Directive action:** the directive needs a v1.2 regardless of pilot outcome — to add Routines and Channels to the surface inventory. Draft when pilot evidence is in.
6. **Vault-standards portability work continues** independently. The more surfaces the vault is accessed from, the more important mechanical enforcement (pre-commit hooks, vault-check) becomes relative to CLAUDE.md-conventions.

## Compound Observation

Both the web Opus and my first verification pass anchored on Cowork as the Anthropic-side always-on surface. Routines was not in either mental model. Two independent passes missed the same feature because the framing was "Cowork vs. Tess" from the first turn, and neither pass questioned the frame itself. The verification step surfaced it only because the Remote Control docs happened to link to Routines via the "scheduling options" table.

Lesson: when evaluating a product landscape, pull the full feature inventory before framing comparisons. "What surfaces does Anthropic actually offer for unattended scheduling?" would have found Routines in one query; "Cowork vs. Tess" never would have.

Worth routing into `_system/docs/solutions/` as a compound pattern about framing risk in vendor comparisons.

## What This Document Is Not

- Not a project. Project creation requires user confirmation per CLAUDE.md project creation protocol.
- Not a Liberation Directive amendment. Any update to v1.1 is a separate, explicit action.
- Not a decision to sunset Tess. Tess continues in current configuration until explicit decision.

## Related

- `_system/directives/liberation-directive.md` — governing directive; reconciliation required if this advances
- `_system/docs/crumb-v2-system-health-assessment.md` — ceremony budget principle
- Memory: `feedback-revenue-leads.md`, `feedback-schema-addition-reflex.md`, `model-grok-fabrications.md`, `model-kimi-recovery-fabrication.md`
- Source conversation: claude.ai web session, 2026-04-21 (not archived in vault; reasoning captured above)
