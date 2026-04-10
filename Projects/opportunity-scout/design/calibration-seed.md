---
project: opportunity-scout
domain: software
type: design-artifact
status: active
created: 2026-03-14
updated: 2026-03-14
tags:
  - calibration
  - scoring
---

# Opportunity Scout — Scoring Calibration Seed

Extracted from v1–v7 research dispatches. This document initializes the triage scoring prompt, graveyard, and dimension weight model for OSC-001.

---

## 1. Graveyard Seed — Rejected Categories

These canonical patterns are permanently filtered from Scout digest output. A graveyard entry is only resurfaced if its `reason_code` is materially invalidated (e.g., employer changes, policy shift, technology maturation).

| # | canonical_pattern | reason_code | source_dispatch | evidence |
|---|-------------------|-------------|-----------------|----------|
| 1 | `ddi-competitive-intelligence` | conflict-safety-fail: directly overlaps Infoblox's business domain. No employed-while-publishing precedent found. CI about one's own industry is NOT "generalized expertise." Disclosure likely to be denied. | v1 (ac59284e) | Conflict safety scored 2/10. All identified successful cybersecurity CI publishers are independent, not employed at vendors. Composite score 5.1/10 dragged down by conflict. |
| 2 | `ddi-migration-toolkit` | conflict-safety-moderate + low-compounding: closer to Infoblox's core business (vendor-to-vendor migration tooling could be perceived as competitive). Episodic use limits compounding. High human cleanup burden per migration. | v2 (bb4cf1b9) | Conflict safety scored 2/5. Compounding scored 2/5. Human cleanup burden scored 2/5. Economics are one-time-purchase per migration with no recurring revenue path. |
| 3 | `same-domain-consulting` | conflict-safety-fail: consulting in the same technical domain as employer carries highest conflict risk regardless of structural protections. Creates perception of competitive threat and customer confusion. | v5 (2efe6c41) | Explicitly identified as "Highest Risk" in v5 domain boundary analysis. Even with full structural separation, same-domain consulting triggers employer action regardless of legal merits. |
| 4 | `raw-pkb-access-product` | no-demonstrated-market: no validated examples exist of anyone successfully monetizing raw access to a personal knowledge base. Every successful PKM-adjacent business transforms knowledge into a different product shape. | v6 (07fe21bb) | Absence finding well-searched across Obsidian, Roam, Notion, and digital garden ecosystems. Dubois ($20K/yr) sells vault templates (structure), not vault contents. |
| 5 | `llm-training-data-sales` | market-inaccessible: AI training dataset market ($2.62B) is enterprise-dominated. Individual seller access is extremely limited. Opendatabay focuses on traditional datasets, not personal knowledge bases. | v6 (07fe21bb) | 77 identified AI training data vendors, all enterprise players. Flowith Knowledge Marketplace is single-beta-case ($3K/2wk) on unproven platform. |

---

## 2. High-Scoring Patterns

Opportunity patterns that scored well across the nine-dimension framework. These calibrate the "what good looks like" baseline for the triage scoring prompt.

### Pattern 1: DNS Hygiene Toolkit
**Source:** v2 (bb4cf1b9)
**Composite score:** Highest in v2 (36/45 raw)
**Strong dimensions:** Automation profile (5/5), Asset leverage (5/5), Conflict safety (4/5), Distribution plausibility (4/5), Compounding (4/5)
**Why it scored well:** One-time build with automated scans, minimal ongoing maintenance. Deep DNS/DDI knowledge is the moat. Generalized tooling (not Infoblox-specific) provides clean conflict boundary. Network engineering communities + GitHub provide natural distribution. Cross-sell between tools compounds value.
**Gate mapping:** Conflict=H, Automation=H, Fit=H

