---
project: opportunity-scout
domain: software
type: specification
skill_origin: inbox-processor
created: 2026-03-14
updated: 2026-03-14
tags:
  - draft
---

# Opportunity Scout — Capability Spec v2

**Project:** Opportunity Scout  
**Classification:** Internal • Danny + Crumb/Tess  
**Date:** March 2026  
**Status:** DRAFT (post peer review)  
**Parent doc:** side-hustle-research-brief-v0.5.md  
**Peer reviewers:** Gemini, DeepSeek, ChatGPT, Perplexity

---

## 1. Mission

Continuously scan the opportunity landscape for income-generating, skill-building, or creatively fulfilling side ventures that match Danny's profile. Surface high-signal candidates with enough context to evaluate quickly. Never stop scanning, even during active execution of committed streams.

> The scarce resource is not opportunities. The scarce resource is opportunities that are automatable, legal, non-slimy, conflict-safe, and reachable through plausible distribution.

**Ultimate success metric:** Within 90 days of steady-state operation, Scout has surfaced at least one opportunity that Danny acted on and would not have found otherwise.

**Primary failure mode to guard against:** A highly polished, always-on idea firehose that Danny learns to ignore. Every design decision below is tested against this risk.

---

## 2. Operating Model

Tess runs Scout Mode autonomously on a daily cadence. Danny reviews the digest each morning. Monthly evaluation cycles determine whether to add, pivot, or kill Execute Mode streams.

### Core Loop

```
SCAN → SCORE → DEDUPE → DIGEST → REVIEW → (monthly) EVALUATE
```

1. **SCAN:** Tess monitors configured signal sources for new opportunities, market shifts, and changes to active stream landscapes.
2. **SCORE:** Each candidate is scored against the triage gates (Section 5). Only items meeting the signal threshold proceed.
3. **DEDUPE:** Items are checked against the candidate registry (Section 6). Repeated sightings of the same pattern update the existing record rather than creating new entries.
4. **DIGEST:** Tess produces a daily digest summarizing high-signal items with scoring rationale, confidence, evidence grade, and links.
5. **REVIEW:** Danny reviews the digest and responds with feedback commands (Section 7).
6. **EVALUATE:** Monthly, Danny and Claude review the accumulated bookmarked/flagged items and assess whether the current portfolio allocation should change.

### Digest Cadence

- **Daily digest:** Default starting cadence. Tess delivers each morning.
- **Threshold-based delivery:** During M0-M2 pilot, Tess scans daily but only delivers a digest when items clear the triage threshold. This prevents empty or near-empty digests from training Danny to skip the review.
- **Adaptive adjustment:** If daily volume is consistently low-signal (<2 items/day for 2+ weeks), shift to every-other-day or weekly. If volume spikes (major market shift, new platform launch), Tess can push an ad-hoc alert outside the normal cadence.
- **Monthly evaluation memo:** Separate from daily digests. A structured summary of the month's signals, trends, bookmarked items, and recommended portfolio actions.

### Delivery

- **Primary channel:** Telegram (canonical — all feedback captured here)
- **Mirror channel:** Discord (read-only mirror of digest)
- **Format:** Structured text digest. Each item gets: one-line summary, signal source, triage gate scores, confidence grade, evidence grade, key insight, and link.
- **Length target:** Designed to be reviewed thoughtfully in 10-15 minutes. This is Danny's daily strategic briefing, not a quick glance. If it consistently takes longer than 15 minutes, either signal threshold is too low or items need tighter writing. If it consistently takes under 5 minutes, either sources are too narrow or the threshold is too aggressive.

### Review Throttles

To prevent Scout from becoming a distraction engine:

- **Max 1 research dispatch per day.** If multiple items warrant research, queue them and release one per day.
- **Max 5 items flagged for evaluation per month.** Forces prioritization rather than accumulation.
- **Monthly evaluation takes no more than 30 minutes.** If it takes longer, the system is surfacing too much noise or the memo needs tighter synthesis.

---

## 3. Scope — What Scout Mode Scans For

### M0-M2 Focus Constraint

During the pilot phase, Scout is biased toward opportunities in three domains where Danny has existing assets and expertise:

1. Infrastructure / DDI / DNS / network security (excluding same-domain competitive activities)
2. AI / LLM / agent tooling and automation
3. Content and products that leverage the existing book/vault/design pipelines

This constraint reduces noise while the triage scoring is being calibrated. After M2 validation, the aperture can be widened deliberately.

