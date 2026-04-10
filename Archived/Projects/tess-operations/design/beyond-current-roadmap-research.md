---
project: tess-operations
type: specification
domain: software
status: active
created: 2026-02-28
updated: 2026-02-28
tags:
  - tess
  - openclaw
  - frontier
---

# Beyond the Current Roadmap: Novel Workflow Possibilities for Tess

**Status:** Research memo — ideas for evaluation, not commitments
**Date:** 2026-02-28
**Premise:** The agent-to-agent draft and tess-frontier-ideas.md cover the obvious workflows. This document explores patterns we *haven't* thought of yet, drawing from external research and analysis of gaps in the current architecture.

---

## How I Organized This

I looked at three things:

1. **What's already covered** — the agent-to-agent draft (4 workflows), the frontier ideas doc (14 ideas), and tess-operations tasks (54 tasks)
2. **What patterns exist in the wild** — OpenClaw community builds, personal AI agent systems, self-improving agent research, CRM patterns, and proactive automation frameworks
3. **Where the gaps are** — things that Danny's stack is uniquely positioned for but nobody has explicitly designed

Already covered well: monitoring/alerting, morning briefings, feed intel pipeline, competitive intelligence, vault health, meeting prep, research dispatch, relationship cadence tracking, follow-through engine, knowledge arbitrage, adversarial pre-brief, self-optimization loop, voice capture, session recording, attention flywheel, proactive skill drafting, fact-checking, secrets hygiene, session compaction, three-body protocol, parallel research swarm.

What follows is what's *not* in any of those documents.

---

## 1. Project Stall Detection and Unsticking

**What's missing:** The vault has project-state.yaml files with `next_action` fields. The frontier ideas doc mentions "vault drift detection" as a bullet under proactive awareness, but nobody has designed what happens *after* detection. Detection without intervention is just a notification.

**The idea:** When Tess detects a project stall (next_action unchanged for N days, no commits to project directory, no run-log entries), she doesn't just alert Danny. She *diagnoses why* and proposes a recovery path:

- **Blocked by dependency?** Cross-reference the blocked project's dependencies against other projects' states. "batch-book-pipeline is stalled on BBP-005 because you haven't had a Crumb session in 8 days. Feed-intel-framework M2 monitoring could also unblock BBP-005's validation approach."
- **Scope creep?** Compare current task count against milestone scope. "researcher-skill M5 has grown from 3 to 7 tasks since planning. Consider splitting into M5a/M5b."
- **Energy/motivation?** If a project stalls after repeated starts and stops (visible in run-log timestamps), surface that pattern rather than pretending it's a scheduling issue. "This is the third time think-different has stalled at the same point. What's actually blocking you here?"

**Why this matters for Danny specifically:** Solo practitioner managing ~25 accounts plus a complex personal system. Projects stall silently because there's no team standup forcing accountability. Tess becomes the accountability mechanism — but one with enough context to be useful rather than nagging.

**Tess-operations connection:** Extends vault drift detection (mentioned in awareness-check cron, TOP-053) from notification to intervention. Uses vault-check.sh + project-state.yaml + run-log timestamps as data sources.

**Readiness:** DESIGN-NEEDED. Detection is straightforward (file modification timestamps, project-state.yaml parsing). Diagnosis requires Tess to load multiple project contexts simultaneously, which bumps into the "Tess context loading" open question from the agent-to-agent draft.

---

## 2. Crumb Session Retrospective Loop

**What's missing:** The frontier ideas doc has Session Compaction (#12) and Session Recorder (#4), but both focus on *capturing* what happened. Nobody has designed a loop where past session *effectiveness* feeds forward into future session design.

**The idea:** After each Crumb session, Tess runs a lightweight retrospective:

- What was the planned objective (from Anticipatory Session prep, TOP-047)?
- What actually got done (from run-log entries, git commits)?
- How much scope drift occurred (planned tasks vs. completed tasks vs. unplanned tasks)?
- What was the effective hourly rate of vault artifacts produced?
- Were there repeated patterns (e.g., "every session starts with 30 min of context recovery" → session compaction is high priority)?

Over time, this builds an operational dataset about *how Danny and Crumb work together*. Patterns emerge: which project types benefit from longer sessions? Which tasks reliably take 2x the estimate? Which kinds of work produce the most scope creep?

**The key insight from self-improving agent research:** The Reflexion framework (cited in Andrew Ng's agentic AI course and multiple papers) shows that agents that review their own trajectories improve on subsequent attempts even without parameter changes. The same principle applies here — Tess reviewing Crumb session trajectories and adjusting session prep accordingly.

**Concrete output:** Instead of generic Anticipatory Session context, Tess generates *calibrated* session prep: "Based on past sessions, researcher-skill tasks take 1.5x estimated time. Plan for 2 tasks, not 3. Last session's unfinished work: [specific items]. Suggested starting point based on completion patterns: [specific task]."

**Readiness:** EXPLORATORY. Depends on Anticipatory Session (TOP-047) being operational first. The retrospective adds a feedback loop on top of it.

---

## 3. Communication Drafting with Voice Calibration

**What's missing:** Tess-operations plans email drafting (TOP-031/037) and iMessage (TOP-043), but these are infrastructure tasks — the *ability* to send. Nobody has designed how Tess learns Danny's communication *voice* across different contexts.

**The idea:** Danny communicates differently with customers vs. internal engineering vs. personal contacts. Instead of generic drafts, Tess builds and maintains a set of "voice profiles" — not as a formal system, but as a curated collection of exemplar messages that she references when drafting.

**Concrete flow:**
1. As email/iMessage integration comes online, Tess passively observes Danny's sent messages (read-only, already in the Google/Apple specs)
2. Over time, she clusters patterns: customer-facing tone, internal-to-engineering tone, brief vs. detailed based on recipient, how Danny's formality shifts for different account tiers
3. When Danny says "draft a follow-up to Acme Corp about the DNS migration timeline," Tess generates a draft that *sounds like Danny writing to that specific customer*, not like a generic AI email

**Why this goes beyond existing tools:** Shortwave's Ghostwriter and similar tools learn from past emails, but they don't have Danny's vault context. Tess knows that the Acme Corp engagement is at a critical juncture (from customer-intelligence dossier), that the technical lead there prefers concise bullets over prose (from meeting notes), and that Danny promised a timeline in last week's call (from follow-through engine, frontier idea #8).

**Privacy consideration:** Voice profiles are derived from Danny's own sent messages. They stay in the vault. They're never sent to external services. The profiles are a vault artifact, not a model fine-tune.

**Readiness:** DESIGN-NEEDED. Depends on Google services Phase 2 (email read) and the follow-through engine. The voice calibration itself is a prompt engineering challenge — how to distill "Danny's tone with enterprise customers" into a reliable reference.

---

## 4. Decision Journal and Pattern Surfacing

**What's missing:** Danny makes architectural decisions, prioritization calls, and trade-offs constantly — in Crumb sessions, in tess-operations gates, in customer engagements. These decisions are scattered across run-logs, project files, and conversation transcripts. Nobody is tracking *decision quality over time*.

**The idea:** Tess maintains a lightweight decision journal. Not every micro-decision — just the ones that cross a threshold:

- Architectural choices ("chose file-based handoffs over WebSocket for crumb-tess-bridge")
- Prioritization calls ("deprioritized vault gardening in favor of feed-intel compound insights")
- Trade-offs ("accepted single-dispatch constraint now, will revisit for parallel dispatch later")
- Predictions ("this approach should reduce session context recovery from 30 min to 5 min")

Each entry includes: the decision, the reasoning, the alternatives considered, and (critically) what would change your mind. Later, Tess can surface when a "what would change your mind" condition has been met.

**Example:** Danny decided to use Haiku 4.5 for the voice agent to minimize cost. The "what would change your mind" was: "If Haiku can't handle multi-step reasoning for orchestration decisions." When Tess starts orchestration work and hits a capability ceiling on Haiku, the decision journal surfaces: "You predicted this might happen — here's the original decision and reasoning. Time to revisit the model choice?"

**Why this is novel:** The OpenClaw community builds morning briefings, research agents, and email triage. Nobody is building a system that tracks the *meta-layer* — the quality of the human's own decisions about the system. This is a personal learning tool, not an agent capability.

**Readiness:** EXPLORATORY. The capture mechanism is the hard part. Decisions don't announce themselves — Tess would need to either (a) prompt Danny at session end ("any architectural decisions worth recording?") or (b) detect decisions from run-log entries (harder, noisier). Start with (a) as a manual practice.

---

## 5. Cross-Domain Insight Bridging

**What's missing:** The frontier ideas doc has Knowledge Arbitrage (#6) — surfacing personal KB models during professional work. But it's one-directional (personal → professional). Nobody has designed the *reverse* or the *lateral* paths.

**The idea:** Danny's domains don't just flow one way. Three unexplored bridges:

**Professional → Personal (reverse):** Patterns Danny discovers in DDI architecture and customer deployments have analogs in his personal system building. Example: "The zone delegation pattern you designed for a customer's DNS hierarchy maps directly to how your vault's MOC structure delegates topic authority. Consider whether your KB/ directory needs the same 'delegation of authority' model."

**Project → Project (lateral):** When a pattern succeeds in one project, proactively check whether it applies to another. Example: "The dispatch protocol's stage-isolation pattern (fresh governance verification per stage) from crumb-tess-bridge solved a class of problems that researcher-skill's RS-009 failure modes are trying to address differently. Should they converge?"

**Feed Intel → Active Project (targeted):** The compound insights workflow in the agent-to-agent draft already covers this, but there's a more specific pattern: when Tess processes a feed-intel item that *contradicts* an assumption in an active project's spec, that's higher signal than a generic cross-reference. Example: "This article claims file-based IPC has scaling limits at >100 messages/minute. Your crumb-tess-bridge assumes low throughput. Is this a risk or irrelevant to your use case?"

**Why this matters:** The frontier ideas doc wisely constrains Knowledge Arbitrage with opt-in and kill criteria to avoid "Proactive Clippy." But *contradiction detection* has a much better signal-to-noise ratio than generic cross-referencing. Surfacing when incoming information challenges an existing assumption is almost always worth the interruption.

**Readiness:** DESIGN-NEEDED for contradiction detection. EXPLORATORY for the broader cross-domain bridging. The contradiction variant could be a simple extension of the compound insights workflow: add a "check active project assumptions" step after feed-intel triage.

---

## 6. Operational Tempo Adaptation

**What's missing:** All of Tess's scheduled work runs on fixed schedules — 60-min heartbeat, 7 AM briefing, nightly vault check, hourly pipeline monitor. Nobody has designed a system that adjusts its tempo based on what's actually happening.

**The idea:** Tess observes Danny's activity patterns and adapts her operational rhythm:

- **High-activity periods** (lots of Crumb sessions, frequent vault commits, active customer engagement): Increase feed-intel processing frequency, run awareness checks more often, prepare session context proactively, increase heartbeat frequency.
- **Low-activity periods** (weekends, vacation, heads-down on a single project): Reduce noise, batch briefings, defer non-urgent vault checks, switch to "only alert on failures" mode.
- **Pre-meeting windows** (calendar integration detects upcoming customer call): Auto-trigger SE account prep, increase relevant feed-intel priority, prepare follow-through engine context from previous meeting.
- **Post-meeting windows** (meeting just ended): Prompt for action items, draft follow-ups, update relationship cadence tracker.

This is the difference between a cron job and an assistant. Cron jobs run on clocks. Assistants read the room.

**Pattern from the wild:** Slack's proactive agents documentation describes this as "sensing-reasoning-planning-acting" — agents that adjust behavior based on contextual signals rather than fixed schedules. The OpenClaw "20 Prompts" article describes heartbeat polling as a batched periodic check, but doesn't go as far as adaptive tempo.

**Readiness:** DESIGN-NEEDED. Calendar integration (TOP-027) provides the meeting signal. Vault commit frequency provides the activity signal. The design challenge is defining the adaptation rules without creating a system that's constantly fiddling with its own parameters. Start with 2-3 fixed "modes" (active, quiet, pre-meeting) rather than continuous adaptation.

---

## 7. Tess as External Memory During Live Conversations

**What's missing:** All current Tess workflows are *asynchronous* — she prepares before or processes after. Nobody has designed her role *during* a live interaction.

**The idea:** When Danny is on a customer call or in a Crumb session, Tess is available as an instant-recall system. Not as a participant in the conversation — as a vault-backed reference that can answer specific factual questions in real-time.

**Concrete scenario:** Danny is on a call with a customer who asks "when did we deploy the v2 migration?" Danny messages Tess on Telegram: "when did we deploy v2 for Acme?" Tess searches the vault (customer-intelligence dossier, meeting notes, email history) and responds in seconds with the date and relevant context.

**Why this is different from just searching the vault:** Danny could search his vault directly, but during a live call he's context-switching between the conversation and searching. Tess as intermediary means he can fire off a natural-language question and get a targeted answer without leaving the conversational flow.

**Extension:** For Crumb sessions, Tess could monitor for specific patterns where her context would help. If Crumb's dispatch hits an escalation about a customer's environment, Tess could proactively push relevant dossier data to the bridge rather than waiting for a formal escalation.

**Readiness:** READY for the basic version (Danny asks via Telegram, Tess searches and responds). The proactive monitoring during Crumb sessions is DESIGN-NEEDED and depends on multi-dispatch capability.

---

## 8. Skill & Tool Acquisition Pipeline

**What's missing:** The frontier ideas doc has Proactive Skill Drafting (#10) — Tess writes OpenClaw skills when she detects repeated patterns. But this is reactive (detecting repetition). Nobody has designed a system where Tess *proactively discovers* useful tools and capabilities.

**The idea:** When Tess encounters a gap in her capabilities, instead of just failing or escalating, she searches for solutions:

- **ClawHub search:** "I need to process a PDF but don't have a PDF skill. Let me check ClawHub for one."
- **MCP server discovery:** "This workflow would benefit from a Jira integration. There's an MCP server for that."
- **Bash tool composition:** "I don't have a dedicated skill for this, but I can compose existing shell tools to accomplish it."

The key constraint: Tess never *installs* anything without approval. She discovers, evaluates (checking permissions, security risk, compatibility), and proposes. Danny approves. Then she installs and tests.

**Self-improving agent research connection:** The Voyager framework (Minecraft agent) builds an expanding skill library through trial-and-error. The LearnAct framework establishes correction loops where agents improve their tools. The "self-improving-agent" Claude Code skill on Termo.ai logs learnings to .learnings/ directories. All share the pattern: agents that get better at using tools over time.

**Concrete scenario:** Tess is processing a customer-intelligence research dispatch and needs to extract text from a PDF the customer sent. She doesn't have a PDF processing capability. Instead of failing, she: (1) logs the capability gap, (2) searches ClawHub for a PDF skill, (3) evaluates it against security criteria (does it need shell.execute? does it phone home?), (4) proposes installation to Danny via Telegram with a risk assessment.

**Readiness:** DESIGN-NEEDED. The discovery mechanism exists (ClawHub is searchable). The evaluation criteria need definition. The approval flow is already designed (Approval Contract, TOP-049).

---

## 9. Degradation-Aware Workflow Routing

**What's missing:** The dispatch protocol (CTB-016) handles failures with retry and terminal failure states. But "failure" is binary. Nobody has designed for *partial degradation* — when a capability is working but working poorly.

**The idea:** Tess maintains awareness of current system health at a granular level and routes work accordingly:

- **Model degradation:** If Haiku is responding slowly or producing lower-quality outputs (detectable via response latency and basic output quality heuristics), route work to the mechanic agent (qwen3-coder) or escalate to Sonnet instead of producing bad results.
- **API degradation:** If Anthropic API is throttled, queue non-urgent work and only process time-sensitive items. If a feed source is returning 429s, temporarily reduce polling frequency rather than consuming retry budget.
- **Data freshness degradation:** If the vault mirror hasn't synced in 12 hours, flag all vault-dependent outputs as "potentially stale" rather than silently using old data.
- **Cost degradation:** If daily spend is approaching budget ceiling, automatically switch to cheaper models for non-critical work rather than hitting the hard cap and stopping all work.

**Why this matters:** Current architecture is binary — things work or they fail. Real systems have long periods of *degraded* operation where everything technically works but quality is suffering. A chief-of-staff should notice this and adapt, just like a human assistant would notice their boss is having a bad day and adjust the schedule accordingly.

**Tess-operations connection:** Extends the mechanic heartbeat (TOP-007) from "check if things are running" to "check if things are running *well*." Extends per-job token budgets (TOP-012) from enforcement to intelligent rationing.

**Readiness:** DESIGN-NEEDED. The monitoring signals exist (response times, error rates, cost tracking). The routing logic needs definition. Start with the cost degradation case since the infrastructure is already there (TOP-012).

---

## What's NOT Here (And Why)

Some things I considered and deliberately excluded:

- **Social media automation** (auto-posting, auto-engaging): The OpenClaw showcase is full of this. Danny's system is about intelligence and operational effectiveness, not content production. If Danny wants a LinkedIn presence, that's a separate decision.
- **Multi-provider model orchestration** (Research Council pattern — use Claude + Codex + Gemini in parallel): Danny's stack is Anthropic-focused with local qwen3 as backup. Adding providers adds complexity without clear value for the current use cases. Revisit if/when a specific workflow demonstrably benefits from a second provider's strengths.
- **Trading/financial automation**: Popular in OpenClaw community, irrelevant to Danny's use case.
- **Smart home integration**: Cool, not the point.
- **Full autonomy (human-out-of-the-loop)**: The Deloitte "autonomy spectrum" describes this as the end state. Danny's architecture deliberately keeps the human in the loop via mechanical enforcement. This is a feature, not a limitation to overcome.

---

## Relationship to Existing Documents

| Idea | Closest Existing Coverage | What's New |
|------|--------------------------|-----------|
| Project stall detection | Frontier #7 (self-optimization loop), vault drift detection bullet | Diagnosis + intervention, not just notification |
| Session retrospective loop | Frontier #4 (session recorder), #12 (session compaction), TOP-047 (session prep) | Feedback loop from session *effectiveness* back into session *design* |
| Communication voice calibration | TOP-031/037 (email infrastructure), frontier #8 (follow-through engine) | Learning Danny's voice per context, not just sending emails |
| Decision journal | None | Entirely new — meta-layer tracking decision quality over time |
| Cross-domain insight bridging | Frontier #6 (knowledge arbitrage) | Contradiction detection, reverse/lateral paths, not just personal→professional |
| Operational tempo adaptation | Fixed cron schedules throughout tess-operations | Adaptive rather than fixed scheduling |
| Live conversation memory | None | Real-time recall during calls/sessions, not just async prep |
| Skill acquisition pipeline | Frontier #10 (proactive skill drafting) | Discovery of *external* tools, not just drafting new ones |
| Degradation-aware routing | Mechanic heartbeat (TOP-007), token budgets (TOP-012) | Continuous quality monitoring, not binary up/down |