### Pattern 2: Expert Research Newsletter (Agent-Assisted)
**Source:** v3 (5a3297e1), with supporting evidence from v4 (1a15b088)
**Strong dimensions:** Goal alignment (HIGH), Automation profile (HIGH), Asset leverage (HIGH), Conflict safety (HIGH per v5), Compounding (HIGH)
**Why it scored well:** Research aggregation, synthesis, formatting, and distribution are all agent-automatable. Danny's vault infrastructure (1,400+ files, 390 books, digest pipeline) is directly deployable. Education and content creation have the cleanest conflict boundary per v5 research. Each piece of content builds the knowledge base; each subscriber increases distribution leverage. "Human expert + AI tooling" positioning avoids AI trust penalty while capturing cost advantage.
**Gate mapping:** Conflict=H, Automation=H, Fit=H

### Pattern 3: Public Domain Wisdom Library
**Source:** v7 (81a052ff)
**Composite score:** 7.3/10 (highest composite across all dispatches)
**Strong dimensions:** Goal alignment (8/10), Automation profile (8/10), Conflict safety (9/10), Compounding (8/10), Asset leverage (7/10)
**Why it scored well:** Lowest conflict risk of all vectors — public domain content, no client conflicts, no professional boundary issues. High automation potential (AI narration, AI illustration, templated formatting). Strong compounding as each title adds to catalog and cross-sell. Production costs are low ($150-350/title marginal). Break-even at 37-75 sales per title is achievable.
**Weaknesses:** Per-title revenue ceiling is modest. AI narration requires 10-20 hours editing per title. Competition from free alternatives (Standard Ebooks, Project Gutenberg).
**Gate mapping:** Conflict=H, Automation=H, Fit=H

### Pattern 4: One-Time Digital Products (Templates, Reference Packs)
**Source:** v3 (5a3297e1), v6 (07fe21bb)
**Strong dimensions:** Economics (80-95% margins), Conflict safety (HIGH), Distribution plausibility (Gumroad/Lemon Squeezy established)
**Why it scored well:** Low production cost, high margins, conflict-safe (generalized expertise). Notion template market validates demand (Thomas Frank $1M, Easlo $239K/yr). Can serve as lead magnet into higher-value offerings. Dubois's Obsidian Starter Kit demonstrates the model works at small scale ($8K from 181 sales).
**Weaknesses:** Revenue ceiling per product is modest without audience. Requires building an audience first.
**Gate mapping:** Conflict=H, Automation=M, Fit=H

### Pattern 5: Opportunity Radar / Technically-Opinionated Intelligence Product
**Source:** v4 (1a15b088)
**Strong dimensions:** Goal alignment (HIGH), Automation profile (HIGH), Asset leverage (HIGH), Compounding (HIGH)
**Why it scored well:** Core pipeline already exists in Crumb/Tess infrastructure — productization is exposure, not construction. Feed ingestion, scoring, synthesis pipeline is existing infrastructure. No product currently occupies the $15-49/mo range targeting individual technical professionals with domain-specific intelligence. Content-led organic growth is proven (Pragmatic Engineer, Stratechery).
**Weaknesses:** Inference cost scaling at subscriber count (500-1000% cost underestimation risk). Competes with free newsletters (AlphaSignal, TLDR). No direct evidence for this exact product category at an accessible price point.
**Gate mapping:** Conflict=H (if generic, not DDI-specific), Automation=H, Fit=H

### Pattern 6: Network Config / Automation Plugin (NetBox, Ansible)
**Source:** v2 (bb4cf1b9)
**Composite score:** 32/45 raw
**Strong dimensions:** Goal alignment (4/5), Automation profile (4/5), Asset leverage (4/5), Distribution plausibility (4/5), Conflict safety (4/5)
**Why it scored well:** Built-in marketplace distribution (NetBox plugin catalog, Ansible Galaxy). Leverages network expertise + software development. Generic infrastructure, not vendor-specific. Build once, maintain alongside platform updates.
**Weaknesses:** Plugin pricing typically modest. Platform dependency creates risk. Plugin ecosystem commercial revenue unproven.
**Gate mapping:** Conflict=H, Automation=H, Fit=H