### Primary Scan Categories

**1. New opportunity patterns**
Emerging models for generating income, building equity, or creating value. Not limited to the seven vectors already researched — any pattern that could score well against the evaluation framework qualifies. This is deliberately broad in principle, constrained in practice by the M0-M2 focus and the triage gates.

**2. Active stream landscape changes**
Market shifts, policy changes, new competitors, or platform developments relevant to committed or parked Execute Mode streams. This is the "protect what we're building" function — making sure external changes don't blindside active projects.

**3. Emerging platforms and marketplaces**
New distribution channels for digital goods, knowledge products, content, tooling, or services. Especially platforms that reduce friction for solo operators, offer novel reach, or create new product categories.

**4. Demand signals across Danny's expertise domains**
Opportunities matching Danny's profile appearing on freelance platforms, community discussions, job boards, or RFP channels. Not to auto-apply — to surface for evaluation. Also includes indirect demand signals: recurring complaints, underserved niches, "someone should build this" posts, and gaps between what exists and what people need.

### Exclusion Criteria

Scout Mode does NOT surface:
- Opportunities requiring significant upfront capital (>$5K) without strong justification
- MLM, dropshipping, or other models that fail the "non-slimy" test
- Opportunities that would clearly fail the conflict-safety test (see Governance Rules, Section 8)
- Get-rich-quick patterns or hype-cycle plays without durable fundamentals
- Anything requiring Danny to become a full-time content creator or abandon the automation-first principle
- Previously rejected opportunity categories listed in the Graveyard (Section 6)

---

## 4. Signal Sources

Signal sources are organized by the *type of signal* they produce, not by specific domains. The goal is to cast a wide net — domain-specific monitoring for active streams is a subset, not the primary architecture.

### M0 Starting Set (3-5 sources per tier)

During pilot, start with a deliberately small source set. Expand only after triage calibration proves the filtering works.

**Tier 1 — Opportunity Pattern Sources (monitor daily)**

| Source Type | M0 Starting Sources | What to Watch For |
|-------------|-------------------|-------------------|
| Builder communities | Hacker News (Show HN), IndieHackers revenue milestones | Validated patterns with real revenue data and operational models that are plausibly automatable |
| Solo operator case studies | Starter Story, IndieHackers interviews | Revenue data, time-to-revenue, operational realities |
| Creator economy trackers | Beehiiv blog, newsletter operator communities | Shifts in content monetization, new formats |

**Tier 1 filter:** Items from Tier 1 must contain either (a) real revenue numbers or (b) an operational model that's plausibly automatable to be surfaced as High Signal. Anecdotes and "I'm going to build X" posts without validation are filtered out.

**Tier 2 — Demand Signal Sources (monitor every 2-3 days)**

| Source Type | M0 Starting Sources | What to Watch For |
|-------------|-------------------|-------------------|
| Professional communities | r/sysadmin, r/netsec, relevant Discord servers | Recurring complaints, underserved needs, "someone should build X" |
| Freelance platforms | Toptal, Upwork (infrastructure/security categories) | Demand signals for specific expertise, rate trends |

**Tier 3 — Landscape and Shift Sources (monitor weekly)**

| Source Type | M0 Starting Sources | What to Watch For |
|-------------|-------------------|-------------------|
| Platform policy | KDP Help, relevant platforms for active streams | Rule changes, pricing shifts affecting operations |
| AI tooling | Midjourney changelog, ElevenLabs blog, Anthropic product updates | Capability leaps that enable new products or reduce costs |

### Active Stream Watch List

Specific sources monitored because they directly affect committed or parked Execute Mode streams. Grows and shrinks with the portfolio.

| Stream | Watch Sources | Trigger Examples |
|--------|-------------|------------------|
| Wisdom Library | KDP policy page, AI art copyright developments, Standard Ebooks releases | KDP changes public domain rules, AI art gets copyright clarity |
| Opportunity Radar (future) | CI/trend tool launches, newsletter platform economics | New entrant in $15-49/mo technical intelligence gap |
| DNS Hygiene Toolkit (parked) | DNS security news, subdomain takeover incidents | Major incident drives demand, new tool validates or invalidates gap |

### Source Management

