---
project: tess-operations
type: review-synthesis
domain: software
created: 2026-02-26
updated: 2026-02-26
status: active
tags:
  - tess
  - peer-review
  - frontier-ideas
---

# Tess Frontier Ideas — Peer Review Synthesis

Consolidated findings from 4 independent peer reviews of `tess-frontier-ideas.md`. Reviews conducted by DeepSeek, Gemini, ChatGPT, and Perplexity. Synthesis prepared by Claude Opus with editorial filtering for hallucination risk, signal quality, and alignment with existing spec content.

## Review Quality Assessment

| Reviewer | Signal Quality | Key Strength | Key Weakness |
|----------|---------------|--------------|--------------|
| DeepSeek | Medium-high | Grounding problems (adversarial pre-brief, session recorder) | "Build immediately" urgency ignores project workflow; heavyweight research patterns (Elo/tournaments) |
| Gemini | Medium | Noise identification (Knowledge Arbitrage as "Proactive Clippy") | One new idea is a privacy overreach (Vibe Check); shallow on implementation |
| ChatGPT | High | Best new ideas (follow-through engine, relationship tracking); structural improvements (noise budgets, readiness rubric) | Minor: risk register idea overlaps intelligence layer |
| Perplexity | High | Best triage framework; practical pivots (Voice Memos, session compaction); operational grounding | Some external references need verification |

---

## Part 1 — Consensus Findings on Existing Ideas

Findings where 2+ reviewers independently converge, verified against the actual spec text.

### Idea 1: Anticipatory Session [READY] — Unanimous: highest-value idea

All four reviewers rank this #1. No disagreement on value or feasibility.

**What the spec already covers well:** The flow (§1, steps 1-7), the extension (post-commit webhook for session exit summaries), and the rationale (two-system architecture creates a unique handoff surface).

**Gaps identified by reviewers:**

| Gap | Raised by | Assessment |
|-----|-----------|------------|
| No schema for the injected context file | ChatGPT, DeepSeek | **Valid.** The spec describes *what* Tess reads and *that* she writes a file, but not the file's structure. Without a defined schema (sections, max tokens, link policy, unknowns list, "suggested next command"), the output will be unstructured prose of varying quality. |
| No feedback loop (which parts of staged context were actually used?) | DeepSeek | **Valid but Phase 2.** Measuring which context sections Crumb actually referenced requires instrumentation that doesn't exist yet. Note as a future enhancement, not a pre-build requirement. |
| Should be promoted to baseline, not frontier | Perplexity | **Agree.** This is "connect existing dots" using the bridge, vault, and run-logs. It belongs in the chief-of-staff roadmap (Week 2+ candidates) rather than a frontier ideas doc. |

