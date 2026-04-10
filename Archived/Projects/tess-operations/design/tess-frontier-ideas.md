---
project: tess-operations
type: specification
domain: software
skill_origin: inbox-processor
status: active
created: 2026-02-25
updated: 2026-02-26
tags:
  - tess
  - openclaw
  - frontier
---

# Tess: Frontier Ideas — Beyond the Operational Baseline

## Premise

The capability spec covers what Tess *should* be doing based on proven patterns. This document covers what's possible that nobody has combined yet, and what's uniquely powerful about the Crumb + Tess + Claude triad.

Your edge isn't just OpenClaw. It's the *combination* of a structured Obsidian vault with governed workflows, a separate AI development environment (Crumb), a two-agent OpenClaw deployment, a bridge protocol between systems, a content intelligence pipeline, a professional domain where intelligence equals revenue, and a personal knowledge practice spanning seven life domains. Nobody else has this stack. These ideas exploit the intersections.

### Readiness Rubric

| Tier | Requirements |
|------|-------------|
| **READY** | Dependencies met, no new infrastructure, implementable with existing tools, success criteria definable |
| **DESIGN-NEEDED** | Concept validated, but requires: spec for output format, dependency resolution, cost/risk analysis, acceptance tests |
| **EXPLORATORY** | Concept stage only. Requires: manual pilot results, feasibility assessment, or upstream dependency resolution before promoting |
| **DEFERRED** | Use case validated but out of scope for tess-operations. Separate project or existing-tool solution noted. |

### Noise Budget

Every idea that emits output must define:
- Max messages/day it can produce
- Suppression trigger (e.g., 3 consecutive ignored outputs → reduce frequency)
- What counts as "actioned" (reply, archive, tag, promote, dismiss)

This turns frontier ideas from unbounded experiments into measurable bets.

### Revenue-Critical Classification

Ideas are classified by proximity to revenue-generating activity:

- **Revenue-critical:** Adversarial Pre-Brief, Follow-Through Engine, Relationship Tracking, Parallel Research Swarm
- **Operational improvement:** Self-Optimization Loop, Session Compaction, Proactive Skill Drafting, Secrets & Privacy Hygiene, Fact-Checking Sub-Agent
- **Personal/exploratory:** Knowledge Arbitrage, Attention Flywheel, Session Recorder

Revenue-critical ideas get priority when resources are constrained.

### Promoted to Baseline

The following ideas have been moved out of this document into the chief-of-staff operational spec (§14) based on peer review consensus:

- **Anticipatory Session** → chief-of-staff §14 Week 2+ item #5. Context injection schema defined. Unanimous reviewer consensus: highest-value idea, "connect existing dots" rather than frontier.
- **Dead Man's Switch** → chief-of-staff §14 Week 0 prerequisite. All reviewers agreed: mandatory infrastructure hygiene, not frontier. Dual-signal monitoring (gateway alive + job ran alive).

### See Also

- [[beyond-current-roadmap-research]] — 9 additional ideas that extend beyond this document's coverage (project stall detection, session retrospectives, voice calibration, decision journals, cross-domain bridging, tempo adaptation, live conversation memory, skill acquisition, degradation-aware routing).

---

## 1. Adversarial Pre-Brief [DESIGN-NEEDED] — Revenue-Critical

**Problem:** You're a solo SE going into meetings where customers have their own research, objections, and preferred competitors. Standard meeting prep builds a *supportive* brief. Nobody builds the adversarial one.

**Idea:** Tess doesn't just brief you on the customer. She prepares what they're likely to throw at you, based on:
- Recent technology announcements (from account intelligence)
- Competitor messaging they've likely seen
- Common objections for their industry vertical
- Their existing infrastructure (from dossier)
- Recent analyst reports framing the competitive landscape

**Output format (source-backed — every factual claim must carry evidence):**

```markdown
## Facts (cited)
- BorgWarner posted a job for "Network Automation Engineer" emphasizing Ansible/Terraform
  [source: LinkedIn, 2026-02-20]
- BlueCat released Terraform provider v2.3 with full DDI resource management
  [source: bluecatnetworks.com/blog, 2026-02-15]

## Hypotheses (labeled, with confidence and basis)
- HIGH CONFIDENCE: BorgWarner is evaluating programmable infrastructure vendors
  (Basis: job posting + existing Cisco DNA Center deployment from dossier)
- MEDIUM CONFIDENCE: BlueCat will lead with API-first positioning
  (Basis: recent messaging pattern, no direct evidence of BorgWarner engagement)

## Recommended Responses
- Pivot on automation: BloxOne's Terraform provider + cloud-first DDI integration
  that BlueCat can't match in hybrid deployments
- Prepare demo: show Ansible playbook for BloxOne provisioning (5-min live demo)
```