- Tess maintains a source registry with last-checked timestamps and signal-yield scores.
- **Deprioritization policy:** 30 days with zero items surfaced → demote from daily to weekly. 90 days with zero items surfaced → flag for Danny review (keep or archive).
- New sources can be added by Danny at any time via Telegram command or during monthly evaluation.
- **Manual intake:** Danny can forward a link/message to Tess with `/scout add [url] [context]` and Tess processes it through the same scoring pipeline. This handles private communities and serendipitous discoveries.
- **Source discovery is itself a Scout function.** When Tess encounters a reference to a community, platform, or publication that looks signal-rich, she adds it to the registry as a candidate source for Danny to approve.
- Source registry lives in the vault at `_system/scout/sources/` for transparency and auditability.

---

## 5. Scoring Framework

### Triage Gates (Daily Digest)

Each item gets a quick High/Medium/Low on three gate dimensions. These are the cheap, fast checks that determine whether an item reaches the digest.

**Gate 1: Conflict Safety**

| Score | Definition | Action |
|-------|-----------|--------|
| High | Clearly no employer overlap. Unrelated domain, public knowledge only. | Pass |
| Medium | Tangential to employer domain. Needs explicit check but likely fine. | Pass with flag |
| Low | Same domain as employer, competitive activity, or uses non-public knowledge. | Block — do not surface |

**Gate 2: Automation Potential**

| Score | Definition | Action |
|-------|-----------|--------|
| High | ≥70% of ongoing work automatable by Tess | Pass |
| Medium | 30-70% automatable. Requires regular Danny involvement. | Pass |
| Low | <30% automatable. Primarily manual ongoing effort. | Pass only if economics score is High |

**Gate 3: Profile Fit**

| Score | Definition | Action |
|-------|-----------|--------|
| High | Directly leverages existing assets (vault, book collection, Crumb infra, domain expertise, design system) | Pass |
| Medium | Leverages transferable skills but not existing assets directly | Pass |
| Low | Requires building entirely new capabilities from scratch | Pass only if economics score is High |

Items that pass all three gates get a brief assessment on the remaining dimensions: economics, distribution plausibility, demand evidence, compounding potential.

### Digest Item Fields

Each item in the digest includes:

- **Triage gate scores** (H/M/L for each gate)
- **Confidence grade:** How reliable is the underlying claim? (Verified / Supported / Plausible / Unverified)
- **Evidence grade:** Is this backed by revenue data, multiple sources, anecdote only, or self-reported? Items marked High Signal must have corroborated evidence (not single-source self-reported claims).

### Full Scoring (Research Dispatch)

When Danny flags an item for deeper research, Tess dispatches it to the researcher skill with a structured brief. The researcher produces a full nine-dimension score against the evaluation framework defined in the research brief (v0.5, Section 3). The nine dimensions are:

1. Goal Alignment (income, independence, skills, creative outlet)
2. Automation Profile (autonomous %, human pattern, startup effort, infra compounding)
3. Asset Leverage (Crumb/Tess, vault, books, domain expertise, design system, agent architecture)
4. Economics (startup cost, operating cost, time-to-revenue, ceiling, scaling vector)
5. Distribution Plausibility (how do first 10 customers find this?)
6. Conflict Safety (Strategic Independence Test — see Governance Rules)
7. Human Cleanup Burden (fulfillment, support, QC, edge cases, disputes)
8. Evidence of Demand (are people asking/paying/complaining?)
9. Compounding Score (does this make other opportunities easier?)

### Scoring Model Evolution

The scoring model is not static. It learns from:

- **Positive signal:** Opportunities that Danny pursued and found valuable
- **Negative signal:** Opportunities that Danny evaluated but passed on (reason recorded)
- **Operational signal:** Friction, time cost, and actual economics from Execute Mode streams
- **Market signal:** Changes in the landscape that shift the value of previously scored opportunities

Monthly evaluation memos include a "scoring model notes" section where Danny and Claude can record adjustments to dimension weights or threshold calibrations.

---

## 6. Candidate Registry & Lifecycle

### Candidate Record Schema

Every opportunity that clears triage gets a persistent record in the vault.

```
candidate_id:        [unique identifier]
title:               [descriptive name]
canonical_pattern:   [the underlying opportunity model, for dedup]
source_urls:         [list of sources where this was observed]
source_tier:         [highest-tier source that surfaced it]
first_seen:          [date first surfaced]
last_seen:           [date most recently observed]
evidence_grade:      [verified / supported / plausible / unverified]
confidence:          [H/M/L]
conflict_grade:      [H/M/L]
automation_grade:    [H/M/L]
fit_grade:           [H/M/L]
economics_note:      [brief assessment]
distribution_note:   [brief assessment]
demand_note:         [brief assessment]
compounding_note:    [brief assessment]
novelty_score:       [how different from existing portfolio]
state:               [new / bookmarked / researching / evaluating / parked / active / rejected / killed]
reason_code:         [why it's in current state]
linked_sources:      [related research memos, if any]
```