**Recommended changes:**
1. Add a context injection schema to §1: required sections (current phase, next task, blockers, recent dispatch results, relevant feed-intel, vault-check status), max token target, wikilink conventions
2. Move from frontier ideas to chief-of-staff spec §14 Week 2+ priority list
3. Note feedback loop as a future enhancement (ties to Self-Optimization Loop, idea #10)

### Idea 2: Adversarial Pre-Brief [DESIGN-NEEDED] — Consensus: ground it or it's hallucination bait

Three reviewers (DeepSeek, ChatGPT, Perplexity) independently flag the same core problem.

**What the spec already covers well:** The concept, the example output, the illustrative Lobster workflow, and the explicit acknowledgment that it "needs careful prompt engineering to avoid hallucinated competitor claims."

**Gap:** The spec identifies the risk but doesn't specify the mitigation. The example output ("BlueCat's latest messaging emphasizes API-first DDI") is exactly the kind of claim that could be fabricated without source grounding.

**Recommended changes:**
1. Define a source-backed output format. Every factual claim must carry a URL + date. Hypotheses must be explicitly labeled as such. If no sources exist for a claim, the output must state "no evidence found" rather than generating plausible assertions.
2. Restructure the output template into three sections: **Facts** (cited), **Hypotheses** (labeled, with confidence and basis), **Recommended responses** (tied to your product strengths)
3. Add a dependency note: requires the competitive intelligence pipeline (customer-intelligence project) to be producing grounded data before this idea is viable

### Idea 3: Three-Body Protocol [READY] — Consensus: high value, needs handoff classification

**What the spec already covers well:** The four handoff directions (Claude→Tess, Tess→Crumb, Crumb→Claude, Tess→Claude→Tess loop), the mechanism (vault as shared surface, git webhook as trigger), and the rationale.

**Gaps identified by reviewers:**

| Gap | Raised by | Assessment |
|-----|-----------|------------|
| Directionality: Claude→Tess is automated, Tess→Claude requires manual paste into claude.ai | DeepSeek | **Valid.** The protocol is actually Claude ↔ Vault ↔ Tess, not Claude ↔ Tess directly. Name this honestly. |
| Handoff acceptance criteria: Tess should classify Claude outputs as actionable / reference / spec-impacting with different routing rules | ChatGPT | **Valid.** Without classification, everything gets the same treatment. Different output types need different routing. |

**Recommended changes:**
1. Acknowledge the asymmetry: Claude→Vault→Tess is automated (webhook). Vault→Claude requires human action (you bring the file to claude.ai). This is a fundamental constraint of the current architecture, not a bug.
2. Define handoff classification: when Tess ingests a Claude output from the vault, she tags it as `actionable` (stage as operational task), `reference` (file in KB, no action needed), or `spec-impacting` (flag for Crumb review). Routing rules differ per classification.

### Idea 4: Dead Man's Switch [READY] — Consensus: mandatory infrastructure, not frontier

All four reviewers agree this is a 5-minute setup that belongs in the operational baseline.

**What the spec already covers well:** The solution (external heartbeat ping), the extension (recovery state file), and the rationale.

**Gap:** Classification. This isn't a frontier idea — it's infrastructure hygiene.

**Recommended changes:**
1. Move to chief-of-staff spec §14 Week 0 as a required item alongside the OpenClaw upgrade
2. Per Perplexity: monitor two signals, not one — (a) gateway alive, (b) "job ran" alive. A system can be "up" but frozen.
3. Remove from frontier ideas doc (or replace with a pointer to its new location)

### Idea 9: Voice Capture Interface [EXPLORATORY] — Consensus: wrong layer, pivot to existing tools

All four reviewers agree this is a separate project, not a Tess feature. But the use case (capturing ideas when you can't type) is real.

**Recommended pivot (two options, both raised by reviewers):**
- **Option A (Perplexity):** iOS Voice Memos → iCloud folder. Tess polls the folder and transcribes. Zero new infrastructure.
- **Option B (ChatGPT):** Drafts app as quick-capture inbox with voice transcription. Tess ingests from Drafts export.

**Recommended change:** Reclassify from EXPLORATORY to "Deferred — separate project." Add a note that the use case can be served by existing tools feeding into `_openclaw/inbox/` without building a custom voice stack.

### Ideas 7 & 8: Attention Flywheel & Knowledge Arbitrage [EXPLORATORY] — Consensus: high noise risk, needs hard constraints

All four reviewers flag these as cool concepts with serious noise/filter-bubble problems. The spec already acknowledges both risks.

**Recommended constraints if pursued (synthesized across reviewers):**

**Attention Flywheel:**
- Single attention metric per topic: 0-1 score based on promotions + research requests over trailing N days (Perplexity)
- Single feedback point: sort feed-intel by attention weight, nothing else. No "central attention brain" that touches everything (Perplexity)
- Explicit guardrails against reinforcing short-term obsessions (ChatGPT)

**Knowledge Arbitrage:**
- Explicit opt-in per brief ("include mental models for this one"), not always-on (Perplexity)
- Start with a curated set of broadly applicable mental models (5-10 max), not full KB search (DeepSeek, Perplexity)
- Hard limit: at most 1 KB-based mental model call-out per brief, only if high confidence (Perplexity)

### Idea 6: Crumb Session Recorder [EXPLORATORY] — Consensus: don't automate yet

All four reviewers converge on the same conclusion: automated insight extraction from git diffs is hard, noisy, and likely to produce bland summaries. The spec already flags this risk.

**Recommended approach (synthesized):**
- **Manual pilot first** (Perplexity): run a one-off job on 3-5 past sessions, evaluate whether the output is actually worth keeping
- **Human-facilitated capture** (DeepSeek): Tess prompts at session end — "What's one architectural insight from today?" — then drafts a note from the response
- **Strict schema** (ChatGPT, Perplexity): pattern name, short description, where it was applied, 1-2 references. Max 1 cross-project insight per session.
- **Preview before KB promotion** (Perplexity): all candidate insights staged via Tess for review, never auto-promoted

---

## Part 2 — New Ideas Worth Adding

Ideas proposed by reviewers that aren't in the current frontier doc. Filtered to exclude scope creep, privacy overreach, and generic advice.

### NEW: Follow-Through Engine [DESIGN-NEEDED]

**Raised by:** ChatGPT
**Assessment:** Highest-value new idea across all reviews.

**Concept:** A first-class loop for meeting outcomes:
- Capture: decisions made, next steps, commitments
- Generate: draft follow-up emails, calendar holds, reminders
- Close: accountability tracking — nag only when it matters, verify completion

**Flow:** meeting → commitments → reminders + drafts → verification

**Why it's high-value:** Revenue-adjacent, reduces real-world leakage, and plugs directly into the Google spec (Calendar/Email) and Apple spec (Reminders). The current specs cover prep and monitoring but not the post-meeting follow-through loop.

**Why it belongs in this doc:** It's not part of the operational baseline (which is about infrastructure health and proactive intelligence). It's a capability that requires the baseline to be running first (needs email drafting, calendar staging, and reminders integration).

### NEW: Relationship / Cadence Tracking [DESIGN-NEEDED]

**Raised by:** ChatGPT
**Assessment:** High-value, directly relevant to SE role with ~25 accounts.

**Concept:** Lightweight personal "keep warm" layer:
- Who you should contact weekly/monthly (customers, peers, internal stakeholders)
- Last-touch + next-touch tracking
- "Stale relationship" alerts when cadence lapses

**Why it's not a CRM:** No pipeline stages, no deal tracking, no forecasting. Just a thin people-oriented layer that ensures important relationships don't go cold because you're heads-down on a project.

**Dependencies:** Google services integration (email/calendar data for last-touch signals), possibly Apple Contacts (for the people index).

### NEW: Proactive Skill Drafting [DESIGN-NEEDED]

**Raised by:** Gemini
**Assessment:** Medium-high value, directly addresses chief-of-staff Open Question #5 ("If Tess writes her own skills, what's the review process?").

**Concept:** When Tess identifies a task she's performed manually 3+ times that follows a repeatable pattern, she drafts a candidate OpenClaw skill and stages it for review.

**Flow:**
1. Tess detects repeated manual pattern (e.g., DDI lookup via shell commands)
2. Drafts a skill file in `_openclaw/staging/`
3. Sends Telegram notification with description and rationale
4. You review, approve/reject, and if approved, Tess installs

**Constraints needed:** Strict approval gate (no self-installation), code review required, sandbox testing before production use.

### NEW: Fact-Checking Sub-Agent [DESIGN-NEEDED]

**Raised by:** Perplexity
**Assessment:** Medium-high value, natural extension of adversarial pre-brief grounding.

**Concept:** A dedicated cheap checker agent (planner → worker → checker pattern) that validates claims in outbound drafts against docs/web before anything touches external recipients.

**Use case:** Before Tess proposes a sensitive email send or surfaces a competitive claim in a brief, the checker verifies factual assertions and flags dubious statements.

**Why it's distinct from the adversarial pre-brief:** The pre-brief generates claims. The checker *validates* claims. These are different capabilities that work in series.

### NEW: Session Compaction for Project History [EXPLORATORY]

**Raised by:** Perplexity
**Assessment:** Medium value, extends the Anticipatory Session concept.

**Concept:** For recurring Crumb projects, maintain a compacted "project history" transcript that Tess can inject into future sessions — instead of re-deriving context from run-logs each time.

**Distinction from Anticipatory Session:** The anticipatory session is a *per-session* context file assembled on demand. Session compaction is a *persistent* project memory that grows and condenses over time.

**Why EXPLORATORY:** Needs design work on compaction strategy (what to keep, what to discard, how to prevent unbounded growth). Also depends on OpenClaw's session-management primitives, which need validation.

### NEW: Secrets & Privacy Hygiene [Standing Capability]

**Raised by:** ChatGPT
**Assessment:** Medium-high value, infrastructure-grade concern.

**Concept:** Given content flowing across Telegram, Discord, and into LLM prompts:
- Automated scanning for secrets (API keys, tokens, credentials) in staged outputs and logs
- Redaction policy for briefings (what gets summarized vs. quoted, PII handling)
- "Never send outside" enforcement layer for sensitive content

**Why it's not frontier:** Like the Dead Man's Switch, this is operational hygiene. It could live in the chief-of-staff spec's security section (§12) rather than the frontier doc. But it's currently missing from both places.

---

## Part 3 — Structural Improvements to the Document

Recommendations for making the frontier ideas doc itself more rigorous.

### 3.1 Readiness Rubric

**Raised by:** ChatGPT
**Assessment:** High value.

The current READY / DESIGN-NEEDED / EXPLORATORY tiers are useful but undefined. Add explicit criteria:

| Tier | Requirements |
|------|-------------|
| READY | Dependencies met, no new infrastructure, implementable with existing tools, success criteria definable |
| DESIGN-NEEDED | Concept validated, but requires: spec for output format, dependency resolution, cost/risk analysis, acceptance tests |
| EXPLORATORY | Concept stage only. Requires: manual pilot results, feasibility assessment, or upstream dependency resolution before promoting |

Per idea, add: dependencies, required instrumentation, success criteria, failure modes, kill criteria (when to stop).

### 3.2 Noise Budget

**Raised by:** ChatGPT
**Assessment:** High value.

Every idea that emits output should define:
- Max messages/day it can produce
- What triggers suppression (e.g., 3 consecutive ignored outputs → reduce frequency)
- What counts as "actioned" (reply, archive, tag, promote, dismiss)

This turns frontier ideas from unbounded experiments into measurable bets.

### 3.3 Revenue-Critical vs. Nice-to-Have Classification

**Raised by:** ChatGPT
**Assessment:** Medium value.

Add a dimension beyond maturity tier: does this idea directly support revenue-generating activity (customer meetings, account management, pipeline health) or is it operational/personal improvement?

Revenue-critical ideas get priority when resources are constrained:
- **Revenue-critical:** Anticipatory Session, Adversarial Pre-Brief, Follow-Through Engine, Relationship Tracking, Parallel Research Swarm
- **Operational improvement:** Dead Man's Switch, Self-Optimization Loop, Session Compaction, Secrets Hygiene
- **Personal/exploratory:** Knowledge Arbitrage, Attention Flywheel, Voice Capture, Session Recorder

---

## Part 4 — Ideas Reviewed and Rejected

New ideas proposed by reviewers that were evaluated and excluded from recommendations.

| Proposed Idea | Reviewer | Reason for Exclusion |
|---------------|----------|---------------------|
| AI Colleague Interface (Tess as team resource) | DeepSeek | Fundamentally changes Crumb's scope from personal OS to team tool. Breaks permission model, privacy boundaries, and governance assumptions. |
| Consulting Arbitrage Layer (YAML framework evaluation) | DeepSeek | Generic "use structured evaluation criteria" advice dressed up as a frontier idea. Not specific to the stack. |
| "Vibe Check" (emotional/cognitive load monitoring) | Gemini | Privacy overreach. Monitoring message "tone" to assess stress levels and recommend skipping sessions crosses a boundary that an autonomous agent shouldn't approach. Also assumes iMessage read access (Phase 3+). |
| Adversarial Mirror / Phishing Firewall (cross-reference iMessage + email) | Gemini | Technically unsound. Absence of recent contact is a terrible phishing heuristic. The Google spec's `@Risk/High` label filter handles this better. Creates false sense of security. |
| Tournament-based Elo ranking for research synthesis | DeepSeek | Heavyweight overkill. Pairwise comparison tournaments are designed for scientific discovery pipelines, not a solo SE triaging feed-intel. |
| Lobster as mandatory for all mutation tasks | Gemini | Directly contradicts the spec's correct caution about Lobster maturity. Based on a fabricated "Typed Deterministic Workflows" industry trend. |

---

## Part 5 — Verified & Unverified Claims

Independent verification conducted against primary sources where feasible. Claims from the operational spec reviews that also affect frontier ideas are cross-referenced here.

### Confirmed Real (via independent research)

| Claim | Reviewer | Verification | Frontier Ideas Impact |
|-------|----------|-------------|----------------------|
| BlueBubbles recommended over `imsg` | DeepSeek, Gemini, Perplexity | OpenClaw docs explicitly deprecate `imsg`, recommend BlueBubbles as bundled plugin with REST API, webhooks, tapbacks, group chat | Voice Capture pivot (idea #9): if iMessage becomes an input channel, BlueBubbles is the path. Not relevant to frontier ideas directly but good context. |
| CVE-2025-43530 (TCC bypass via AppleScript) | Gemini | Real CVE, patched macOS 26.2. Allows silent TCC bypass via VoiceOver framework. | Reinforces conservative approach to Apple automation in any frontier idea that touches Apple services. Verify Studio Mac is on macOS 26.2+. |

### Not Verified (kept for awareness)

| Claim | Reviewer | Status |
|-------|----------|--------|
| OpenClaw issue #4555 (Discord bot can't receive messages) | Perplexity | Not searched. The recommendation (fallback paths for Discord interactive flows) is sound regardless. |
| `docs.openclaw.ai/reference/session-management-compaction` | Perplexity | Not searched. Relevant to Session Compaction idea — verify if that idea is promoted to DESIGN-NEEDED. |
| Manus deploying "100+ parallel agents" | DeepSeek | Likely embellished. General point (parallel research becoming common) is valid. |
| AI CoScientist tournament-based selection | DeepSeek | Probably real but Elo-rating specifics may be exaggerated. Irrelevant — excluded from recommendations. |
| KDDI "85% of employees more candid with AI" | DeepSeek | Likely hallucinated number. Used to support the rejected AI Colleague idea. |

### Confirmed Hallucinated

| Claim | Reviewer | Result |
|-------|----------|--------|
| `bbgun` npm package | DeepSeek | Does not exist. BlueBubbles integration is native to OpenClaw as a bundled plugin. |

---

## Part 6 — "24-Hour Agent Swarm" Calibration

A supplementary question was put to all four reviewers: "What are people actually doing when they claim to run agent swarms for 24+ hours?" The responses provide useful background calibration for the Parallel Research Swarm (idea #5), the Self-Optimization Loop (idea #10), and the overall ambition level of the frontier ideas doc.

### What "24-hour swarms" actually are

All four reviewers converge on the same demystification. The signal collapses into three patterns:

1. **Always-on ops/monitoring loops** — Cron and heartbeat agents that check services, watch queues, and produce digests. Any individual LLM call is short; the "24 hours" is scheduling + state management, not continuous reasoning. This is what your chief-of-staff spec already designs.

2. **I/O-bound research/content pipelines** — Agents that crawl, search, summarize, deduplicate, and produce reports. Duration comes from rate limits, retries, and external API waits — not from 24 hours of thinking. A pipeline that "ran overnight" typically did 30-60 minutes of actual LLM work spread across hours of waiting (ChatGPT).

3. **Role-specialized pipelines marketed as "swarms"** — 3-8 agents with narrow roles (researcher → analyst → writer → editor) passing artifacts in sequence. Frameworks like CrewAI formalize this as Agents + Tasks + Crews. It's orchestrated pipeline execution, not a swarm in any meaningful sense.

### Key empirical findings

- **Naive swarms don't outperform good single agents** once you account for handoff overhead and coordination errors. Swarms only win when: (a) the task is wide and parallelizable, (b) agents have narrow, well-defined roles with clear interfaces, and (c) you care about throughput/coverage more than single-task latency (Perplexity, citing LangChain multi-agent benchmarks).

- **"25 agents working simultaneously" usually means** a handful doing useful work at any moment with the rest idle or waiting (Perplexity). Social media posts rarely mention the failure/retry noise.

- **"Zero human" swarms are still rare.** Almost all serious deployments have humans defining tasks, curating outputs, and intervening on failures (ChatGPT, Perplexity).

- **Context drift** is a real failure mode for agents running 100+ steps — the agent forgets the original goal and wanders (Gemini). This is relevant to any long-running Lobster workflow or overnight research job.

- **The real engineering is durability, not autonomy** — checkpointing, pause/resume, error recovery, and human-in-the-loop gates matter more than raw runtime (ChatGPT, Perplexity). Modern production frameworks (LangGraph) emphasize "durable execution" over continuous autonomy.

### Implications for frontier ideas

| Frontier Idea | Implication |
|---------------|-------------|
| Parallel Research Swarm (#5) | Justified — competitive intel across 25 accounts is wide, parallelizable, with narrow per-account roles. But expect runtime dominated by I/O waits, not reasoning. Budget for rate limits and retries, not compute. Cap at 3-5 subagents, not 25. |
| Self-Optimization Loop (#10) | The "measure what was acted on" problem is the same challenge every long-running agent system faces. Crude heuristics (did you reply? did you archive?) are better than nothing, per Perplexity. |
| Overnight research queue | Already the non-hype version of what people are showing off. Your morning briefing pattern (overnight work → deliverable at 9 AM) is exactly what the serious deployments look like. |
| Lobster workflows | Context drift risk is real for multi-step workflows. Reinforces the spec's existing caution (§7: experimental only). Any workflow >5 steps should checkpoint intermediate state and be idempotent. |

### What you don't need

- Huge unconstrained swarms ("25 agents for 24 hours") — the empirical evidence says this is fragile and wasteful
- "Vibe coding" / autonomous overnight product builds — your code-review skill with multi-tier validation exists precisely because automated output needs human verification
- Content factory patterns (SEO generation, multi-platform variant production) — irrelevant to your use case

### Bottom line

Your architecture is already the disciplined version of what the hype cycle is selling. Heartbeat loops, overnight research, morning briefing deliverables, approval gates, and phased capability expansion are what the serious deployments actually look like once you strip away the social media packaging. The frontier ideas doc doesn't need to chase swarm scale — it needs to execute the patterns it already describes with the durability and constraint rigor that the real-world evidence demands.

---

## Recommended Action Sequence

1. **Promote to baseline:** Move Anticipatory Session and Dead Man's Switch out of frontier ideas into chief-of-staff spec §14 (Week 2+ and Week 0 respectively)
2. **Add context injection schema** to Anticipatory Session before implementation
3. **Ground the Adversarial Pre-Brief** with the source-backed output format (facts/hypotheses/responses structure)
4. **Add handoff classification** to Three-Body Protocol (actionable/reference/spec-impacting)
5. **Add new ideas:** Follow-Through Engine, Relationship Tracking, Proactive Skill Drafting, Fact-Checking Sub-Agent, Secrets & Privacy Hygiene
6. **Add structural improvements:** Readiness rubric, noise budgets, revenue-critical classification
7. **Tighten constraints** on Attention Flywheel and Knowledge Arbitrage per reviewer consensus before any future implementation
8. **Reclassify Voice Capture** as deferred/separate project with existing-tool pivot noted