If no sources exist for a claim, the output must state "no evidence found" rather than generating plausible assertions. Hypotheses without basis are omitted, not fabricated.

**Dependencies:** Requires the competitive intelligence pipeline (customer-intelligence project) to be producing grounded data before this idea is viable.

**Noise budget:** Max 1 pre-brief per scheduled external meeting. Suppression: if pre-briefs are not opened for 3 consecutive meetings, pause and ask if the format needs adjustment.

---

## 2. Three-Body Protocol — Crumb, Tess, and Claude as a Triad [READY]

**Problem:** Three AI systems operate in isolation. Crumb (deep project work), Tess (operations), Claude (ad-hoc research). Each knows things the others don't.

**Idea:** Design explicit handoff protocols between all three:

**Claude → Vault → Tess:** End of a claude.ai research session, save deliverable to vault. Git webhook notifies Tess. She reads it, classifies it, and routes accordingly.

**Tess → Crumb:** Session context files (already in the capability spec, promoted to §14 Week 2+). But also: Tess can draft *project proposals* in Crumb's expected format (right frontmatter, right structure) and stage them.

**Crumb → Claude:** After a project milestone, Tess summarizes the journey and identifies open questions. These become seeds for the next claude.ai deep-research session.

**Tess → Claude → Tess loop:** Tess identifies a capability gap beyond her scope. Stages a research brief. You bring it to claude.ai. Output goes back to vault. Tess picks it up and implements.

**Architectural asymmetry:** Claude → Vault → Tess is automated (webhook). Vault → Claude requires human action (you bring the file to claude.ai). This is a fundamental constraint of the current architecture, not a bug.

**Handoff classification:** When Tess ingests a Claude output from the vault, she classifies it before routing:
- **Actionable** — stage as operational task in `_openclaw/inbox/`
- **Reference** — file in KB or project design dir, no action needed
- **Spec-impacting** — flag for Crumb review before any action (potential architecture/governance change)

Different classifications trigger different routing rules and urgency levels.

**Noise budget:** Handoff notifications are event-driven (git webhook), not scheduled. Max 1 notification per webhook event, suppressed if Danny is in an active Crumb session (detected via recent vault commits).

---

## 3. Parallel Research Swarm [DESIGN-NEEDED] — Revenue-Critical

**Problem:** Competitive intelligence for 25 accounts across multiple competitors is too broad for a single serial agent run.