### Candidate States

```
new → bookmarked → researching → evaluating → active (Execute Mode)
                                             → parked (on radar)
                                             → rejected (Graveyard)
     → acknowledged (noted, no action)
active → killed (invalidated)
parked → promoted (landscape shifted favorably)
       → killed (no longer viable)
```

### Deduplication

When Tess encounters an opportunity that matches the `canonical_pattern` of an existing candidate, she updates the existing record (`last_seen`, appends `source_urls`) and increases novelty_score rather than creating a new entry. Repeated sightings of the same pattern from different sources is itself a signal — it means the opportunity is gaining visibility.

### Graveyard

Rejected or killed candidates stay in the registry with their `reason_code`. Scout checks new items against the Graveyard before surfacing them. If a new item matches a graveyard pattern, it is only resurfaced if the reason_code has been materially invalidated (e.g., a policy changed, a technology matured, a market shifted).

Vault location: `_system/scout/candidates/`

---

## 7. Feedback Mechanism

### Daily Review Commands

Danny responds to digest items via Telegram with simple commands:

| Command | Action | Effect |
|---------|--------|--------|
| `!bookmark [N]` | Save item N for monthly review | State → bookmarked |
| `!research [N]` | Dispatch researcher skill (max 1/day) | State → researching |
| `!evaluate [N]` | Flag as Execute Mode candidate (max 5/month) | State → evaluating |
| `!pass [N] [reason]` | Not interested | State → acknowledged, reason recorded |
| `!reject [N] [reason]` | Send to Graveyard | State → rejected, reason recorded |
| `/scout add [url] [context]` | Manual intake — process through scoring pipeline | New candidate created |

Tess parses these and updates the candidate registry. No vault navigation required during daily review. The vault is for storage, not daily interaction.

### Feedback Data Flow

Danny's responses feed the scoring model:
- Bookmark rate indicates what types of items Danny finds worth tracking
- Research dispatch patterns indicate what types warrant deeper investigation
- Pass/reject reasons indicate what types should be filtered more aggressively
- Source-level patterns (e.g., "Danny always passes on items from Source X") inform source yield scoring

---

## 8. Governance Rules

### Conflict Safety Policy

Based on Vector 5 research findings (dispatch 2efe6c41, confidence 0.78).

**Clearly safe — surface without flag:**
- Activities in domains with zero employer overlap (publishing, creative work, generalized education)
- Products built on public knowledge, personal expertise, and independent infrastructure
- Content creation on topics not specific to employer's competitive landscape

**Requires human review — surface with flag:**
- Activities in adjacent technical domains (general networking, security tooling) that might trigger "relates to employer's business" test
- Consulting or freelance opportunities in infrastructure/security (even if different sub-domain)
- Any activity where a reasonable observer might question the boundary

**Do not surface:**
- Direct competitive intelligence products about the DDI/DNS market
- Tools or services that compete with employer's offerings
- Anything requiring employer-confidential information or customer relationships
- Activities that would fail the plain-language test: "Would I be comfortable explaining this to my manager over coffee?"

### Source Trust Policy

- **High Signal items must have corroborated evidence.** Single-source, self-reported revenue claims are surfaced as Medium Signal at most. High Signal requires either multiple independent sources or a primary source with verifiable data.
- Revenue claims without methodology or specifics are treated as Plausible, not Verified.
- Vendor-sourced claims (e.g., "our tool saves 60% of production time") are flagged as vendor claims, not treated as independent evidence.

### Human Approval Boundaries

- Tess scans and scores autonomously. No approval needed.
- Tess delivers digests and processes feedback commands autonomously. No approval needed.
- Research dispatches require Danny's explicit `!research` command. Tess does not auto-dispatch.
- Adding new sources to the registry: Tess can propose, Danny approves.
- Portfolio rebalancing decisions (add/pivot/kill streams): Danny decides during monthly evaluation.

---

## 9. Digest Format

### Daily Digest Template