### Pattern 7: Knowledge-Transformed Products (Courses, Community, Consulting Pipeline)
**Source:** v6 (07fe21bb)
**Strong dimensions:** Asset leverage (HIGH — 1,400+ files, 390 books), Conflict safety (HIGH), Compounding (HIGH)
**Why it scored well:** Every successful PKM monetization transforms knowledge into courses, communities, templates, or consulting pipelines. Tiago Forte ($1M+/yr), Nat Eliason ($600K lifetime), Anne-Laure Le Cunff ($120K+/yr) all demonstrate the model. Danny's vault is directly deployable as course/community foundation.
**Weaknesses:** Requires significant audience building. Teaching PKM is a crowded space — differentiation must come from domain-specific expertise, not PKM methodology.
**Gate mapping:** Conflict=H, Automation=M, Fit=H

---

## 3. Dimension Weight Observations

These observations capture what the v1-v7 research revealed about relative importance of the nine scoring dimensions for Danny's specific situation. They inform how the three-gate triage model should weight its decisions.

### Conflict Safety is the Dominant Constraint (Veto Power)
Every dispatch that touched employer-adjacent territory showed conflict safety as the single dimension that can zero out an otherwise strong opportunity. V1 scored 2/10 on conflict safety and that alone dragged the composite from ~6/10 to 5.1/10. V2's DDI migration toolkit scored 2/5 on conflict safety despite 5/5 on asset leverage. V5 established that education and content creation have the "cleanest conflict boundary" while same-domain consulting is structurally conflicted regardless of other dimensions.

**Weight implication:** Conflict safety is a gate, not a dimension. Low conflict safety = block, period. This is correctly modeled as Gate 1 in the three-gate triage.

### Automation Profile is the Second-Strongest Discriminator
Across all dispatches, the patterns that scored highest overall were those with high automation potential. DNS Hygiene Toolkit (5/5 automation), Wisdom Library (8/10 automation), Expert Research Newsletter (HIGH automation). The weakest patterns — same-domain consulting, DDI migration toolkit, raw PKB access — all had low automation profiles. Danny's primary constraint is time (full-time employment + solo operator). Any opportunity requiring sustained manual effort beyond 10-15 min/day of review is structurally incompatible.

**Weight implication:** Automation should be weighted heavily in Gate 2. The "Low automation passes only if economics are High" rule in the spec is correct — it creates a narrow exception for genuinely exceptional economics.

### Asset Leverage Separates "Interesting" from "Actionable"
The most actionable patterns directly leverage Danny's existing assets: the vault (1,400+ files, 390 books), Crumb/Tess infrastructure, DDI/DNS domain expertise, the design system, and agent architecture. Patterns requiring entirely new capability development (e.g., building a SaaS from scratch in an unfamiliar domain) scored lower on actionability even when they scored well on other dimensions.

**Weight implication:** Gate 3 (Profile Fit) correctly captures this. The distinction between "leverages existing assets" (H) and "leverages transferable skills but not existing assets" (M) is the key discriminator.

### Economics Is Important but Not Gating
V7 (Wisdom Library) scored 6/10 on economics but 7.3/10 composite — the strongest overall. V6 showed PKM monetization ranges from $20K (Dubois) to $1M+ (Forte) depending entirely on format and audience, not the underlying knowledge. Economics matter for evaluation depth (research dispatch stage) but not for triage filtering.

**Weight implication:** Economics correctly sits outside the three gates and is assessed in the digest note. However, the exception rule — "Low automation/fit passes if economics are High" — acknowledges that exceptional economics can override structural weaknesses.

### Distribution Plausibility Is a Slow-Burn Dimension
Every dispatch noted that audience building is slow. Content-led organic growth is proven (Pragmatic Engineer, Stratechery) but takes months to years. This means distribution plausibility is important for evaluation but should not filter at triage — nearly everything starts with low distribution and builds over time.

**Weight implication:** Correctly excluded from the three gates. Assessed in digest notes.

### Compounding Score Distinguishes Sustainable from One-Shot
The highest-scoring patterns all had strong compounding: newsletter archives become searchable reference, each subscriber increases distribution, each title adds to catalog, scoring models improve with feedback. The weakest patterns (DDI migration toolkit, same-domain consulting) were episodic with no compounding.