**Idea:** Tess uses subagent spawning for parallel research:
- Spawn 3-5 subagents (not 25 — empirical evidence shows naive swarms don't outperform good single agents past this count), each researching one competitor or account batch
- When all complete, synthesize into a single competitive landscape brief
- Extend to accounts: batch 25 into groups of 5, run sequentially with subagent parallelism within each batch

**Cost:** Parallel Haiku subagents are ~$0.10-0.30 per run. Runtime dominated by I/O waits (rate limits, retries), not reasoning.

**Why DESIGN-NEEDED:** Subagent orchestration patterns need testing. How does Tess collect and synthesize results from multiple subagents? Does OpenClaw's `/subagents spawn` support this cleanly? Need to validate the mechanic before building the workflow.

**Swarm calibration (from peer review):** "24-hour agent swarms" are mostly I/O-bound pipelines with scheduling. The serious deployments look like heartbeat loops, overnight research, and morning briefing deliverables — which is what the chief-of-staff spec already designs. Don't chase swarm scale; execute existing patterns with durability.

**Noise budget:** Max 1 research swarm output per week (competitive landscape brief). Suppression: if brief is not acted on for 2 consecutive weeks, reduce to biweekly.

---

## 4. Crumb Session Recorder [EXPLORATORY] — Operational Improvement

**Problem:** Crumb sessions produce design decisions, architectural rationale, and problem-solving approaches. This intellectual output is trapped in project-specific run-logs. A brilliant insight in one project never surfaces in another.

**Recommended approach (synthesized from peer review — do not automate without manual validation):**

1. **Manual pilot first:** Run a one-off job on 3-5 past sessions, evaluate whether the output is actually worth keeping before building automation
2. **Human-facilitated capture:** Tess prompts at session end — "What's one architectural insight from today?" — then drafts a note from the response
3. **Strict schema:** Pattern name, short description, where it was applied, 1-2 references. Max 1 cross-project insight per session.
4. **Preview before KB promotion:** All candidate insights staged via Tess in `_openclaw/inbox/insight-<topic>-<date>.md` for review. Never auto-promoted to KB.

**Related work:** Peter O'Mallet's DataClaw ([github.com/peteromallet/dataclaw](https://github.com/peteromallet/dataclaw)) turns Claude Code conversation history into structured training data published to Hugging Face. 0xSero's ai-data-extraction ([github.com/0xSero/ai-data-extraction](https://github.com/0xSero/ai-data-extraction)) does similar extraction across multiple AI coding assistants.

**Why EXPLORATORY:** Automated insight extraction from diffs is hard, noisy, and likely to produce bland summaries without the manual pilot proving value first.

**Noise budget:** Max 1 insight candidate per Crumb session. Suppression: if 5 consecutive candidates are dismissed, pause and reassess prompt quality.

---

## 5. Attention Flywheel [EXPLORATORY] — Personal

**Problem:** Feed-intel, competitive intelligence, personal reading, and Crumb sessions are separate streams with no cross-pollination.

**Idea:** Tess maintains a running attention model — a structured file tracking what you've been paying attention to across all domains.

**Hard constraints (peer review consensus — pursue only with these guardrails):**
- **Single attention metric per topic:** 0-1 score based on promotions + research requests over trailing N days. No complex multi-dimensional scoring.
- **Single feedback point:** Sort feed-intel by attention weight, nothing else. No "central attention brain" that touches everything.
- **Explicit guardrails against reinforcing short-term obsessions:** Decay rate must be fast enough that a 2-week fixation doesn't permanently bias the system. Include a mandatory "diversity slot" in every feed-intel digest (1 item from lowest-attention topics).

**Why EXPLORATORY:** The implementation is non-trivial — how does an attention model concretely re-weight feed-intel scoring without gaming itself? Needs careful design of the feedback mechanism.

**Noise budget:** Attention model is an internal data structure, not a user-facing output. Impact is indirect (feed-intel sort order). No standalone messages.

---

## 6. Knowledge Arbitrage [EXPLORATORY] — Personal

**Problem:** You read widely across history, philosophy, and classic fiction. This personal knowledge never surfaces when it's professionally relevant.

**Idea:** When Tess prepares an account brief or competitive analysis, she also searches personal KB for relevant mental models.

**Example:** Prepping for a legacy DDI migration meeting. Tess surfaces your note on Chesterton's Fence: "Before migrating their legacy DDI, understand *why* their current system is configured as it is. Hidden dependencies are the #1 migration risk."

**Hard constraints (peer review consensus — high noise risk without these):**
- **Explicit opt-in per brief:** "Include mental models for this one" — not always-on
- **Curated model set:** Start with 5-10 broadly applicable mental models, not full KB search
- **Hard limit:** At most 1 KB-based mental model call-out per brief, only if high confidence
- **Kill criteria:** If call-outs are dismissed 5 consecutive times, disable and reassess relevance matching

**Why EXPLORATORY:** High risk of producing noise ("Proactive Clippy" per Gemini). The general case ("search personal KB for professional relevance") needs a precision mechanism. Worth testing manually before automating.

**Noise budget:** Max 1 call-out per brief, only when opt-in is active. Zero standalone messages.

---

## 7. Self-Optimization Loop [DESIGN-NEEDED] — Operational Improvement

**Problem:** As cron jobs, heartbeats, and workflows accumulate, Tess becomes a complex system. Who monitors the monitor's *effectiveness*?

**Idea:** Weekly self-assessment:
- Signal-to-noise ratio per cron job (how many outputs were acted on vs ignored?)
- Heartbeat check efficiency (always HEARTBEAT_OK = candidate for frequency reduction)
- Cost breakdown by job type
- Self-improvement proposals staged for approval

**Example proposal:** "Competitive intel for Men&Mice hasn't produced relevant findings in a month. Recommend pausing and reallocating to Palo Alto DNS Security."

**Feedback measurement (peer review guidance):** Use crude heuristics — did you reply? did you archive? did you promote? These are better than nothing. Measuring "was this acted on" precisely requires instrumenting responses to briefings, which is a Phase 2+ enhancement. Start with coarse signals.

**Ties to:** Anticipatory Session feedback loop (measuring which context sections Crumb references), Attention Flywheel (attention scores as optimization input).

**Noise budget:** Max 1 self-assessment report per week. Suppression: if weekly report produces no actionable recommendations for 3 consecutive weeks, switch to biweekly.

---

## 8. Follow-Through Engine [DESIGN-NEEDED] — Revenue-Critical

**Problem:** Meetings produce decisions, commitments, and next steps. These leak — follow-up emails don't get sent, calendar holds don't get created, action items don't get tracked. The current specs cover prep and monitoring but not the post-meeting follow-through loop.

**Concept:** A first-class loop for meeting outcomes:
1. **Capture:** Decisions made, next steps, commitments (from session debrief or manual input)
2. **Generate:** Draft follow-up emails (Google spec), calendar holds (Google spec), reminders (Apple spec)
3. **Close:** Accountability tracking — nag only when it matters, verify completion

**Flow:** meeting → commitments → reminders + drafts → verification → follow-up nag if incomplete

**Why it's high-value:** Revenue-adjacent. Reduces real-world leakage. Plugs directly into the Google spec (Calendar/Email) and Apple spec (Reminders). The current specs cover prep and monitoring but not the post-meeting follow-through loop.

**Dependencies:** Google services Phase 2+ (email drafting), Google services Phase 3 (calendar staging), Apple services Phase 2 (reminders write).

**Noise budget:** Follow-through items are event-driven (post-meeting). Max 1 nag per commitment per day. Suppression: commitment marked complete or explicitly deferred by Danny.

---

## 9. Relationship / Cadence Tracking [DESIGN-NEEDED] — Revenue-Critical

**Problem:** With ~25 accounts, important relationships go cold when you're heads-down on a project. There's no system tracking when you last engaged with key contacts.

**Concept:** Lightweight personal "keep warm" layer:
- Who you should contact weekly/monthly (customers, peers, internal stakeholders)
- Last-touch + next-touch tracking (derived from email/calendar data)
- "Stale relationship" alerts when cadence lapses

**Why it's not a CRM:** No pipeline stages, no deal tracking, no forecasting. Just a thin people-oriented layer that ensures important relationships don't go cold.

**Dependencies:** Google services integration (email/calendar data for last-touch signals), possibly Apple Contacts (for the people index).

**Noise budget:** Max 1 "stale relationship" alert per day (batched). Suppression: if all relationships are within cadence, no message. If Danny dismisses alerts for a specific contact 3 times, extend that contact's cadence window.

---

## 10. Proactive Skill Drafting [DESIGN-NEEDED] — Operational Improvement

**Problem:** Chief-of-staff Open Question #5: "If Tess writes her own skills, what's the review process?"

**Concept:** When Tess identifies a task she's performed manually 3+ times that follows a repeatable pattern, she drafts a candidate OpenClaw skill and stages it for review.

**Flow:**
1. Tess detects repeated manual pattern (e.g., DDI lookup via shell commands)
2. Drafts a skill file in `_openclaw/staging/`
3. Sends Telegram notification with description and rationale
4. Danny reviews, approves/rejects
5. If approved, Tess installs within her workspace

**Constraints:** Strict approval gate (no self-installation), code review required, sandbox testing before production use.

**Noise budget:** Max 1 skill proposal per week. Suppression: if 3 consecutive proposals are rejected, pause for 30 days and reassess detection criteria.

---

## 11. Fact-Checking Sub-Agent [DESIGN-NEEDED] — Operational Improvement

**Problem:** Outbound drafts and competitive briefs may contain factual claims that haven't been verified.

**Concept:** A dedicated cheap checker agent (planner → worker → checker pattern) that validates claims in outbound content against docs/web before anything touches external recipients.

**Use case:** Before Tess proposes a sensitive email send or surfaces a competitive claim in a brief, the checker verifies factual assertions and flags dubious statements.

**Distinct from Adversarial Pre-Brief:** The pre-brief *generates* claims. The checker *validates* claims. These are different capabilities that work in series.

**Noise budget:** Checker runs silently on applicable outputs. Only surfaces findings when it detects a factual issue. Max 1 flagged-claims notification per output reviewed.

---

## 12. Session Compaction for Project History [EXPLORATORY] — Operational Improvement

**Problem:** Recurring Crumb projects require re-deriving context from run-logs each time. This works but is slow and may miss nuance.

**Concept:** Maintain a compacted "project history" transcript that Tess can inject into future sessions — instead of re-deriving context from run-logs each time.

**Distinction from Anticipatory Session:** The Anticipatory Session (now in chief-of-staff §14 Week 2+) is a *per-session* context file assembled on demand. Session compaction is a *persistent* project memory that grows and condenses over time.

**Why EXPLORATORY:** Needs design work on compaction strategy (what to keep, what to discard, how to prevent unbounded growth). Also depends on OpenClaw's session-management primitives, which need validation.

**Noise budget:** No user-facing output. Compaction runs silently after session debrief. Produces an updated file in `_openclaw/state/`.

---

## 13. Secrets & Privacy Hygiene [Standing Capability] — Operational Improvement

**Problem:** Content flows across Telegram, Discord, and into LLM prompts. API keys, tokens, credentials, and PII may appear in staged outputs and logs.

**Concept:**
- Automated scanning for secrets (API keys, tokens, credentials) in staged outputs and logs
- Redaction policy for briefings (what gets summarized vs. quoted, PII handling)
- "Never send outside" enforcement layer for sensitive content categories

**Why it's a standing capability, not a frontier idea:** Like the Dead Man's Switch, this is operational hygiene. It belongs in the security model but is currently missing from all specs.

**Noise budget:** Runs silently on all outbound content. Only surfaces findings when a secret or PII is detected. Max 1 alert per output reviewed.

---

## 14. Voice Capture Interface [DEFERRED]

**Problem:** Ideas and observations throughout the day are lost when you can't type (driving, walking).

**Status:** Reclassified from EXPLORATORY to DEFERRED. The use case is real but the solution belongs outside tess-operations.

**Existing-tool pivots (no new infrastructure needed):**
- **Option A:** iOS Voice Memos → iCloud folder. Tess polls the folder and transcribes. Zero new infrastructure.
- **Option B:** Drafts app as quick-capture inbox with voice transcription. Tess ingests from Drafts export.

Both options feed into `_openclaw/inbox/` through the existing Apple services iCloud Drive integration (Apple spec §3.6).

**If pursued:** Separate project. Depends on Apple services Phase 1 (iCloud Drive read) being operational first.

---

## The Organizing Principle

All of these share a single thesis: **Tess should not be a tool you use. She should be a system that operates.**

A tool waits for invocation. A system runs whether you're paying attention or not, and improves over time because it learns from its own operations.

The frontier isn't "what can Tess do when I ask her." It's "what has Tess already done by the time I sit down."

The operational baseline (capability spec) is table stakes. These frontier ideas are the differentiators. Build the basics first, then layer in the READY items, then design-spec the DESIGN-NEEDED ones, then revisit EXPLORATORY after six months of operational data.

**Sequencing guidance:** Revenue-critical ideas (Adversarial Pre-Brief, Follow-Through Engine, Relationship Tracking, Parallel Research Swarm) get priority when baseline is stable. Operational improvements layer in as capacity allows. Personal/exploratory ideas are experiments — treat them as measured bets with kill criteria.

---

## Appendix: Peer Review Calibration — "24-Hour Agent Swarms"

Supplementary context from the peer review panel on what long-running agent deployments actually look like in practice.

**What "24-hour swarms" actually are (consensus across all 4 reviewers):**

1. **Always-on ops/monitoring loops** — Cron and heartbeat agents. Individual LLM calls are short; the "24 hours" is scheduling + state management. This is what the chief-of-staff spec already designs.
2. **I/O-bound research/content pipelines** — Agents that crawl, search, summarize. Duration comes from rate limits and retries, not continuous reasoning. A pipeline that "ran overnight" typically did 30-60 minutes of actual LLM work.
3. **Role-specialized pipelines marketed as "swarms"** — 3-8 agents with narrow roles passing artifacts in sequence. Orchestrated pipeline execution, not a swarm.

**Key empirical findings:**
- Naive swarms don't outperform good single agents once you account for handoff overhead
- Context drift is a real failure mode for agents running 100+ steps
- The real engineering is durability (checkpointing, pause/resume, error recovery), not autonomy
- "Zero human" swarms are still rare — almost all serious deployments have human curation gates

**Bottom line:** The tess-operations architecture is already the disciplined version of what the hype cycle is selling. Don't chase swarm scale — execute existing patterns with durability and constraint rigor.