```
🔭 SCOUT DIGEST — [Date]
Signal count: [N] items | Sources checked: [N]

━━━ HIGH SIGNAL ━━━

[1] [One-line summary]
    Source: [where found] | Category: [scan category]
    Gate: Safety ✓ | Automation ✓ | Fit ✓
    Confidence: [Verified/Supported/Plausible]
    Evidence: [corroborated/single-source/self-reported]
    Key insight: [Why this matters in 2-3 sentences]
    Link: [URL]

━━━ MEDIUM SIGNAL ━━━

[2] [One-line summary]
    Source: [where found] | Category: [scan category]
    Gate: Safety ✓ | Automation ~ | Fit ✓
    Confidence: [grade] | Evidence: [grade]
    Key insight: [Brief note]
    Link: [URL]

━━━ LANDSCAPE CHANGES ━━━

[3] [Policy/market change affecting active streams]
    Affects: [which stream]
    Action needed: [None / Monitor / Investigate]

━━━ END ━━━
```

**Note:** Zero-signal source list omitted from human-facing digest. Stored in `_system/scout/ops/` for debugging and source health monitoring.

### Monthly Evaluation Memo Template

```
📊 SCOUT MONTHLY — [Month Year]

SIGNAL SUMMARY
- Total items surfaced: [N]
- High signal: [N] | Medium: [N]
- Items bookmarked: [N] | Researched: [N] | Evaluated: [N]
- Bookmark rate: [N]% (target: >20%)
- Duplicate rate: [N]% (target: <15%)

PORTFOLIO STATUS
- Execute Mode: [active streams and status]
- Parked: [opportunities being tracked]
- Killed: [anything removed this month]
- Graveyard additions: [newly rejected categories with reasons]

TOP SIGNALS THIS MONTH
[Ranked list of 3-5 most interesting items surfaced]

LANDSCAPE SHIFTS
[Notable changes to active stream markets]

SCORING MODEL NOTES
[Adjustments to weights, thresholds, or source priorities]
[What types of items Danny consistently bookmarks vs. passes on]

BEHAVIORAL IMPACT
[Did Scout surface anything Danny acted on this month?]
[Did Scout surface anything Danny would not have found otherwise?]

RECOMMENDED ACTIONS
[Specific next steps for Danny's consideration]
```

---

## 10. Integration with Execute Mode

### Feedback Loop

Any Execute Mode stream (current or future) must expose four metrics to Scout for scoring calibration:

| Data Type | Description | How Scout Uses It |
|-----------|------------|-------------------|
| Time-per-task actuals | Actual hours spent on key production steps | Calibrates "automation profile" scoring for similar opportunities |
| Revenue data | Sales, conversions, earnings per unit | Calibrates "economics" scoring for comparable products |
| Friction log | What was harder than expected, where did automation break | Flags "human cleanup burden" patterns to watch for |
| Market response | Reviews, rank, organic discovery, customer feedback | Validates or invalidates demand assumptions |

This interface is stream-agnostic. Wisdom Library is the first stream to implement it; future streams follow the same pattern.

### Portfolio Rebalancing

Monthly evaluation may result in:

- **Add:** A new opportunity scores high enough to warrant a second Execute Mode stream. Prerequisite: first stream must be at steady-state (low run-rate, pipeline proven) before Danny's attention is split.
- **Pivot:** An active stream is underperforming and a parked opportunity looks better.
- **Kill:** An active stream is invalidated (no demand, too much friction, market changed).
- **Promote:** A parked opportunity's landscape has shifted favorably.
- **No change:** Current allocation is working, stay the course.

---

## 11. Infrastructure Requirements

### What Already Exists (Reuse)

- **Tess orchestration:** Always-on via Telegram on Haiku, running on Mac Studio under OpenClaw
- **Feed ingestion:** FIF (Feed Intel Framework) completed M1/M2, production-ready
- **Delivery:** Telegram and Discord delivery pipelines validated
- **Research dispatch:** Researcher skill operational (proven across all seven vectors)
- **Vault storage:** Obsidian vault for persistent storage

### What Needs Building