**Weight implication:** Compounding is correctly a digest-note dimension, not a gate. But it should be weighted heavily in the Sonnet-tier batch ranking step (AD-10 stage 2) when ordering items within a digest.

### Evidence of Demand Varies Wildly by Category
V3 and V4 had strong demand evidence (Pragmatic Engineer $1.5M+/yr, Stratechery $5M+/yr). V6 had moderate evidence (PKM monetization proven but niche-specific demand unvalidated). V2 had strong pain-point evidence but no quantified demand. V7 had validated category demand (Stoic philosophy boom) but fierce competition.

**Weight implication:** Evidence of demand should be captured in the confidence and evidence grade fields of the digest, not in the gates. Items with "Verified" evidence grade should rank higher than "Plausible" in the Sonnet batch ranking.

---

## 4. Conflict-Safety Boundary Examples (from v5)

These examples establish the operational boundary for Gate 1. Sourced from dispatch 2efe6c41 (confidence 0.78).

### Clearly Safe (Gate 1 = H)

| Activity | Why Safe | Precedent |
|----------|----------|-----------|
| Technical books/courses on generalized topics | Public knowledge, personal expertise, no employer IP | Philip Kiely: $20K first week, "Writing For Software Developers" while employed as SE |
| Blogging/podcasting on domain expertise | Personal voice, public information | Scott Hanselman: 20+ years blogging, 1000+ podcast episodes while VP at Microsoft |
| Speaking/training at conferences | Personal brand building | Hanselman model — complementary to employer interests |
| Tools in unrelated domain | Complete domain separation | Patrick McKenzie (patio11): Bingo Card Creator (education) while enterprise SE |
| Public domain content publishing | No employer connection whatsoever | V7 Wisdom Library scored 9/10 conflict safety |

### Requires Human Review (Gate 1 = M)

| Activity | Why Ambiguous | Key Test |
|----------|--------------|----------|
| Generalized networking/security tooling | Adjacent to employer domain but not specific to DDI | Does it "relate to the employer's business or anticipated R&D"? (state statute exception language) |
| Infrastructure consulting in different sub-domain | Customer overlap possible, competitive perception risk | "Would I be comfortable explaining this to my manager over coffee?" |
| DNS Hygiene Toolkit (stale record cleanup, dangling DNS scanner) | DNS is employer-adjacent but the tooling is generalized, not Infoblox-specific | V2 scored 4/5 on conflict safety — the generalized nature provides buffer |

### Do Not Surface (Gate 1 = L)

| Activity | Why Blocked | Source |
|----------|------------|--------|
| DDI/DNS competitive intelligence digest | Directly overlaps employer domain. "CI about one's own industry is NOT generalized expertise." | V1: no employed-while-publishing precedent; conflict safety 2/10 |
| DDI migration tooling | "Closer to Infoblox's business; migration tooling could be seen as competitive." | V2: conflict safety 2/5 |
| Same-domain consulting (DDI/DNS/IPAM) | "Highest conflict risk regardless of structural protections." Creates competitive threat perception. | V5: explicit "Highest Risk" category |
| Anything requiring employer-confidential information | IP assignment is primary risk vector, not non-competes. Alcatel v. Brown: employee lost innovation AND paid $332K legal fees. | V5: landmark cautionary tale |

### Structural Protections (context for scoring prompt)

The v5 research identified a consistent structural pattern for safe side-business operation:
1. **Temporal separation** — all work on personal time exclusively
2. **Resource separation** — separate devices, networks, accounts, infrastructure
3. **Knowledge separation** — public information only, no employer trade secrets
4. **Documentation** — contemporaneous records demonstrating independent creation
5. **Entity formation** — LLC for liability protection (does not create IP separation)
6. **Disclosure** — strongest single protective action (paradoxically, disclosure of DDI CI digest to employer would likely be denied)

**Key legal context:** Nine US states (including California) provide statutory protection for employee inventions on personal time. BUT all include the "relates to employer's business" exception. IP assignment disputes — not non-competes — are the primary risk vector. Litigation cost asymmetry structurally favors employers regardless of legal merits.

---

## 5. Three-Gate Mapping

