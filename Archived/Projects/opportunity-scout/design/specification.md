---
project: opportunity-scout
domain: software
type: specification
skill_origin: systems-analyst
created: 2026-03-14
updated: 2026-03-14
tags:
  - automation
  - tess
  - openclaw
  - opportunity-detection
---

# Opportunity Scout — Specification

## Problem Statement

Danny has no systematic way to discover income-generating, skill-building, or creative side ventures. Despite deep technical expertise, a functioning AI agent infrastructure (Crumb/Tess), and seven completed research dispatches that map the opportunity landscape, opportunity discovery is entirely absent — not manual, not automated, not even informal. The research dispatches produced evaluation frameworks and calibration data, but no ongoing scanning capability. Opportunities that Danny would find valuable are passing undetected.

## Facts

- **F1:** Seven side-hustle research dispatches (v1–v7) completed, covering competitive intel digests, DNS/DDI network tooling, expert research formats, opportunity radar products, conflict-safe monetization, knowledge asset monetization, and public domain wisdom library. Each includes structured findings, confidence grades, and evaluation against a nine-dimension scoring framework.
- **F2:** FIF (Feed Intel Framework) is in TASK phase with production RSS/Atom ingestion. HN and arXiv adapters are live. Reddit adapter gated on API terms review. FIF is purpose-built for feed ingestion — not a general-purpose scanning platform.
- **F3:** Tess delivers via Telegram (primary) and Discord (mirror). Delivery infrastructure is validated and operational.
- **F4:** book-scout (phase: DONE) provides a proven pattern for Tess-driven tools with Telegram interaction — search, present candidates, Danny approves, Tess acts.
- **F5:** Haiku cannot reliably execute complex procedures from SOUL.md. Competing behavioral instructions in SOUL.md override later procedural sections. Dedicated session prompts (cron/exec) are required for reliable procedure execution. (Source: `_system/docs/solutions/haiku-soul-behavior-injection.md`)
- **F6:** OpenClaw `--model` override is broken (#9556/#14279). The stored model value is ignored at runtime — the agent's default model is used.
- **F7:** OpenClaw `delivery.to` is broken (v2026.2.25). Gateway ignores the stored value. Combined with `bestEffort: true`, delivery reports success when nothing was sent.
- **F8:** DM pairings in OpenClaw are in-memory only — lost on gateway restart.
- **F9:** Danny's employer is Infoblox (DDI/DNS/IPAM). Conflict safety eliminates direct-domain monetization but not systems-thinking applied to other domains. (Source: v5 dispatch, confidence 0.78)
- **F10:** Danny has NO existing scanning practice. He has never systematically looked for opportunities. The Wisdom Library concept emerged organically over years, not from deliberate scanning.
- **F11:** API cost target for Scout pilot: ≤$10/month.
- **F12:** Operational architecture pattern (documented): bash for checks, direct curl for delivery, OpenClaw for thinking. Lightweight operations shouldn't go through the full LLM pipeline.

## Assumptions

- **A1:** Danny will engage with a daily digest format consistently enough to provide feedback signal. *Validation: M1 gate — 5 qualifying digests reviewed within a 21-day window, with at least 10 scan cycles completed. HIGH RISK — no existing habit to anchor onto.*
- **A2:** Haiku can perform triage scoring (three-gate H/M/L classification) at acceptable quality when given a focused triage prompt in a dedicated session. *Validation: M0 — 50-item comparison test, Haiku vs. Sonnet, ≥85% agreement rate.*
- **A3:** Sufficient RSS-ingestible signal sources exist for the M0 focus domains (AI/LLM tooling, builder communities, creator economy). *Validation: M0 source registry population.*
- **A4:** ~~Telegram feedback command parsing can be implemented either via OpenClaw tool registration or direct Telegram Bot API integration.~~ **RESOLVED (peer review r1):** Direct Telegram Bot API for both delivery and feedback (AD-6). OpenClaw used for LLM inference only.
- **A5:** The nine-dimension scoring model from v1–v7 research is transferable to real-time triage via the three-gate simplification (conflict safety, automation potential, profile fit). *Validation: M0 scoring prompt test.*
- **A6:** Three to five sources per tier will produce sufficient signal volume during M0–M2 pilot without overwhelming the digest. *Validation: first 2 weeks of M1 — adjust threshold if volume is too high or too low.*

## Unknowns

- **U1:** Reddit API access viability. FIF is already gated on API terms review. Reddit is a high-value signal source (r/sysadmin, r/netsec) but may not be accessible programmatically within terms of service.
- **U2:** Discord server scanning mechanics. Requires bot tokens with channel read permissions. Which servers? What content? Legal and ToS implications unclear.
- **U3:** Freelance platform data access. Toptal and Upwork do not offer public APIs for browsing opportunities. Manual intake via `/scout add` may be the only path for these sources.
- **U4:** Where the 50-item test set for M0 scoring validation comes from. Options: manually curated from v1–v7 research findings, pulled from FIF's existing feed intel inbox (145 items), or synthetic. Each has different calibration properties.
- **U5:** Whether the research brief v0.5 (referenced in the input draft as parent document) exists outside the vault or needs to be reconstructed from v1–v7 dispatches. The individual dispatches exist; the umbrella brief does not.
- **U6:** Multi-model orchestration path. OpenClaw's `--model` override is broken (F6). Scout needs Haiku for triage, Sonnet for digest assembly, and Opus for monthly synthesis. Implementation options: separate cron jobs per model tier, model-specific OpenClaw agent configurations, or hybrid bash+claude-print approach.
- **U7:** Candidate registry query patterns at scale. The dedup logic and state machine transitions need indexed access. Flat files will be painful above ~50 candidates. SQLite (following FIF pattern) is the likely answer but needs design validation.

## System Map

### Components

| Component | Description | Build/Reuse |
|-----------|------------|-------------|
| Source registry | Structured list of signal sources with metadata (URL, type, frequency, yield score) | Build — vault-native YAML or SQLite |
| Ingestion adapters | Per-source-type modules that normalize raw content to candidate items. Types: RSS, API (HN), manual intake | Build — port FIF adapter pattern, new interface |
| Triage scoring | Three-gate classification (H/M/L) applied to each ingested item | Build — LLM prompt, dedicated session |
| Candidate registry | Persistent records with dedup, state machine, and lifecycle tracking | Build — SQLite (recommended) |
| Digest assembly | Template-based daily digest with scoring rationale and key insights | Build — LLM prompt (Sonnet-tier) |
| Delivery | Telegram (primary) + Discord (mirror) | Build — direct Bot API curl + Discord webhook (bypasses OpenClaw) |
| Feedback parser | Parse Danny's Telegram commands, update candidate registry | Build — direct Telegram Bot API polling (unified with delivery path) |
| Cron orchestration | Daily scan → score → digest → deliver pipeline | Build — LaunchAgent plists, dedicated session prompts |
| Monthly memo generator | Aggregates month's data into evaluation memo | Build — LLM prompt (Opus-tier, Danny+Claude session) |
| Graveyard | Rejected/killed patterns used for negative-match filtering | Build — initialized from v1–v7 rejected categories |

### Data Contracts

#### Normalized Item Schema (adapter → scoring interface)

Every ingestion adapter emits records conforming to this schema. This is the core interface contract tying ingestion, triage, dedup, registry, and digest assembly together.

```
source_id:         [registered source identifier]
source_type:       [rss | api | manual]
external_id:       [source-specific unique identifier — feed GUID, HN item ID, etc.]
title:             [item title or headline]
url:               [canonical URL to the source content]
author:            [author name if available, null otherwise]
published_at:      [ISO 8601 timestamp from source]
summary:           [first 500 chars of content or feed description]
raw_tags:          [tags/categories from source, if any]
ingested_at:       [ISO 8601 timestamp of ingestion]
content_hash:      [SHA-256 of title + url for deterministic dedup]
source_confidence: [H/M/L — inherited from source registry tier]
```

#### Candidate Record Schema

Every opportunity that clears triage gets a persistent record in SQLite. This schema is canonical for the candidate registry (AD-4).

```
candidate_id:        [UUID — auto-generated on insert]
title:               [descriptive name]
canonical_pattern:   [the underlying opportunity model, for dedup — e.g., "public-domain-ebook-publishing"]
source_urls:         [JSON array of source URLs where observed]
source_tier:         [highest-tier source that surfaced it — T1/T2/T3]
first_seen:          [ISO 8601 — date first surfaced]
last_seen:           [ISO 8601 — date most recently observed]
sighting_count:      [integer — incremented on dedup match]
conflict_gate:       [H/M/L]
automation_gate:     [H/M/L]
fit_gate:            [H/M/L]
evidence_grade:      [verified / supported / plausible / unverified]
confidence:          [H/M/L]
economics_note:      [brief text assessment]
distribution_note:   [brief text assessment]
demand_note:         [brief text assessment]
compounding_note:    [brief text assessment]
key_insight:         [Sonnet-generated 2-3 sentence explanation of why this matters]
state:               [new / acknowledged / bookmarked / researching / evaluating / parked / active / rejected / killed]
reason_code:         [text — why it's in current state]
feedback_history:    [JSON array of {date, command, reason} entries]
linked_sources:      [JSON array of related research memo paths, if any]
digest_appearances:  [JSON array of {digest_id, item_index} entries]
created_at:          [ISO 8601]
updated_at:          [ISO 8601]
```

#### Digest Mapping Table

Stores the identity mapping between digest item numbers and candidate records (required for feedback command resolution).

```
digest_id:      [unique identifier per digest — date-based, e.g., "2026-03-14"]
item_index:     [integer — position in digest, 1-based]
candidate_id:   [FK to candidate record UUID]
telegram_msg_id:[Telegram message ID of the delivered digest, for reply-context resolution]
created_at:     [ISO 8601]
```

When Danny sends `!bookmark 2`, the parser resolves via: most recent digest_id → item_index=2 → candidate_id. If Danny replies to a specific digest message, the parser uses telegram_msg_id for unambiguous resolution.

#### Source Registry Schema

```
source_id:        [unique identifier — kebab-case, e.g., "hn-show"]
name:             [human-readable name]
url:              [feed URL, API endpoint, or base URL]
source_type:      [rss | api | manual]
signal_tier:      [T1 / T2 / T3]
check_frequency:  [daily / every-2-days / weekly]
focus_domain:     [ai-llm / builder-community / creator-economy / infrastructure / general]
enabled:          [boolean]
yield_score:      [float 0.0–1.0 — items surfaced / items checked, rolling 30-day]
last_checked_at:  [ISO 8601]
last_item_seen:   [external_id of most recent item, for incremental polling]
parser_config:    [JSON — adapter-specific config, e.g., RSS selector paths, API params]
created_at:       [ISO 8601]
updated_at:       [ISO 8601]
```

### Dependencies

| Dependency | Direction | Nature |
|-----------|-----------|--------|
| FIF adapter pattern | Scout consumes pattern | Architectural reuse — adapter interface, not code sharing |
| Telegram Bot API | Scout consumes | Direct delivery + feedback (bypasses OpenClaw per AD-6) |
| v1–v7 research dispatches | Scout consumes data | Scoring calibration, graveyard initialization, domain knowledge |
| OpenClaw cron / LaunchAgent | Scout consumes | Scheduling infrastructure for daily pipeline |
| book-scout interaction pattern | Scout consumes pattern | Telegram command → Tess action → vault update pattern |
| Wisdom Library (future) | Scout monitors, receives metrics | Future feedback loop — design deferred until stream exists (see OSC-012) |

### External Code Repo

Yes. Scout's implementation involves Node.js adapters, SQLite schema, cron orchestration scripts, and prompt templates — consistent with FIF and book-scout patterns. Convention: `~/openclaw/opportunity-scout/`. Repo initialization during PLAN phase.

### Constraints

- **C1: Haiku SOUL.md ceiling.** Scout's autonomous functions MUST use dedicated cron session prompts, not SOUL.md behavior injection. This is a hard architectural constraint with a documented solution pattern.
- **C2: OpenClaw model override bug.** Multi-model orchestration cannot rely on `--model` override in OpenClaw cron. Workaround: separate agent configurations per model tier, or bypass OpenClaw for model-specific invocations (claude --print with explicit model).
- **C3: OpenClaw delivery bugs.** Telegram delivery via `delivery.to` is broken. Workaround: direct Telegram Bot API via curl for Scout digest delivery (follows operational architecture pattern, F12).
- **C4: Cost ceiling.** ≤$10/month API costs during pilot. Constrains source count, scan frequency, and model tier usage. Budget breakdown (expected volume):

  | Component | Volume | Model | Est. Monthly Cost |
  |-----------|--------|-------|-------------------|
  | Triage scoring | ~50 items/day × 30 days | Haiku | ~$1.00 |
  | Digest assembly | ~20 digests/month | Sonnet | ~$3–5.00 |
  | Monthly synthesis | 1/month | Opus (manual session) | ~$0 (session cost) |
  | **Total (Haiku triage)** | | | **~$4–6.00** |
  | **Total (Sonnet fallback triage)** | | | **~$12–18.00 — exceeds ceiling** |

  If Haiku fails M0 validation (A2) and Sonnet is required for triage, the cost ceiling must be renegotiated or source volume reduced.
- **C5: Attention budget.** Danny is a solo operator with limited time. Daily digest review must stay within 10–15 minutes. Monthly evaluation ≤30 minutes. Review throttles (1 research/day, 5 evaluations/month) are design constraints, not suggestions.
- **C6: Conflict safety.** Gate 1 is a hard filter. Direct DDI/DNS/network security monetization is blocked. Scout surfaces opportunities that leverage systems thinking and architecture skills applied across domains.
- **C7: No existing scanning habit.** Unlike most Crumb automation projects, this is creating a new behavior, not streamlining an existing one. Adoption risk is the primary project risk, not technical risk.

### Levers

- **L1: Triage threshold.** The H/M/L cutoff determines signal-to-noise ratio. Too aggressive = empty digests → Danny stops checking. Too permissive = noisy digests → Danny stops reading. This is the single highest-leverage calibration point.
- **L2: Source selection.** Which sources are monitored determines the opportunity space. M0 focus constraint (AI/LLM, builder communities, content/products) is the initial aperture.
- **L3: Digest format quality.** The "key insight" field — the 2–3 sentence explanation of why an item matters — is what makes or breaks daily review engagement. Sonnet-tier writing quality is justified here.
- **L4: Feedback friction.** How easy it is for Danny to respond to digest items. Simple Telegram commands (one word + item number) minimize friction. If feedback requires opening the vault or navigating files, engagement will drop.

### Second-Order Effects

- **Positive:** A working Scout creates a persistent awareness of the opportunity landscape that compounds over time. Even passed items build Danny's mental model of what's possible. The candidate registry becomes a searchable history of opportunity patterns.
- **Positive:** Scoring model calibration from Danny's feedback creates a progressively more personalized filter that learns what Danny actually values, not what a framework says he should value.
- **Negative:** A poorly calibrated Scout becomes an attention tax — a daily obligation that produces guilt when skipped and noise when reviewed. The abort criterion (M2, 30 days, <20% interesting) is the circuit breaker.
- **Negative:** Scout may surface opportunities that create decision fatigue or FOMO without actionable next steps. The throttles (1 research/day, 5 evaluations/month) are designed to prevent this.

## Domain Classification & Workflow Depth

- **Domain:** Software
- **Project class:** System (external repo, cron jobs, Node.js adapters)
- **Workflow:** Full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** Scout is a software system with adapters, a database, cron orchestration, prompt engineering, and delivery integration. The operational output serves career/financial goals, but the deliverables are software artifacts.

## Overlay Analysis

### Business Advisor

- **Lifecycle stage: IDEATION.** This is unvalidated. The right move is a thin M0 validation (can the system surface things Danny finds interesting?), not a polished production system. Every design decision should be evaluated against "is this needed for M0 validation, or is this premature?"
- **Value proposition:** Creating a capability Danny doesn't have (F10: no existing scanning practice). This is higher-risk than automating an existing process — there's no existing behavior to anchor onto.
- **Economic model:** Very low financial risk ($10/month). The ROI chain is long and unvalidated: Scout surfaces → Danny evaluates → Danny acts → revenue. Each step has dropout risk. But the cost is low enough that even modest value creation justifies the investment.
- **Strategic alignment:** Not in Danny's stated 6–12 month priorities (Crumb, customer intelligence, DDI expertise). BUT: low operational cost once running, and the research investment (v1–v7) is already sunk. Scout operationalizes that investment rather than letting it sit idle.

### Career Coach

- **Skill leverage:** Opportunity detection is a meta-skill that compounds across roles and employers. Even if Scout surfaces nothing actionable, the habit of systematic environmental scanning is professionally valuable.
- **Opportunity cost:** 10–15 min/day for a solo operator is not trivial. The system must earn that time by consistently surfacing items Danny finds worth reading. If it doesn't earn it within M2, abort.
- **Next role test:** Strong. Automated opportunity scanning is valuable regardless of employer or career stage.
- **Behavior creation risk:** Creating a new daily habit (checking Scout digest) is harder than improving an existing one. The threshold-based delivery design (suppress empty digests) is the right instinct — don't train Danny to skip reviews by sending empty ones.

## Architectural Decisions

### AD-1: Orchestration via dedicated cron jobs, NOT Tess SOUL.md

Scout's autonomous functions (scan, score, digest, deliver) run as dedicated cron jobs with focused session prompts. Tess SOUL.md is not modified. Each pipeline stage gets its own cron job with a single-purpose prompt. Rationale: F5 (Haiku SOUL.md injection ceiling is a proven failure mode). This follows the operational architecture pattern (F12): bash for coordination, dedicated LLM sessions for thinking.

### AD-2: Sibling to FIF, not extension

Scout shares FIF's adapter pattern and downstream processing concepts but is a separate codebase with its own repo. Rationale: source types are too heterogeneous for FIF's feed-oriented ingestion layer, and Scout has different scoring/storage/delivery requirements. Shared patterns, not shared code.

### AD-3: Vault data under Projects/opportunity-scout/data/

Scout operational data (candidates, digests, source registry, feedback, monthly memos) lives under the project directory, not `_system/`. `_system/` is for Crumb system infrastructure. Scout data is project-specific. Subdirectories: `data/digests/`, `data/candidates/`, `data/sources/`, `data/monthly/`, `data/ops/`.

### AD-4: SQLite for candidate registry

Following FIF's pattern. Candidate records need indexed access for dedup (match against canonical_pattern), state machine queries (find all candidates in state X), and aggregate queries (monthly memo generation). Flat files break down above ~50 candidates. SQLite is already proven in the Crumb ecosystem via FIF.

### AD-5: Model tiering via separate cron configurations

Given the OpenClaw `--model` override bug (F6), multi-model orchestration uses separate approaches per tier:
- **Haiku:** OpenClaw cron with default agent model (Haiku) for triage scoring
- **Sonnet:** `claude --print` with explicit `--model sonnet` for digest assembly, or a Sonnet-configured OpenClaw agent
- **Opus:** Not automated — monthly evaluation is a Danny + Claude (Crumb) session, not a cron job

### AD-6: Direct Telegram Bot API for all Telegram interaction

Given OpenClaw delivery bugs (F7, F8), Scout uses direct Telegram Bot API for **both** outbound delivery (digests) **and** inbound feedback command parsing. This eliminates the asymmetry of reliable delivery with unreliable feedback. Discord mirror uses a Discord webhook (also direct curl). OpenClaw is used for LLM inference (triage, digest assembly) only — not for transport. This follows the operational architecture pattern (F12) and provides a single, consistent Telegram integration path.

### AD-7: M0 constrained to RSS-ingestible + HN API sources

Non-feed sources (Reddit, Discord, freelance platforms) are deferred to post-M0. M0 validates the core loop (scan → score → digest → deliver → feedback) with sources that have clear, proven ingestion paths. This prevents the "scan orchestration is actually 5 separate integration projects" problem from blocking initial validation.

### AD-8: Threshold-based delivery from day one

Scout scans daily but only delivers a digest when items clear the triage threshold. Empty or near-empty digests are suppressed. This prevents the primary failure mode (training Danny to ignore digests) from the very first delivery. Stored in vault for auditability even when not delivered.

### AD-9: Weekly health heartbeat

To distinguish "no items today" from "pipeline broken," Scout sends a weekly health summary regardless of whether any digests were delivered that week. Format: "Scout healthy — N sources checked, N items scanned, N qualified, N digests delivered this week." Pipeline failures trigger an immediate ops alert (separate from the weekly heartbeat). This prevents silent suppression from masking operational failures.

### AD-10: Two-stage triage (item-wise filter, then batch rank)

M0 triage operates in two stages: (1) item-wise Haiku classification against the three gates — each item scored independently with a deterministic rubric; (2) batch Sonnet ranking of items that pass all gates — ordering by relevance, evidence strength, and novelty for digest presentation. This separates the cheap filtering step (Haiku, per-item) from the more expensive ranking/writing step (Sonnet, per-digest).

## Task Decomposition

### OSC-001: Research calibration data extraction
Extract scoring calibration data from v1–v7 research dispatches — what scored well, what was rejected with reasons, nine-dimension framework weights. Produce a structured calibration seed for the triage scoring prompt. Resolve U5 (locate or reconstruct the research brief v0.5).

- **Tag:** `#research`
- **Risk:** Low
- **Dependencies:** None
- **Acceptance criteria:** Structured calibration document exists with: rejected categories (graveyard seed), high-scoring patterns, dimension weight observations, and conflict-safety boundary examples from v5.

### OSC-002: Source registry design + M0 population
Implement source registry per the Source Registry Schema (Data Contracts section). Populate with M0 starting set constrained to RSS-ingestible + HN API sources. Resolve A3 (do sufficient RSS sources exist for M0 focus domains?).

- **Tag:** `#research` `#code`
- **Risk:** Low
- **Dependencies:** None (parallel with OSC-001)
- **Acceptance criteria:** Source registry exists with ≥3 sources per signal tier, conforming to the Source Registry Schema. Each source has a confirmed ingestion path (RSS URL or API endpoint). No sources requiring unsolved access problems (U1, U2, U3). Parser config populated for each source.

### OSC-003: Ingestion adapter architecture + RSS/HN adapters
Define adapter interface (input: source config → output: normalized item records). Implement RSS adapter (port FIF pattern to Scout codebase). Implement HN API adapter. External repo initialization.

- **Tag:** `#code`
- **Risk:** Medium — HN API rate limits and response format need validation
- **Dependencies:** OSC-002 (source registry defines what adapters consume)
- **Acceptance criteria:** Both adapters successfully ingest from ≥1 source each and produce normalized item records. Adapter interface is documented. External repo exists with initial commit.

### OSC-004: Triage scoring prompt + model validation
Design three-gate triage prompt (conflict safety, automation potential, profile fit) per AD-10 (item-wise Haiku filter, then batch Sonnet rank). Build 50-item test set: 20 items from v1–v7 research findings (known-good and known-bad), 20 items from FIF inbox (real-world signal), 10 synthetic edge cases (conflict-safety boundary, low-automation high-economics, etc.). Run Haiku vs. Sonnet comparison. Establish triage threshold.

- **Tag:** `#research` `#code`
- **Risk:** Medium — A2 validation (Haiku triage quality is unknown)
- **Dependencies:** OSC-001 (calibration data informs prompt design)
- **Acceptance criteria:** Test set composed of 20 v1–v7 items + 20 FIF inbox items + 10 synthetic edge cases. Haiku/Sonnet agreement rate ≥85% on three-gate scores. Triage threshold established. If agreement <85%, fallback plan documented with cost impact (Sonnet-only triage at ~$12–18/month — see C4 budget table).

### OSC-005: Candidate registry (SQLite)
Implement candidate registry per the Candidate Record Schema and Digest Mapping Table (Data Contracts section). Initialize with WAL (Write-Ahead Logging) mode for concurrent access safety (cron writes + feedback updates). State machine implementation (new → acknowledged / bookmarked → researching → evaluating → active/parked/rejected). Dedup logic matching against canonical_pattern. Graveyard initialization from OSC-001 rejected categories. SQLite is canonical for live state; vault markdown files are audit/archive artifacts.

- **Tag:** `#code`
- **Risk:** Low
- **Dependencies:** OSC-001 (graveyard seed data), OSC-003 (adapter output format defines what gets inserted)
- **Acceptance criteria:** CRUD operations work. WAL mode enabled. Dedup correctly matches repeated patterns via content_hash and canonical_pattern. State transitions enforce valid paths. Digest mapping table stores (digest_id, item_index, candidate_id, telegram_msg_id). Graveyard contains ≥3 rejected categories from research.

### OSC-006: Digest assembly + delivery pipeline
Digest template implementation (daily format from input draft §9). Sonnet-tier "key insight" generation per item (AD-10 batch ranking stage). Direct Telegram Bot API delivery (AD-6). Discord webhook mirror. Threshold-based suppression (AD-8). Weekly health heartbeat (AD-9). Vault archival of all digests (delivered or suppressed). On delivery, store the Telegram message ID and write digest mapping rows (digest_id, item_index, candidate_id, telegram_msg_id) to SQLite for feedback command resolution.

- **Tag:** `#code`
- **Risk:** Low — delivery infrastructure is proven, template is well-defined
- **Dependencies:** OSC-004 (triage scores), OSC-005 (candidate data + digest mapping table)
- **Acceptance criteria:** Digest renders correctly in Telegram. Key insights are coherent and specific (not generic). Digest mapping rows written on delivery (enables feedback resolution). Suppressed digests archived in vault. Discord mirror delivers. Weekly heartbeat delivered even if no digests that week.

### OSC-007: Cron orchestration
Daily pipeline: scan all M0 sources → score items → assemble digest → deliver (if threshold met) → archive. LaunchAgent plist(s) per AD-1. Bash coordination script per AD-1 and F12. Error handling: source failure doesn't block other sources; scoring failure suppresses digest with alert. Validate multi-model orchestration (AD-5 M0 validation task).

Pipeline reliability rules:
- **Idempotent ingest:** Each scan cycle uses source's `last_item_seen` for incremental polling. Re-running the same cycle produces no duplicate inserts.
- **Run IDs:** Each pipeline execution gets a unique run_id (timestamp-based). Digest delivery is gated on run_id to prevent duplicate sends.
- **Digest generation lock:** Only one digest per calendar day. If pipeline runs twice (manual + cron), the second run skips digest assembly.

- **Tag:** `#code`
- **Risk:** Medium — cron reliability, multi-step pipeline coordination, model tiering per AD-5
- **Dependencies:** OSC-003, OSC-004, OSC-005, OSC-006 (all pipeline stages must exist)
- **Acceptance criteria:** Pipeline runs unattended for 3 consecutive days. Source failures are logged but don't halt the pipeline. Digest is delivered when items clear threshold. No digest delivered when threshold not met (but archive written). No duplicate ingests or sends on re-run. Multi-model invocation (Haiku triage + Sonnet digest) confirmed working.

### OSC-008: Feedback command parser
Parse `!bookmark [N]`, `!research [N]`, `!pass [N] [reason]`, `!reject [N] [reason]`, `/scout add [url] [context]` from Telegram via direct Bot API polling (AD-6 — unified Telegram path). Resolve `[N]` via digest mapping table: most recent digest_id → item_index → candidate_id. If Danny replies to a specific digest message, use telegram_msg_id for unambiguous resolution. Update candidate registry state. Enforce throttles (1 research/day, 5 evaluations/month).

Acknowledgement responses (sent back via Bot API):
- Success: `"Bookmarked #2: [title]"`, `"Research queued for #3: [title] (1 of 1 daily)"`, `"Passed on #1: [title] — reason recorded"`
- Error: `"Item #7 not found in latest digest"`, `"Research limit reached (1/day) — try again tomorrow"`, `"Could not parse command. Usage: !bookmark [N]"`

- **Tag:** `#code`
- **Risk:** Medium — Bot API polling reliability, command parsing edge cases
- **Dependencies:** OSC-005 (candidate registry + digest mapping table), OSC-006 (digest delivery stores mapping rows)
- **Acceptance criteria:** All five commands correctly update candidate state via digest mapping resolution. Acknowledgement response sent for every command (success or error). Throttles enforced. Reply-to-message resolution works when Danny replies to a specific digest. Command processing latency ≤30 seconds.

### OSC-009: M1 validation gate
Run Scout pipeline for 3 weeks (21-day window). Collect metrics: digest delivery rate, review confirmation, bookmark rate, items surfaced per day, Haiku triage accuracy (spot-check). Assess M1 acceptance criteria.

- **Tag:** `#decision`
- **Risk:** Low (technical), HIGH (behavioral — A1 is the biggest project risk)
- **Dependencies:** OSC-007 (pipeline must be running), OSC-008 (feedback must be capturable)
- **Acceptance criteria:** Within a 21-day window: at least 10 scan cycles completed, at least 5 qualifying digests delivered and reviewed. Bookmark/research rate ≥10% of delivered items. Median review time 10–15 minutes. At least 1 item bookmarked or researched in week 1. If zero engagement, diagnose: is the content wrong (source/scoring problem) or is the channel wrong (delivery/format problem)?

### OSC-010: Source yield scoring + calibration
Track signal-to-noise per source. Apply deprioritization policy (30 days zero items → weekly; 90 days → flag for review). Tune triage threshold based on M1 feedback data. Update scoring prompt if Danny's feedback reveals systematic miscalibration.

- **Tag:** `#code` `#research`
- **Risk:** Low
- **Dependencies:** OSC-009 (needs M1 data)
- **Acceptance criteria:** Source yield scores are computed and stored. At least one source priority adjustment made based on data. Triage threshold has been adjusted at least once from M0 baseline.

### OSC-011: Monthly evaluation memo generator
Aggregate month's data into structured memo (template from input draft §9). Signal summary, portfolio status, top signals, landscape shifts, scoring model notes, behavioral impact assessment. Produced during a Danny + Claude session (Opus-tier, not automated).

- **Tag:** `#code` `#writing`
- **Risk:** Low
- **Dependencies:** OSC-010 (needs calibrated data), OSC-005 (candidate registry aggregation)
- **Acceptance criteria:** First monthly memo produced. Contains at least one concrete portfolio observation. Evaluation takes ≤30 minutes. Scoring model notes section has at least one calibration observation.

### OSC-012: Execute Mode feedback interface design
Define four-metric schema (time-per-task actuals, revenue data, friction log, market response). Design integration point for stream → Scout data flow. This is a design artifact — implementation deferred until an Execute Mode stream exists.

- **Tag:** `#research`
- **Risk:** Low
- **Dependencies:** None (can proceed in parallel)
- **Acceptance criteria:** Schema documented. Integration pattern described. At least one concrete example showing how Wisdom Library data would flow into Scout scoring.

### Dependency Graph

```
OSC-001 ──→ OSC-004 ──→ OSC-006 ──→ OSC-007 ──→ OSC-009 ──→ OSC-010 ──→ OSC-011
OSC-002 ──→ OSC-003 ──↗         ↗                       ↗
                  OSC-005 ──────┘                 OSC-008 ┘
OSC-012 (independent)
```

### Milestone Mapping

| Milestone | Tasks | Gate Criteria |
|-----------|-------|--------------|
| M0: Source + Scoring Validation | OSC-001, OSC-002, OSC-003, OSC-004, OSC-005 | Sources ingest, Haiku triage ≥85% agreement, candidate registry works, multi-model invocation confirmed |
| M1: First Digest Production | OSC-006, OSC-007, OSC-008 | 5 qualifying digests reviewed within 21-day window, ≥10 scan cycles completed, bookmark/research rate ≥10%, ≥1 bookmark/research in week 1 |
| M2: Feedback Loop + Calibration | OSC-009, OSC-010 | Bookmark rate ≥20%, duplicate rate <15%, ≤2 consecutive skips. **ABORT if <20% bookmark/research rate after 30 days OR <5 digests delivered in any 30-day period.** |
| M3: Monthly Evaluation | OSC-011, OSC-012 | First memo produced, ≤30 min evaluation, ≥1 scoring calibration |
| M4: Steady State | (operational) | 30+ consecutive days running, ≥1 opportunity acted on that Danny wouldn't have found otherwise |

### Metric Definitions

| Metric | Definition |
|--------|-----------|
| Bookmark rate | bookmarked items / total delivered items (across all digests in period) |
| Research rate | researched items / total delivered items |
| Bookmark/research rate | (bookmarked + researched) / total delivered items |
| Duplicate rate | items matched to existing candidates via dedup / total newly ingested items |
| Interesting rate | bookmark/research rate (alias — used in abort criterion) |
| Digest delivery rate | digests delivered / scan cycles completed |

## Open Questions

1. **U5 — Research brief v0.5:** The input draft references this as parent doc but it's not in the vault. Either locate it externally or reconstruct the framework section from v1–v7 dispatch commonalities during OSC-001.

2. **Relationship to book-scout:** book-scout is a search-and-download tool for a specific source (Anna's Archive). Scout is a monitoring system across heterogeneous sources. The relationship is pattern reuse (Telegram interaction model), not functional overlap. No integration needed beyond shared infrastructure.

3. **Aperture expansion timing:** When does Scout graduate from M0–M2 focus constraint to broader scanning? Recommendation: after M2 acceptance criteria are met AND 30+ days of stable operation. Expansion is a deliberate decision during monthly evaluation, not an automatic graduation.

## M0 Validation Tasks

These were previously listed as open questions but are answered by architectural decisions. They require M0 validation to confirm the decisions are viable.

1. **Multi-model orchestration validation (AD-5):** Confirm `claude --print --model sonnet` can be invoked reliably from a bash orchestration script. Verify a Sonnet-configured OpenClaw agent works (the `--model` override bug is in cron override, not agent default config). Part of OSC-007 acceptance criteria.

2. **Telegram Bot API integration validation (AD-6):** Confirm bot token can send messages (delivery) and poll for updates (feedback) via direct curl. Validate getUpdates polling or webhook approach for inbound commands. Part of OSC-006 and OSC-008 acceptance criteria.