| Component | Description | Effort Estimate |
|-----------|------------|-----------------|
| Source registry | Structured list of signal sources with metadata (URL, check frequency, last checked, yield score) | Small |
| Scan orchestration | Tess-driven scheduled scanning. Note: sources are heterogeneous — feed polling, web scraping, API access, manual intake all needed. Crumb to propose ingestion architecture during M0. | Medium |
| Triage scoring engine | Automated gate-check applied to raw scan results. Test Haiku vs. Sonnet during M0 (50 items, both models, measure agreement rate). Use Sonnet for digest assembly if Haiku passes triage but lacks nuance for "why this matters." | Medium |
| Candidate registry | Structured candidate records with dedup logic and state machine | Medium |
| Digest assembly | Template-based digest generation delivered via Telegram (primary) and Discord (mirror) | Small |
| Digest archive | Daily digests stored in vault for searchability and monthly review | Small |
| Monthly memo generator | Aggregates month's digests + candidate registry + feedback data into evaluation memo | Small |
| Feedback parser | Parses `!bookmark`, `!research`, `!pass`, `!reject`, `/scout add` commands from Telegram and updates candidate registry | Medium |

### Technical Approach

1. **FIF-based scanning:** Extend FIF for feed-based sources. Add scraper/API modules for non-feed sources. Keep ingestion pipeline unified downstream.
2. **Haiku-tier triage:** Gate scoring runs on Haiku for cost efficiency (~$1/month at 500 items/day).
3. **Sonnet-tier digest writing:** Digest assembly and "key insight" generation uses Sonnet for nuance.
4. **Opus-tier synthesis:** Monthly evaluation memos and research dispatch briefs use Opus for deeper analysis.
5. **Vault-native storage:** All Scout data lives in the Obsidian vault under `_system/scout/` with subdirectories: `digests/`, `sources/`, `candidates/`, `feedback/`, `monthly/`, `ops/`.

### Cost Target

Target: keep Scout under $10/month in API costs during M0-M2. If exceeded, either raise the budget consciously or narrow source scope. (Estimated: ~$1/month Haiku triage + ~$3-5/month Sonnet digest assembly + ~$2-5/month Opus monthly synthesis.)

---

## 12. Milestones

### M0: Source Registry & Triage Validation

**Timebox:** Two weeks maximum before first raw scan output.

**Deliverables:**
- Source registry populated with M0 starting set (3-5 sources per tier)
- Scan schedule configured in Tess
- Triage scoring prompt designed and tested on 50 sample items (Haiku vs. Sonnet comparison)
- Candidate registry schema implemented in vault
- Feedback parser accepting `!bookmark`, `!pass`, `/scout add` commands

**Acceptance criteria:**
- Tess successfully scans all M0 sources and produces raw signal output
- Haiku/Sonnet agreement rate on triage gates ≥ 85%
- Candidate registry correctly deduplicates repeated patterns

### M1: First Digest Production

**Deliverables:**
- Daily digest template implemented with confidence and evidence fields
- Triage scoring applied to scan results
- First digests delivered via Telegram (primary) and Discord (mirror)

**Acceptance criteria:**
- Danny receives and reviews 5 consecutive digests
- Median review time: 10-15 minutes
- At least 1 item bookmarked or researched in first week (if zero, triage is too aggressive or sources are too narrow)

### M2: Feedback Loop & Calibration

**Deliverables:**
- Full feedback mechanism operational (all commands working)
- Signal threshold tuned based on first 2 weeks of digests
- Source yield scoring active (low-yield sources deprioritized per policy)
- Graveyard initialized with rejected categories from research phase (DDI migration toolkit, raw PKB monetization, LLM data sales)
- Digest archive in vault

**Acceptance criteria:**
- Bookmark rate ≥ 20% of surfaced items
- Duplicate rate < 15%
- Median digest review time stays within 10-15 minute target
- Danny has not skipped more than 2 consecutive digests

**Abort criterion:** If after 30 days, <20% of surfaced items feel genuinely interesting or actionable, pause and revisit source selection and gating before continuing.

### M3: Monthly Evaluation Cycle

**Deliverables:**
- Monthly evaluation memo template implemented with all fields (signal summary, portfolio status, behavioral impact, scoring model notes)
- First monthly memo produced
- Feedback data from Execute Mode (Wisdom Library) integrated into scoring

**Acceptance criteria:**
- Monthly memo produces at least one concrete portfolio decision or explicit no-change rationale
- Evaluation process takes ≤ 30 minutes
- Scoring model notes section has at least one calibration observation

### M4: Steady State

**Deliverables:**
- Scout Mode running autonomously at daily cadence for 30+ consecutive days
- Source registry self-maintaining (yield scores updating, low-yield sources auto-deprioritized)
- Feedback loop closed (operational data from Execute Mode actively calibrating scores)
- Monthly evaluation cycle established as routine
- Candidate registry contains ≥ 20 tracked items across multiple states