How the original nine dimensions map to the three-gate triage model. This mapping is the compression that enables Haiku-tier triage at acceptable cost.

### Gate 1: Conflict Safety (Dimension 6)
- **Maps from:** Dimension 6 (Conflict Safety) directly
- **Scoring rubric:** H = clearly no employer overlap, unrelated domain, public knowledge only. M = tangential to employer domain, needs explicit check. L = same domain, competitive activity, or uses non-public knowledge.
- **Action:** L = block (hard filter). M = pass with flag. H = pass.
- **Why this is a gate:** V1-V7 data shows conflict safety has veto power. A single L on conflict safety invalidates any combination of other scores. No other dimension has this property.

### Gate 2: Automation Potential (Dimension 2, informed by Dimension 7)
- **Maps from:** Dimension 2 (Automation Profile) primarily, with Dimension 7 (Human Cleanup Burden) as inverse signal
- **Scoring rubric:** H = >=70% of ongoing work automatable by Tess. M = 30-70% automatable, requires regular Danny involvement. L = <30% automatable, primarily manual ongoing effort.
- **Action:** L = pass only if economics score is H. M = pass. H = pass.
- **Compressed signal:** Automation profile and human cleanup burden are conceptually inverse. High automation = low cleanup burden. The gate captures both by asking "what percentage of the work can run without Danny?"
- **Why this is a gate:** Danny's time constraint (full-time employment + solo operator) makes automation the second-hardest structural requirement. Time-intensive opportunities fail operationally even when they score well on everything else.

### Gate 3: Profile Fit (Dimensions 1 + 3)
- **Maps from:** Dimension 1 (Goal Alignment) + Dimension 3 (Asset Leverage)
- **Scoring rubric:** H = directly leverages existing assets (vault, book collection, Crumb infra, domain expertise, design system). M = leverages transferable skills but not existing assets directly. L = requires building entirely new capabilities from scratch.
- **Action:** L = pass only if economics score is H. M = pass. H = pass.
- **Compressed signal:** Goal alignment and asset leverage both answer "does Danny already have what this needs?" Goals (income, independence, skills, creative outlet) define the direction; assets (vault, infra, expertise) define the starting position.
- **Why this is a gate:** The v1-v7 research consistently showed that patterns leveraging existing assets scored higher overall. Starting from zero in a new domain is both slower and riskier for a solo operator.

### Non-Gated Dimensions (Assessed in Digest Notes)
These six dimensions are evaluated during Sonnet-tier digest assembly (AD-10 stage 2), not during Haiku triage:

| Dimension | Where Assessed | Role in Digest |
|-----------|---------------|----------------|
| 4. Economics | `economics_note` field | Revenue trajectory, scaling vector, startup cost |
| 5. Distribution Plausibility | `distribution_note` field | How first 10 customers find this |
| 7. Human Cleanup Burden | Partially in Gate 2, remainder in digest note | Fulfillment, support, QC, edge cases |
| 8. Evidence of Demand | Confidence + evidence grade fields | Are people asking/paying/complaining? |
| 9. Compounding Score | `compounding_note` field | Does this make other opportunities easier? |
| 1. Goal Alignment (residual) | Partially in Gate 3, remainder in digest note | Income vs. independence vs. skills vs. creative |

---

## 6. U5 Resolution

**Status: NOT FOUND — reconstructed from dispatches.**

The research brief v0.5 (`side-hustle-research-brief-v0.5.md`) referenced in the draft spec as "Parent doc" does not exist in the vault. It was never written to the vault filesystem.

**Search performed:**
- Grep for "side-hustle-research-brief" across entire vault: zero results
- Glob for `**/*side-hustle*brief*`: zero results
- Grep for "research brief", "v0.5", "portfolio brief" across vault: found references TO the brief in the draft spec and v1-v7 dispatches, but not the brief itself
- Checked `_inbox/`, `Sources/research/`, `Projects/opportunity-scout/`, `_system/schemas/briefs/`: not present

**What the brief contained (reconstructed from references):**
The draft spec's Appendix A (Section 586) explicitly states: "The full nine-dimension evaluation framework is defined in side-hustle-research-brief-v0.5.md, Section 3." The nine dimensions are:

1. Goal Alignment (income, independence, skills, creative outlet)
2. Automation Profile (autonomous %, human pattern, startup effort, infra compounding)
3. Asset Leverage (Crumb/Tess, vault, books, domain expertise, design system, agent architecture)
4. Economics (startup cost, operating cost, time-to-revenue, ceiling, scaling vector)
5. Distribution Plausibility (how do first 10 customers find this?)
6. Conflict Safety (Strategic Independence Test)
7. Human Cleanup Burden (fulfillment, support, QC, edge cases, disputes)
8. Evidence of Demand (are people asking/paying/complaining?)
9. Compounding Score (does this make other opportunities easier?)

V2 references "the 9 dimensions from the side-hustle portfolio brief" (line 143), confirming the brief existed as a document that the dispatches were scored against. The brief likely also contained Danny's profile description, constraint set, and the original framing for the seven research vectors.

**Practical impact:** The framework is fully reconstructable from the draft spec and dispatch data. This calibration seed document captures all operationally relevant content. No separate reconstruction artifact is needed — the framework is now codified in sections 2-5 above and in the spec's Appendix A.

---

## Appendix: Dispatch Score Summary

Cross-dispatch scoring data for reference during triage prompt design.

### V1 — Competitive Intel Digests (dispatch ac59284e, confidence 0.68)

| Dimension | Score | Notes |
|-----------|-------|-------|
| Goal alignment | 7/10 | Leverages deep domain expertise |
| Automation profile | 5/10 | Research/curation is labor-intensive |
| Asset leverage | 6/10 | Domain knowledge is asset, but can't leverage employer-specific knowledge |
| Economics | 4/10 | Sponsorship viable at small scale but requires audience |
| Distribution plausibility | 6/10 | LinkedIn targeting effective; DDI community small |
| Conflict safety | 2/10 | **Highest-risk vector** — directly overlaps employer domain |
| Human cleanup burden | 6/10 | Weekly curation requires sustained manual effort |
| Evidence of demand | 5/10 | Signals exist but contradicted by free-content norm |
| Compounding | 5/10 | Audience compounds but conflict risk limits trajectory |
| **Composite** | **~5.1/10** | Conflict safety is dominant drag |

### V2 — DNS/DDI Network Tooling (dispatch bb4cf1b9, confidence 0.74)

**DNS Hygiene Toolkit** (best-scoring in v2):

| Dimension | Score (1-5) | Notes |
|-----------|-------------|-------|
| Goal alignment | 4 | Leverages DDI expertise; builds IP |
| Automation profile | 5 | One-time build, automated scans |
| Asset leverage | 5 | Deep DNS/DDI knowledge is moat |
| Economics | 3 | Micro-SaaS median $4.2K MRR; ceiling unclear |
| Distribution plausibility | 4 | Network engineering communities + GitHub |
| Conflict safety | 4 | Generalized tooling, not Infoblox-specific |
| Human cleanup burden | 4 | Low once built |
| Evidence of demand | 3 | Universal pain points; no quantified demand |
| Compounding | 4 | Cross-sell between tools |

**DDI Migration Toolkit** (rejected — graveyard entry):

| Dimension | Score (1-5) | Notes |
|-----------|-------------|-------|
| Goal alignment | 3 | Episodic, not recurring |
| Automation profile | 3 | Each migration has unique elements |
| Asset leverage | 5 | Cross-vendor DDI knowledge is rare |
| Economics | 3 | One-time purchase per migration |
| Distribution plausibility | 3 | Vendors may resist neutral tooling |
| Conflict safety | 2 | **Closer to Infoblox's business** |
| Human cleanup burden | 2 | Migration data quality needs human judgment |
| Evidence of demand | 4 | Migration pain well-documented |
| Compounding | 2 | **Episodic use, no recurring revenue** |

### V3 — Expert Research Formats (dispatch 5a3297e1, confidence 0.72)