**Acceptance criteria:**
- Scout has surfaced at least one opportunity that Danny acted on and would not have found otherwise
- Danny has not abandoned daily review (skipped ≤ 3 digests in any 30-day period)
- System runs with ≤ 15 minutes/day of Danny's time (digest review + feedback commands)

---

## 13. Relationship to Other Projects

**Wisdom Library (Execute Mode):** Scout monitors the Wisdom Library's market landscape via the Active Stream Watch List. Operational data from Wisdom Library production calibrates Scout's scoring model via the four-metric interface (Section 10).

**Research Brief (v0.5):** Scout's evaluation framework is derived from the research brief. The nine-dimension scoring model is the shared DNA. Any updates to the framework apply to both documents.

**Competitive Intel (Separate Project):** DDI/DNS/network security competitive intelligence for SE performance is a separate project. Scout's scope is opportunity detection for income/skill/creative ventures. The two projects may share infrastructure but have different scopes and output formats.

**Future Execute Mode Streams:** Scout's primary job is to identify when a parked opportunity should be promoted to active execution, or when an entirely new opportunity should be evaluated. Each new stream connects to Scout via the four-metric feedback interface.

---

## 14. Open Questions

1. **FIF extension scope:** How much of FIF can be reused directly vs. needs adaptation for Scout's heterogeneous source types? Crumb to assess and propose ingestion architecture during M0.

2. **Haiku classification quality:** M0 includes a 50-item comparison test. If agreement < 85%, fall back to Sonnet for triage on ambiguous cases.

3. **Digest volume calibration:** The right triage threshold will only emerge from live data. Plan to iterate weekly during M0-M1.

4. **Vault architecture:** Proposed: `_system/scout/` with `digests/`, `sources/`, `candidates/`, `feedback/`, `monthly/`, `ops/`. Crumb to confirm this fits the vault architecture.

5. **Cost at scale:** Estimated ~$7-10/month for M0-M2. Monitor and adjust if source count grows significantly.

6. **Aperture expansion timing:** When does Scout graduate from M0-M2 focus constraint to broader scanning? Suggest: after M2 acceptance criteria are met and 30+ days of stable operation.

---

## Appendix A: Evaluation Framework Reference

The full nine-dimension evaluation framework is defined in side-hustle-research-brief-v0.5.md, Section 3. For quick reference during triage prompt design:

| # | Dimension | Core Question | Triage Gate? |
|---|-----------|--------------|-------------|
| 1 | Goal Alignment | Does it build income, independence, skills, or creative outlet? | No — assessed in digest note |
| 2 | Automation Profile | Can Tess handle ≥30% of ongoing work? | **Yes — Gate 2** |
| 3 | Asset Leverage | Does it use existing Crumb/vault/expertise? | **Yes — Gate 3** |
| 4 | Economics | What's the revenue trajectory and scaling vector? | No — assessed in digest note |
| 5 | Distribution Plausibility | Can anyone find and buy the output? | No — assessed in digest note |
| 6 | Conflict Safety | Does it pass the Strategic Independence Test? | **Yes — Gate 1** |
| 7 | Human Cleanup Burden | How much last-mile human work remains? | No — assessed in digest note |
| 8 | Evidence of Demand | Are people asking/paying/complaining? | No — assessed in digest note |
| 9 | Compounding Score | Does this make other opportunities easier? | No — assessed in digest note |

## Appendix B: Peer Review Contributions

| Reviewer | Key Contributions Incorporated |
|----------|-------------------------------|
| Gemini | Sonnet for digest assembly; triage prompt quality as make-or-break |
| DeepSeek | Feedback command model (`!bookmark`/`!research`/`!pass`/`!reject`); manual intake (`/scout add`); graveyard/anti-signals; source abstraction layer; Haiku vs. Sonnet comparison test; cost modeling ($1/month triage); generalized Execute Mode feedback interface |
| ChatGPT | Candidate record schema and lifecycle state machine; governance rules (conflict safety policy, source trust, human approval boundaries); measurable milestone criteria; attention budget consistency fix; dedupe model; abort criterion |
| Perplexity | Behavioral failure mode identification ("firehose you learn to ignore"); M0-M2 focus constraint; research dispatch rate limit (1/day); evaluation flag cap (5/month); behavioral impact as ultimate success metric; "abort if sucks" criterion |