Qualitative scoring (no numeric grid):

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Goal alignment | HIGH | Leverages deep domain expertise; builds intellectual capital |
| Automation profile | HIGH | Research aggregation, synthesis, formatting all agent-automatable |
| Asset leverage | HIGH | 1,400+ vault files, 390 books, digest pipeline directly deployable |
| Economics | MEDIUM-HIGH | 80-95% margins; time is dominant cost |
| Distribution plausibility | MEDIUM | Platform infrastructure exists but audience building takes time |
| Conflict safety | HIGH (per v5) | Education/content creation = cleanest conflict boundary |
| Human cleanup burden | LOW-MEDIUM | Agent-assembled drafts need editorial review, not rewriting |
| Evidence of demand | MEDIUM-HIGH | ipSpace.net sustained 13+ years; Pragmatic Engineer $1.5M+/yr |
| Compounding | HIGH | Content builds knowledge base; subscribers compound distribution |

### V4 — Opportunity Radar Products (dispatch 1a15b088, confidence 0.72)

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Goal alignment | High | Extends existing Crumb/Tess infrastructure |
| Automation profile | High | Core pipeline exists; productization is exposure |
| Asset leverage | High | Feed ingestion, scoring, synthesis is existing infra |
| Economics | Medium | $15-49/mo viable but inference costs at scale constrain |
| Distribution plausibility | Medium | Content-led growth proven but slow |
| Conflict safety | High | Generic intelligence product if not DDI-specific |
| Human cleanup burden | Medium | Quality requires human calibration |
| Evidence of demand | Medium | Indirect evidence strong; direct evidence thin |
| Compounding | High | Subscriber feedback improves scoring models |

### V5 — Conflict-Safe Monetization (dispatch 2efe6c41, confidence 0.78)

Not scored as an opportunity vector. Instead provides the conflict-safety scoring rubric:

| Activity Type | Conflict Risk | Strategic Independence Test |
|---------------|---------------|----------------------------|
| Technical books/courses (generalized) | Very Low | Strong pass |
| Blogging/podcasting on domain expertise | Low | Pass |
| Speaking/training at conferences | Low | Pass |
| Tooling in unrelated domain | Low | Pass |
| Tooling in adjacent domain | Moderate | Partial — depends on specifics |
| Consulting in adjacent domain | Moderate-High | Weak |
| Consulting in same domain | High | Fail |

### V6 — Knowledge Asset Monetization (dispatch 07fe21bb, confidence 0.74)

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Goal alignment | Medium | Leverages existing assets but requires transformation work |
| Automation profile | Medium-High | Digest pipeline exists; delivery depends on format |
| Asset leverage | High | 1,400+ files, 390 books = core asset |
| Economics | Variable | $20K (Dubois) to $1M+ (Forte) depending on format |
| Distribution plausibility | Medium | No existing audience |
| Conflict safety | High | Knowledge/education = cleanest conflict boundary |
| Human cleanup burden | Medium-High | Vault needs curation before public exposure |
| Evidence of demand | Medium | PKM education proven; curated knowledge unproven |
| Compounding | High | Each book/connection increases value |

### V7 — Public Domain Wisdom Library (dispatch 81a052ff, confidence 0.72)

| Dimension | Score | Notes |
|-----------|-------|-------|
| Goal alignment | 8/10 | Strong mission alignment |
| Automation profile | 8/10 | AI narration, AI illustration, templated formatting |
| Asset leverage | 7/10 | Leverages vault book digests, Tess orchestration |
| Economics | 6/10 | Low per-title cost but also low per-title revenue ceiling |
| Distribution plausibility | 7/10 | KDP, Kobo, Google Play accessible. ACX/Audible restricted. |
| Conflict safety | 9/10 | **Lowest risk of all vectors** |
| Human cleanup burden | 6/10 | AI narration requires 10-20 hrs editing per title |
| Evidence of demand | 7/10 | Stoic boom (10M Holiday books), Gutenberg downloads |
| Compounding | 8/10 | Each title adds to catalog, brand, cross-sell |
| **Composite** | **7.3/10** | **Highest composite across all dispatches** |
