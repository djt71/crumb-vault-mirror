---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/opportunity-scout/design/specification.md
artifact_type: spec
artifact_hash: b6d0d09a
prompt_hash: decc1675
base_ref: null
project: opportunity-scout
domain: software
skill_origin: peer-review
created: 2026-03-14
updated: 2026-03-14
status: active
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 86562
    attempts: 1
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-specification-openai.json
  google:
    http_status: 200
    latency_ms: 31388
    attempts: 1
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 66891
    attempts: 2
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 21262
    attempts: 1
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Opportunity Scout Specification

**Artifact:** Projects/opportunity-scout/design/specification.md
**Mode:** full
**Reviewed:** 2026-03-14
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning

---

## OpenAI (gpt-5.4)

Below is a structured review of the specification.

## Overall assessment

This is a strong spec: it is unusually explicit about constraints, known bugs, adoption risk, milestones, and architecture tradeoffs. The biggest strengths are its realism about failure modes and its disciplined M0/M1 scoping.

I agree with the spec's central thesis that **behavioral adoption is likely the primary project risk**. However, I would elevate **technical reliability of the end-to-end loop** to nearly equal importance, specifically:
- scoring quality/calibration,
- feedback capture reliability,
- item identity stability across digests,
- orchestration/model invocation reliability.

Those are not "harder than adoption," but they are essential enough that if they are shaky, the behavioral experiment becomes invalid.

---

# Findings

## Correctness / Internal consistency / Feasibility

- [F1]
- [Severity]: STRENGTH
- [Finding]: The spec correctly centers known platform constraints (Haiku prompt-execution limits, OpenClaw model override bug, OpenClaw delivery bugs) as first-order architectural drivers rather than implementation footnotes.
- [Why]: This prevents a common failure mode where architecture is designed around idealized platform behavior rather than observed behavior.
- [Fix]: None.

- [F2]
- [Severity]: STRENGTH
- [Finding]: AD-1, AD-5, and AD-6 are internally consistent with the listed facts and constraints: dedicated cron/session prompts for autonomy, explicit model-tier workarounds, and direct Telegram delivery.
- [Why]: The architecture follows directly from the facts instead of fighting them.
- [Fix]: None.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: The spec treats "delivery" as bypassing OpenClaw, but "feedback parser" remains undecided between OpenClaw tools and direct Telegram Bot API. This creates an architectural split in the most operator-visible loop.
- [Why]: If outbound delivery is direct but inbound commands depend on OpenClaw, reliability and observability become asymmetric. A digest may arrive reliably while feedback silently fails or is delayed, undermining the calibration loop.
- [Fix]: Decide in M0 that **both outbound and inbound Telegram handling use direct Bot API** unless there is a strong reason not to. Use OpenClaw only for thinking, not transport.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Digest item numbering is referenced by feedback commands (`!bookmark [N]`, etc.), but the spec does not define a durable identity mapping between digest item number and candidate record.
- [Why]: If digests are regenerated, suppressed, edited, or mirrored across channels, item number alone is ambiguous. This is a likely operational bug source.
- [Fix]: Add a required field such as `digest_item_id` or `presentation_id` linked to a specific digest instance and candidate ID. Feedback commands should resolve `[digest_id, item_number] -> candidate_id`.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: The spec suppresses empty digests from day one, which is sensible, but it does not define how the operator distinguishes "no digest because no opportunities" from "no digest because pipeline failed."
- [Why]: Silent suppression and silent failure look identical to the operator, which can damage trust and hide operational issues.
- [Fix]: Add an explicit lightweight heartbeat behavior, e.g. one of:
  - a weekly "Scout healthy, no qualifying items on X days" summary,
  - an ops-only alert on failure,
  - a minimal "no qualifying items today" only during the first 2 weeks of onboarding, then suppress afterward.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: The M1 gate requires "5 consecutive digests delivered + reviewed," but AD-8 intentionally suppresses digests below threshold.
- [Why]: These are in tension. If suppression works as designed, there may not be 5 consecutive delivered digests even in a healthy system.
- [Fix]: Redefine M1 as something like: "5 qualifying digests reviewed within a 14–21 day period" or "5 scan cycles with visible operator acknowledgement, of which at least 3 produce digests."

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: The state machine is plausible, but its transitions are underspecified relative to the actual user commands and throttles.
- [Why]: For example: what state does `!pass` imply? Is `rejected` terminal? Can `parked` return to `researching`? What happens when the same canonical pattern reappears after rejection?
- [Fix]: Add an explicit state transition table with:
  - allowed command per state,
  - terminal vs reversible states,
  - dedup behavior when a known pattern resurfaces.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: The dedup strategy mentions matching against `canonical_pattern`, but the spec does not define how `canonical_pattern` is generated or maintained.
- [Why]: Dedup quality is central to avoiding operator fatigue. Poor canonicalization will either spam duplicates or collapse distinct opportunities incorrectly.
- [Fix]: Define a first-pass deterministic dedup scheme:
  - source URL normalization,
  - title similarity,
  - source-specific ID,
  - optional LLM-assisted pattern labeling only after deterministic checks fail.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: The three-gate triage model may be too compressed for ranking within "acceptable" items.
- [Why]: Conflict safety, automation potential, and profile fit are strong filters, but they do not capture urgency, monetization path clarity, effort horizon, or novelty. That may be acceptable for filtering, but not for ordering digest items.
- [Fix]: Keep the three gates for inclusion/exclusion, but add a lightweight secondary rank field for digest ordering, e.g.:
  - immediacy,
  - expected leverage,
  - evidence strength.

- [F10]
- [Severity]: STRENGTH
- [Finding]: The spec explicitly distinguishes M0 validation of the core loop from later source expansion and avoids trying to solve Reddit/Discord/freelance ingestion up front.
- [Why]: This sharply reduces risk of turning the pilot into multiple integration projects.
- [Fix]: None.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: The cost ceiling is stated (<=\$10/month), but no rough usage budget is attached to M0/M1 operations.
- [Why]: Without an estimated scan volume x scoring calls x digest generation cadence, the cost constraint is not actionable.
- [Fix]: Add a monthly budget table estimating:
  - sources/day,
  - items/day,
  - Haiku triage calls/day,
  - Sonnet digest calls/week,
  - projected spend under low/expected/high volume.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: Failure handling is underspecified for partial pipeline success. The spec says source failure should not block others, and scoring failure suppresses digest with alert, but it does not define retry behavior, idempotency, or duplicate-send prevention.
- [Why]: Cron-driven pipelines often fail not by crashing but by producing duplicate inserts, duplicate digests, or inconsistent state.
- [Fix]: Add operational rules for:
  - idempotent ingest per source/check window,
  - digest generation lock per day/run,
  - retry policy,
  - duplicate-send guard using run IDs.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not define whether triage occurs item-by-item or batch-wise, nor how context from prior items influences scoring.
- [Why]: Batch scoring may reduce cost but introduce inconsistent calibration; item-wise scoring is simpler but may increase cost and reduce comparative ranking quality.
- [Fix]: Specify M0 behavior: e.g. item-wise Haiku triage with a deterministic rubric, then digest-level Sonnet ranking over shortlisted items.

- [F14]
- [Severity]: MINOR
- [Finding]: "Candidate registry" and "graveyard" are conceptually clear, but the exact negative-match filtering mechanism is not described.
- [Why]: Reviewers can infer intent, but implementation clarity would improve if the graveyard had examples and explicit matching behavior.
- [Fix]: Add examples of graveyard rules: exact categories, pattern tags, or embedding/similarity-based exclusion if later.

- [F15]
- [Severity]: STRENGTH
- [Finding]: The spec has clear abort criteria and recognizes the risk of creating an attention tax.
- [Why]: This is unusually good product discipline and improves feasibility.
- [Fix]: None.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: M2 metrics include "bookmark rate >=20%, duplicate rate <15%," but the denominator definitions are missing.
- [Why]: Without precise metric definitions, gate decisions will be subjective.
- [Fix]: Define each metric explicitly, e.g.:
  - bookmark rate = bookmarks / delivered candidates,
  - duplicate rate = candidates marked duplicate / total newly surfaced candidates,
  - interesting rate = bookmarked or researched / delivered candidates.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: Security/privacy considerations for direct Telegram Bot API handling are absent.
- [Why]: Even for a personal system, bot tokens, chat IDs, polling offsets, logs, and source content retention should be handled explicitly.
- [Fix]: Add a minimal security section:
  - token storage location,
  - log redaction,
  - allowed sender validation,
  - retention policy for raw message payloads.

- [F18]
- [Severity]: MINOR
- [Finding]: The repo/data boundary is mostly clear, but storing "operational data under the project directory" while also using SQLite and vault archival may create dual-source-of-truth confusion.
- [Why]: It should be obvious what is canonical: DB, YAML, or archived digest markdown.
- [Fix]: State explicitly:
  - SQLite is canonical for live state,
  - vault files are audit/archive/export artifacts,
  - source registry may be YAML or SQLite, but choose one for M0.

---

## Completeness / Missing essential elements

- [F19]
- [Severity]: CRITICAL
- [Finding]: The spec lacks a concrete definition of the normalized item schema emitted by adapters and consumed by scoring/registry.
- [Why]: This is the core contract tying ingestion, triage, dedup, registry, and digest assembly together. Without it, multiple tasks depend on an undefined interface.
- [Fix]: Add a mandatory normalized item schema with fields such as:
  - `source_id`
  - `source_type`
  - `external_id`
  - `title`
  - `url`
  - `author`
  - `published_at`
  - `summary/snippet`
  - `raw_tags`
  - `ingested_at`
  - `content_hash`
  - `source_confidence`

- [F20]
- [Severity]: CRITICAL
- [Finding]: The spec does not define the candidate record schema, despite referencing "full candidate record fields (from input draft SS6)," which is not present in the artifact.
- [Why]: This makes a central implementation task dependent on an unavailable document section.
- [Fix]: Inline the candidate schema into this spec or attach it as an appendix. At minimum include IDs, lifecycle state, source links, triage outputs, rationale, dedup keys, timestamps, and feedback history.

- [F21]
- [Severity]: SIGNIFICANT
- [Finding]: The source registry schema is mentioned at a high level but not fully specified.
- [Why]: Source frequency, parser config, category labels, and enable/disable flags are likely needed immediately.
- [Fix]: Define a source schema including:
  - `source_id`
  - `name`
  - `url/feed_url/api_endpoint`
  - `source_type`
  - `check_frequency`
  - `enabled`
  - `focus_domain`
  - `yield_score`
  - `last_success_at`
  - `last_item_seen`
  - `parser_config`

- [F22]
- [Severity]: SIGNIFICANT
- [Finding]: Feedback acknowledgement UX is missing.
- [Why]: If a user sends `!bookmark 2`, they need confirmation of what happened, especially when numbers may be ambiguous.
- [Fix]: Add response templates like: "Bookmarked #2: [title]" and "Could not resolve item #2 in latest digest."

- [F23]
- [Severity]: SIGNIFICANT
- [Finding]: No explicit observability/ops dashboard or log review mechanism is defined.
- [Why]: A daily automated system with multiple moving parts needs lightweight operational visibility.
- [Fix]: Add a daily/weekly ops artifact:
  - last run status,
  - sources checked,
  - items ingested,
  - items scored,
  - digest delivered/suppressed,
  - failures.

---

## Clarity / Spec quality

- [F24]
- [Severity]: STRENGTH
- [Finding]: The spec is clear about what is deferred, especially Reddit/Discord/freelance platforms and Execute Mode integration.
- [Why]: Good boundary management improves execution.
- [Fix]: None.

- [F25]
- [Severity]: STRENGTH
- [Finding]: Milestones are sensibly staged and tied to validation rather than feature completeness.
- [Why]: This aligns with the unvalidated nature of the project.
- [Fix]: None.

- [F26]
- [Severity]: MINOR
- [Finding]: Some acceptance criteria refer to absent sections of the "input draft" (e.g. "SS6", "SS9"), which weakens standalone readability.
- [Why]: A spec review should not require reconstructing missing parent sections.
- [Fix]: Inline or summarize any externally referenced required structures/templates.

---

# Unverifiable claims requiring grounded verification

Per your instruction, I am flagging claims I cannot independently verify from the artifact itself.

- [F27]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Haiku cannot reliably execute complex procedures from SOUL.md... documented solution in `_system/docs/solutions/haiku-soul-behavior-injection.md`."
- [Why]: This may be true in the local system context, but it is not independently verifiable from the artifact alone.
- [Fix]: Link or quote the relevant test evidence/results in the spec appendix.

- [F28]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "OpenClaw `--model` override is broken (#9556/#14279)."
- [Why]: The GitHub issue numbers and the bug claim are specific but not independently verifiable here.
- [Fix]: Add repository name, issue URLs, and a one-line summary of observed local repro.

- [F29]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "OpenClaw `delivery.to` is broken (v2026.2.25)."
- [Why]: Specific versioned bug claim without a verifiable source in the artifact.
- [Fix]: Add issue link, changelog reference, or local repro note.

- [F30]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "DM pairings in OpenClaw are in-memory only -- lost on gateway restart."
- [Why]: Specific product behavior not verifiable here.
- [Fix]: Add source reference or test note.

- [F31]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "book-scout (phase: DONE) provides a proven pattern..."
- [Why]: Internal system status claim not verifiable from this artifact.
- [Fix]: Add a pointer to the book-scout spec or implementation artifact.

- [F32]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "FIF is in TASK phase with production RSS/Atom ingestion. HN and arXiv adapters are live."
- [Why]: Internal project status and implementation state are not independently verifiable here.
- [Fix]: Add repo/spec references or remove "production/live" wording unless linked.

- [F33]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Source: v5 dispatch, confidence 0.78" for conflict safety around Infoblox/DDI monetization.
- [Why]: Internal source and confidence score not verifiable here.
- [Fix]: Summarize the v5 reasoning directly in the spec or append citation details.

- [F34]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "145 items" in FIF's existing feed intel inbox.
- [Why]: Specific statistic not verifiable from the artifact.
- [Fix]: Add snapshot date/source or soften to approximate wording if exactness is not needed.

---

# Answers to the specific reviewer questions

## 1) Is behavioral adoption really the primary risk?

**Yes, mostly.** I agree with the spec that adoption is the top product risk because there is no existing behavior to streamline.

But I would call out two technical risks as almost co-equal because they directly determine whether the behavioral test is fair:

1. **Scoring quality/calibration risk**
   - If triage is weak, Danny won't engage, but that does not mean the concept failed.
   - This is the most important technical risk.

2. **Feedback loop reliability risk**
   - If delivery works but command parsing or state updates are flaky, calibration data will be corrupted or absent.
   - That can masquerade as an adoption failure.

3. **Identity/dedup reliability risk**
   - Repeated or ambiguously referenced items will quickly create annoyance and distrust.

So: **adoption is primary**, but **triage calibration and feedback reliability deserve equal operational attention in M0/M1**.

## 2) Is the three-gate model sound?

**As a first-pass filter: yes. As the whole scoring model: no.**

The simplification is sound for M0 if the goal is fast triage:
- conflict safety,
- automation potential,
- profile fit

These are high-signal gating dimensions.

However, the reduction loses important signal needed for ranking and operator trust:
- effort horizon / time-to-first-value,
- evidence strength,
- monetization clarity,
- novelty / non-obviousness,
- urgency / timing.

Recommendation:
- Keep the three gates as **hard/soft screening gates**.
- Add **1-3 lightweight ranking dimensions** for shortlisted items only.

## 3) Is direct Telegram Bot API delivery the right tradeoff?

**Yes.** Given the stated OpenClaw delivery bugs, bypassing it for delivery is the right choice.

I would go further:
- also bypass OpenClaw for inbound Telegram feedback,
- use one direct Telegram integration path for both send and receive,
- reserve OpenClaw for LLM inference only.

That reduces maintenance, not increases it, because it avoids split transport semantics.

The maintenance burden only grows if you keep:
- direct outbound transport,
- OpenClaw inbound command path,
- and mirrored Discord via yet another path.

## 4) Is SQLite right for 200+ candidates?

**Yes, SQLite is the right choice.**

For this use case, SQLite is better than flat files because you need:
- dedup queries,
- lifecycle state transitions,
- aggregate reporting,
- source yield scoring,
- monthly memo summaries,
- command-driven updates.

At 200+ candidates, flat files are still possible, but they become awkward exactly where this system derives value: querying and calibration.

Recommended compromise:
- **SQLite as canonical state**
- markdown/YAML only for exports, archive, and human-readable digests.

## 5) Is M0 (RSS + HN API only) too narrow?

**No, it is the right scope for the pilot.**

The pilot needs to validate:
- ingestion,
- triage quality,
- digest usefulness,
- delivery,
- feedback.

RSS + HN are sufficient to test those mechanics.

The only caveat: if the value proposition specifically depends on opportunity types that are underrepresented in feeds, then M0 could understate the concept's value. To hedge that:
- include a small **manual `/scout add` lane during M0**
- so non-feed opportunities can still enter the same scoring and digest pipeline.

That gives you a broader concept test without reopening the ingestion complexity.

---

# Recommended priority fixes

If I were tightening this spec before implementation, I'd do these first:

1. **Define the normalized item schema**.
2. **Define the candidate registry schema** in-line.
3. **Unify Telegram transport**: direct Bot API for both delivery and feedback.
4. **Define durable digest item identity mapping** for feedback commands.
5. **Resolve M1 gate inconsistency** with threshold-based suppression.
6. **Add metric denominator definitions** for bookmark/interesting/duplicate rates.
7. **Add idempotency + duplicate-send protections** for cron pipeline.
8. **Add a lightweight budget estimate** against the $10/month target.

---

# Bottom line

This is a **good and implementation-ready spec in structure**, but **not yet implementation-safe** in interfaces. The main missing pieces are the data contracts and some reliability semantics around digest identity, feedback handling, and pipeline failure visibility.

If those are added, the design becomes much stronger and the M0/M1 experiment will be much more trustworthy.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the Opportunity Scout specification.

### Unverifiable Claims Review
Per your instructions, the following claims cannot be independently verified and are flagged for grounded verification:

- **[REV-001]**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: GitHub/Issue references for OpenClaw bugs ("OpenClaw `--model` override is broken (#9556/#14279)").
- **Why:** I cannot verify the existence, status, or context of these specific issue numbers for the OpenClaw framework.
- **Fix:** Verify these issues are accurately described and check if recent patches to OpenClaw have resolved them before hardcoding workarounds.

- **[REV-002]**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: Software version and specific bug behavior ("OpenClaw `delivery.to` is broken (v2026.2.25). Gateway ignores the stored value...").
- **Why:** I cannot independently verify the version history or the internal gateway routing behavior of OpenClaw.
- **Fix:** Confirm this regression is still present in the current environment before committing to the direct Telegram API bypass (AD-6).

- **[REV-003]**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: External document references ("Source: `_system/docs/solutions/haiku-soul-behavior-injection.md`" and "Danny's employer is Infoblox... Source: v5 dispatch").
- **Why:** These rely on private, local vault data that cannot be externally validated.
- **Fix:** Ensure these documents and constraints exist as described in the local environment and are accessible to the implementation agent.

---

### System Specification Review

- **[REV-004]**
- **Severity:** CRITICAL
- **Finding:** Missing state-mapping logic for Telegram feedback commands (OSC-008).
- **Why:** The spec states Danny will reply with `!bookmark [N]` or `!research [N]`. However, Telegram is stateless. When the parser receives `!bookmark 2`, it has no inherent way to know which SQLite UUID corresponds to item "2" in that specific day's digest. If Danny replies to yesterday's digest, it could map to the wrong item entirely.
- **Fix:** Update OSC-006 (Digest Assembly) to store a daily mapping table in SQLite (e.g., `digest_date, item_index, candidate_id`). Update OSC-008 to look up the `candidate_id` using this mapping, ideally requiring Danny to "Reply" to the specific digest message so the parser can extract the message ID for context.

- **[REV-005]**
- **Severity:** SIGNIFICANT
- **Finding:** Concurrency/Locking risk in SQLite architecture (AD-4, OSC-005, OSC-007, OSC-008).
- **Why:** The system uses cron jobs to write to SQLite (batch inserts/updates) while simultaneously polling or receiving webhooks from Telegram for feedback updates. SQLite is file-based and prone to `database is locked` errors during concurrent write attempts, especially if a Node.js adapter holds a transaction open during an LLM call.
- **Fix:** Specify WAL (Write-Ahead Logging) mode in the SQLite initialization step in OSC-005, and ensure adapter scripts decouple LLM network calls from database write transactions.

- **[REV-006]**
- **Severity:** SIGNIFICANT
- **Finding:** Ambiguity in handling the M1 "Abort Criterion" (M2 Gate).
- **Why:** The spec states: "ABORT if <20% interesting after 30 days." However, because AD-8 suppresses empty/low-quality digests entirely, Danny might receive very few digests. If he receives only 2 digests in 30 days, but finds 1 item interesting, the rate is 50%, but the system is practically dead.
- **Fix:** Define the baseline volume expectation for the 20% threshold. E.g., "ABORT if <20% of delivered items are interesting OR if <5 digests are delivered in a 30-day period."

- **[REV-007]**
- **Severity:** MINOR
- **Finding:** No purge or archiving strategy for raw ingested feed items.
- **Why:** RSS feeds and HN API will generate thousands of raw items monthly. The Candidate Registry (SQLite) filters these via dedup and triage, but if raw failed/un-triaged items are stored indefinitely, the database will bloat.
- **Fix:** Add a cleanup routine to OSC-007 (Cron orchestration) to delete un-triaged or L-scored raw items older than 30 days.

- **[REV-008]**
- **Severity:** STRENGTH
- **Finding:** Highly pragmatic, risk-aware task decomposition.
- **Why:** The choice to enforce M0 focus constraints (RSS/HN only), defer non-API sources, and explicitly define "workarounds as architecture" (e.g., direct bash/curl orchestration due to LLM/framework limits) shows excellent systems-engineering maturity. It isolates the pilot's core value loop from integration hell.

---

### Answers to Specific Reviewer Questions

**1. The spec identifies behavioral adoption (A1) as the primary risk, not technical complexity. Do you agree? Are there technical risks that deserve equal or greater attention?**
Yes, I strongly agree. Automated systems that push content to humans fail almost exclusively on the human's failure to engage, leading to "alert fatigue." However, there is one technical risk of equal weight: **Feedback Friction (A4/OSC-008)**. If the technical implementation of the Telegram parser fails to perfectly map a simple `!bookmark 2` command to the database, the friction to fix it will instantly destroy the behavioral adoption. The technical mapping gap identified in [REV-004] is a direct threat to the behavioral risk.

**2. The three-gate triage model (conflict safety, automation potential, profile fit) reduces a nine-dimension evaluation to three fast gates. Is this simplification sound, or does it lose critical signal?**
It is highly sound for a first-pass (M0/M1) filter. A lightweight model (Haiku) will hallucinate or degrade if asked to evaluate 9 nuanced dimensions across dozens of items in a single cron run. Three gates essentially act as a high-recall, moderate-precision sieve. Deep evaluation (the 9 dimensions) should be reserved for the Sonnet-tier digest assembly or Danny's monthly Opus-tier review. This perfectly balances API cost (C4) with signal extraction.

**3. The spec proposes direct Telegram Bot API delivery (bypassing OpenClaw) due to known delivery bugs. Is this the right tradeoff, or does it create maintenance burden by having two delivery paths?**
It is the right tradeoff for a pilot (M0-M2), but it is technical debt. If OpenClaw is the primary OS framework, bypassing it fragments your operational logging and error handling. *Suggestion:* Implement the bypass, but document an explicit M3/M4 transition task to revert to OpenClaw delivery once issues #9556/#14279 are resolved upstream.

**4. The candidate registry uses SQLite following the FIF pattern. For a system that might have 200+ candidates over time, is SQLite the right choice, or would flat files (YAML/MD) be simpler and sufficient?**
SQLite is absolutely the correct choice here. While flat files are fine for 200 static records, this system requires:
1. State machine transitions (New -> Bookmarked -> Parked)
2. Complex querying (finding all items in X state for the monthly memo)
3. Deduplication against a `canonical_pattern`
Doing this with YAML/MD requires loading all files into memory, parsing them, running array filters, and rewriting them to disk, which is fragile and slow. SQLite handles this natively and safely.

**5. The M0 constraint (RSS + HN API sources only) limits initial validation. Is this too narrow to validate the core value proposition, or is it the right scope for a pilot?**
It is exactly the right scope. The core value proposition is **not** "can we scrape Reddit?" The core value proposition is "if an AI hands Danny a highly relevant opportunity, will he engage with it?" RSS and HN provide enough high-quality signal to test the LLM triage logic, the digest formatting, and Danny's behavioral response. Adding web-scraping or Discord ToS battles in M0 would distract from validating the actual human-in-the-loop thesis.

---

## DeepSeek (deepseek-reasoner)

## Structured Review: Opportunity Scout Specification

**Overall Assessment:** This is a well-structured, thorough specification that demonstrates strong systems thinking. It correctly identifies behavioral adoption as the primary risk, designs around known platform constraints, and proposes a pragmatic, phased validation approach. The architectural decisions are sound and justified.

### Findings

**F1**
- **Severity:** STRENGTH
- **Finding:** Clear problem statement and context setting. The spec effectively establishes that the problem is a complete absence of a capability (no scanning practice) rather than an inefficiency in an existing process.
- **Why:** This foundational clarity correctly orients the entire project toward behavior creation and validation, influencing risk assessment and design priorities.

**F2**
- **Severity:** STRENGTH
- **Finding:** Comprehensive and honest accounting of platform constraints (F5-F8). The spec doesn't ignore known bugs but explicitly designs workarounds (AD-1, AD-5, AD-6).
- **Why:** Grounding the design in documented system limitations prevents unrealistic technical assumptions and promotes feasible solutions from the outset.

**F3**
- **Severity:** STRENGTH
- **Finding:** Explicit mapping of project phases (M0-M4) to concrete, measurable acceptance criteria and abort conditions (e.g., M2: ABORT if <20% interesting after 30 days).
- **Why:** This creates clear go/no-go decision points, aligns the team, and prevents sunk cost fallacy in a high-behavioral-risk project.

**F4**
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** References to specific OpenClaw bug IDs (#9556, #14279), a specific software version (v2026.2.25), and an internal document (`_system/docs/solutions/haiku-soul-behavior-injection.md`) cannot be independently verified.
- **Why:** While these references lend credibility and suggest grounded design, their accuracy is crucial as they drive major architectural decisions (AD-1, AD-5, AD-6).
- **Fix:** Annotate these references in the spec as requiring validation against the current state of the OpenClaw codebase and internal documentation vault.

**F5**
- **Severity:** MINOR
- **Finding:** The "Second-Order Effects" section is excellent but could be expanded. The "Negative" effect of "decision fatigue or FOMO" is noted, but the proposed throttles (1 research/day) are only mentioned elsewhere.
- **Why:** Explicitly linking the prescribed mitigation (throttles) to the identified risk in this section would strengthen the narrative of proactive risk management.
- **Fix:** In the "Negative" second-order effect regarding decision fatigue, add a parenthetical: "(mitigated by the hard-coded throttles: 1 research/day, 5 evaluations/month)."

**F6**
- **Severity:** SIGNIFICANT
- **Finding:** Assumption A2 states Haiku's triage quality is "unknown," yet the validation (M0) and a task (OSC-004) depend on it. The fallback plan (Sonnet-only) is mentioned but not integrated into cost constraints (C4, <=\$10/month) or architectural decisions (AD-5).
- **Why:** If Haiku fails validation, switching to Sonnet for daily triage could immediately breach the pilot cost ceiling, creating a project-threatening contradiction.
- **Fix:** In the "Constraints" section (C4), add a note: "Cost ceiling assumes Haiku-tier for daily triage. If validation fails and Sonnet is required, the ceiling must be re-evaluated." Also, in OSC-004 acceptance criteria, specify the fallback plan's cost impact.

**F7**
- **Severity:** SIGNIFICANT
- **Finding:** U6 (Multi-model orchestration path) and A4 (Feedback command architecture) are listed as "Open Questions," but the spec has already made firm Architectural Decisions (AD-5, AD-6) that answer them.
- **Why:** This creates confusion. The decisions seem sound, but presenting them as settled while also listing them as open questions undermines the spec's authority.
- **Fix:** Remove U6 and A4 from the "Open Questions" list. Instead, in that section, frame them as "Architecture Validation Tasks for M0" to confirm the proposed decisions (AD-5, AD-6) are viable.

**F8**
- **Severity:** MINOR
- **Finding:** The "System Map" table includes "Wisdom Library (future)" as a dependency with direction "Scout monitors, receives metrics." This conflicts with OSC-012, which defers design of this interface because "an Execute Mode stream exists" is a future condition.
- **Why:** It's inconsistent to list it as a current dependency. This is likely a forward-looking note but should be clarified.
- **Fix:** In the "Dependencies" table, change the "Wisdom Library" entry's "Nature" to: "Future feedback loop -- design deferred (see OSC-012)."

**F9**
- **Severity:** STRENGTH
- **Finding:** The "Overlay Analysis" (Business Advisor, Career Coach) is outstanding. It forces evaluation against external frameworks (lifecycle stage, value proposition, skill leverage), providing crucial perspective beyond technical implementation.
- **Why:** This directly addresses the core challenge: this is a *behavioral* product for a user, not just a software system. It validates the project's strategic premise.

### Answers to Specific Questions

**1. Behavioral vs. Technical Risk:** Agree. The spec correctly identifies behavioral adoption (A1) as the primary risk. The technical patterns (cron, SQLite, adapters, API calls) are largely repurposed from existing, working systems (FIF, book-scout). The significant technical risks (F6 - Haiku triage quality, U6/A4 - orchestration/feedback implementation path) are acknowledged and have validation steps or workarounds planned. The much harder problem is making a useful product that changes Danny's behavior.

**2. Three-Gate Triage Model:** The simplification is sound for the **triage** stage. The goal of triage is fast, high-throughput filtering, not final evaluation. The three gates (Conflict Safety, Automation Potential, Profile Fit) appear to distill the nine dimensions into the most binary and high-leverage criteria. Conflict Safety is a hard filter. Automation Potential aligns with Danny's builder profile. Profile Fit is the catch-all for personal resonance. The nuanced scoring can be reintroduced later for "bookmarked" items during manual evaluation. This is a good example of designing for the stage in the workflow.

**3. Direct Telegram API Tradeoff:** This is the right tradeoff. Given the stated delivery bugs (F7, F8) that cause silent failures, reliability is paramount for user trust in a new habit-forming system. The maintenance burden of a second delivery path is low because it's a simple `curl` call, following the established operational pattern (F12). It isolates Scout from OpenClaw's instability. The spec could be clearer that feedback *parsing* (OSC-008) might also use the direct Bot API, creating a more consistent and reliable interaction loop.

**4. SQLite vs. Flat Files:** SQLite is the right choice. The spec correctly anticipates scale (~50+ candidates) and need for indexed queries (dedup, state machine, aggregation for monthly memos). Flat files would become unwieldy for deduplication checks and generating aggregate reports. Using SQLite aligns with the FIF pattern, leveraging existing in-house familiarity, which reduces cognitive and maintenance overhead.

**5. M0 Constraint (RSS + HN only):** This is the **right scope**. The core value proposition is the *loop*: scan -> score -> digest -> deliver -> feedback. Validating that this loop works and that Danny finds its output engaging is the critical first step. Adding complex, unproven sources (Reddit, Discord) risks turning M0 into a multi-headed integration project, delaying validation of the core premise. If the loop works with RSS/HN, expanding sources is a manageable technical problem. If the loop fails, no number of sources will help.

### Summary
This specification is highly competent. Its major strengths are its risk-aware design, clear phased approach, and strong architectural reasoning around constraints. The few significant issues revolve around reconciling assumptions with constraints (Haiku cost fallback) and cleaning up the presentation of settled vs. open decisions. The answers to the review questions largely affirm the spec's direction and judgments.

---

## Grok (grok-4-1-fast-reasoning)

### Structured Review: Opportunity Scout Specification

#### Summary Metrics
- **Correctness**: High overall; minor factual gaps but no major contradictions. Architectural decisions align with stated facts/constraints.
- **Completeness**: Strong task decomposition and milestones; gaps in resolving U4/U5/U6 fully, feedback architecture spike.
- **Internal Consistency**: Excellent; dependency graph matches task flows, ADs reinforce facts (e.g., F5->AD-1).
- **Feasibility**: Medium-high; behavioral risk (A1) dominates, technical workarounds for OpenClaw bugs feasible but add complexity. Cost target (F11) realistic.
- **Clarity**: Very high; tables, graphs, and structured sections aid readability.

#### Findings

- **F1** [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: Seven side-hustle research dispatches (v1-v7) with specific topics (e.g., DNS/DDI, conflict-safe monetization) and nine-dimension scoring framework. Referenced repeatedly (e.g., F1, F9, OSC-001).
  [Why]: Core calibration data for triage/gravestone; if nonexistent or mismatched, invalidates scoring prompt (A5), triage validation (OSC-004), and graveyard.
  [Fix]: Verify vault contents; if missing, reconstruct during OSC-001 as noted in U5.

- **F2** [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: FIF in TASK phase with HN/arXiv live, Reddit gated; 145 items in inbox.
  [Why]: Assumes reusable pattern/codebase; if FIF status diverges, blocks ingestion adapters (OSC-003) and test set (U4 option).
  [Fix]: Confirm FIF repo/status before M0; fallback to greenfield adapters.

- **F3** [Severity]: MINOR
  [Finding]: Delivery via Telegram primary + Discord mirror assumed validated, but F7/F8 detail OpenClaw delivery bugs without quantifying impact on existing Tess infra.
  [Why]: Risks over-reliance on "validated" status; could cascade to Scout if not segregated.
  [Fix]: Add F3.1 subfact: "Tess delivery success rate audited >=95% over last 30 days."

- **F4** [Severity]: STRENGTH
  [Finding]: book-scout pattern explicitly reused for interaction model, with clear distinction from Scout (monitoring vs. search).
  [Why]: Reduces reinvention risk; Q5 notes no overlap. Edge case: if book-scout throttles conflict with Scout's, but spec enforces separation.
  [Fix]: N/A

- **F5** [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: Haiku SOUL.md limitations documented in `_system/docs/solutions/haiku-soul-behavior-injection.md`.
  [Why]: Underpins AD-1 (cron-only); if undocumented or overstated, exposes cron complexity as hidden risk.
  [Fix]: Link/quote doc excerpt in spec; test single cron job in M0 pre-OSC-007.

- **F6** [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: OpenClaw `--model` override broken (#9556/#14279).
  [Why]: Forces AD-5 model tiering workarounds; multi-model untested (U6). Could inflate costs if Sonnet cron fails.
  [Fix]: Confirm via local OpenClaw test; document workaround success rate.

- **F7** [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: OpenClaw `delivery.to` broken (v2026.2.25), with `bestEffort: true` false positives.
  [Why]: Justifies AD-6 bypass; if bug fixed post-v2026.2.25, spec becomes outdated/maintenance debt.
  [Fix]: Pin version or add "as of [date]" qualifier; M0 spike to retest.

- **F8** [Severity]: MINOR
  [Finding]: DM pairings in-memory (lost on restart) noted, but impact on Scout minimal (uses direct API).
  [Why]: Minor since bypassed, but unclear if affects feedback parser (OSC-008).
  [Fix]: Explicitly state "irrelevant post-AD-6."

- **F9** [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: Infoblox employer conflict from v5 dispatch (confidence 0.78).
  [Why]: Gate 1 hard filter; wrong boundaries risk non-compliance.
  [Fix]: Quote v5 excerpt; annual review trigger for employer changes.

- **F10** [Severity]: STRENGTH
  [Finding]: No existing scanning habit explicitly called out as adoption risk anchor (A1, C7).
  [Why]: Forces behavioral design (threshold delivery AD-8, throttles); consistent risk propagation to M gates. Edge: assumes Danny's self-reported habit accurately.
  [Fix]: N/A

- **F11** [Severity]: MINOR
  [Finding]: API cost <=\$10/month target; no breakdown (e.g., Haiku triage volume).
  [Why]: Feasibility gate; unmodeled spikes could breach early.
  [Fix]: Add table: est. items/day * prompt tokens * $ rates.

- **F12** [Severity]: STRENGTH
  [Finding]: Operational pattern (bash/curl/LLM) consistently applied (AD-1/6).
  [Why]: Proven lightweight ops; avoids full LLM overhead.
  [Fix]: N/A

- **A1** [Severity]: SIGNIFICANT
  [Finding]: Validation M1 gate (5 consecutive reviews, <=2 skips/30 days) but no fallback if fails (e.g., alt channels).
  [Why]: Primary risk; spec aborts at M2 but lacks early pivots.
  [Fix]: Add A1 fallback: weekly digests or email if <50% engagement.

- **A2** [Severity]: MINOR
  [Finding]: Haiku triage >=85% vs. Sonnet; no inter-rater reliability metric beyond agreement.
  [Why]: Binary pass/fail; misses calibration drift.
  [Fix]: Add Cohen's kappa >=0.7 target.

- **U1** [Severity]: MINOR
  [Finding]: Reddit viability gated but M0 defers entirely (AD-7 good).
  [Why]: High-value but correctly de-risked.
  [Fix]: N/A -- schedule post-M2 spike.

- **U4** [Severity]: SIGNIFICANT
  [Finding]: 50-item test set source unresolved; recommendation in Open Questions but not binding in OSC-004.
  [Why]: Blocks M0 gate; calibration quality directly impacts L1 lever.
  [Fix]: Promote recommendation to OSC-004 AC: "Test set composition: 20 v1-7, 20 FIF, 10 synthetic."

- **U5** [Severity]: SIGNIFICANT
  [Finding]: v0.5 brief "does not exist" but OSC-001 assumes reconstructable.
  [Why]: Calibration seed fuzzy; risks inconsistent framework transfer (A5).
  [Fix]: OSC-001 AC: "Reconstruction diff vs. v1-7 commonalities documented."

- **U6** [Severity]: SIGNIFICANT
  [Finding]: Multi-model unresolved beyond AD-5 proposal; needs M0 validation per Open Q3.
  [Why]: Pipeline reliability (OSC-007); Sonnet cost creep if claude-print flaky.
  [Fix]: Add OSC-003.5: "Model invocation spike."

- **AD-3** [Severity]: MINOR
  [Finding]: Data under Projects/opportunity-scout/data/ but FIF pattern in _system/?
  [Why]: Minor silo risk for cross-project queries (e.g., FIF-Scout merge).
  [Fix]: Clarify "FIF exception due to system-wide role."

- **AD-6** [Severity]: SIGNIFICANT
  [Finding]: Direct curl delivery bypasses OpenClaw but feedback (OSC-008) undecided (A4 spike). Inconsistency if feedback uses OpenClaw.
  [Why]: Dual paths fragment maintenance; polling bot API scales poorly.
  [Fix]: Mandate direct Bot API for feedback too.

- **OSC-007** [Severity]: MINOR
  [Finding]: 3-day unattended run AC but M1 needs 2 weeks; gap.
  [Why]: Insufficient for cron flakiness detection.
  [Fix]: Extend to 7 days.

- **OSC-009** [Severity]: SIGNIFICANT
  [Finding]: M1 AC lacks quantitative engagement (e.g., bookmark rate); only ">=1 bookmark".
  [Why]: Underdiagnoses A1; too lenient for habit formation.
  [Fix]: Add "Bookmark/research rate >=10% of items."

- **M2** [Severity]: MINOR
  [Finding]: Abort <20% interesting but undefined ("interesting" = bookmark?).
  [Why]: Subjective gate.
  [Fix]: Tie to ">=20% bookmark/research rate."

#### Specific Questions
1. **Agree on behavioral adoption (A1) as primary risk?** Yes -- F10/C7 substantiate no habit, unlike Crumb tools streamlining existing flows. Technical risks (OpenClaw bugs F6-8, cron per AD-1) secondary but elevated: equal attention via M0 spikes (U6/A4). Add tech risk matrix.

2. **Three-gate simplification sound?** Yes for triage speed (A5 transfer); retains essence (conflict C6, automation L1, fit). Loses nine-dimension nuance (e.g., no economics explicitly), but calibration (OSC-001/010) mitigates. Edge: high-econ/low-fit items misgated H.

3. **Direct Telegram API tradeoff?** Right -- bugs (F7) make OpenClaw unreliable; curl proven (F12). Maintenance burden low (one script); unifies if feedback follows (contra current A4 ambiguity). Alt: fix OpenClaw upstream.

4. **SQLite right for registry?** Yes > flat files; scales to 200+ with dedup/queries (U7). YAML sufficient <50 but painful (AD-4 rationale). Proven (FIF).

5. **M0 scope too narrow?** Right pilot scope (AD-7 de-risks integrations); validates core loop sans U1-3 noise. Value prop (ongoing scanning) testable with RSS/HN volume (A3,A6). Broaden post-M2 if >=20% hit rate.

---

## Synthesis

### Reviewer Question Consensus

All four reviewers unanimously agree on all five directed questions:

1. **Behavioral adoption is the primary risk** — with the caveat that triage quality and feedback reliability deserve near-equal operational attention in M0/M1 because flawed technical execution would invalidate the behavioral experiment
2. **Three-gate triage is sound for M0** — gates work as high-recall filters; ranking needs lightweight secondary dimensions later
3. **Direct Telegram Bot API is the right tradeoff** — all 4 recommend extending it to feedback parsing too (not just delivery)
4. **SQLite is correct** — flat files break at the exact operations Scout needs (dedup, state machine, aggregation)
5. **M0 scope (RSS + HN) is right** — validates the core loop without integration hell

### Consensus Findings

Issues flagged by 2+ reviewers. Highest signal.

**1. Digest-to-candidate identity mapping is missing** (OAI-F4, GEM-REV-004)
Telegram is stateless. When Danny sends `!bookmark 2`, the parser has no way to resolve which candidate record "item 2" refers to without a stored mapping from (digest_date, item_index) → candidate_id. Both reviewers flag this independently; Gemini specifically notes that replying to yesterday's digest could map to the wrong item. **This is a data integrity risk in the core feedback loop.**

**2. Feedback path asymmetry — delivery bypasses OpenClaw but feedback is undecided** (OAI-F3, GRK-AD-6, DS Q3 answer)
Three reviewers independently recommend using direct Bot API for both outbound delivery AND inbound feedback, not just delivery. OpenAI explicitly states: "use one direct Telegram integration path for both send and receive; reserve OpenClaw for LLM inference only." This eliminates the A4 open question.

**3. M1 gate conflicts with threshold-based suppression** (OAI-F6, GEM-REV-006, GRK-OSC-009)
"5 consecutive digests delivered + reviewed" contradicts AD-8 (suppress empty digests). If suppression works, there may not be 5 consecutive delivered digests even in a healthy system. Gemini adds a volume floor concern: if only 2 digests arrive in 30 days, a 50% bookmark rate is meaningless. Gate needs reformulation.

**4. Cost budget is stated but unmodeled** (OAI-F11, GRK-F11, DS-F6)
$10/month ceiling exists but no volume-based breakdown. DeepSeek uniquely adds: if Haiku fails M0 validation and Sonnet is needed for triage, the cost ceiling could immediately break. The fallback plan's cost impact needs to be explicit.

### Unique Findings

Issues only one reviewer caught. Assessment of each.

**OAI-F5: Suppressed digest vs. pipeline failure look identical** — *Genuine insight.* Danny can't distinguish "no items today" from "system broken." A lightweight weekly heartbeat or ops alert on failure would fix this. Worth incorporating.

**OAI-F12: Pipeline idempotency and duplicate-send protection** — *Genuine insight.* Cron pipelines fail by producing duplicates, not by crashing. Run IDs and duplicate-send guards are standard cron hygiene. Worth incorporating as a should-fix.

**OAI-F19/F20: Normalized item schema and candidate record schema missing** — *Genuine insight, elevated to CRITICAL.* The normalized item schema is the core interface contract tying ingestion → triage → registry → digest together. The candidate schema references "input draft §6" which isn't in the spec. Both schemas need to be inlined.

**GEM-REV-005: SQLite WAL mode for concurrency** — *Genuine insight.* Cron writes + feedback updates = concurrent access. WAL mode is the standard fix. One line in OSC-005.

**OAI-F22: Feedback acknowledgement UX** — *Good catch.* When Danny sends `!bookmark 2`, he needs confirmation: "Bookmarked #2: [title]" or "Could not resolve item #2." Without this, feedback commands feel like shouting into a void.

**OAI-F13: Item-wise vs. batch triage unspecified** — *Genuine insight.* Affects cost and ranking quality. Should be specified for M0.

**GRK-U4: Test set composition not in OSC-004 AC** — *Good catch.* The recommendation is in Open Questions but should be binding.

### Contradictions

No contradictions across reviewers. All four agree on direction for all five directed questions. Severity disagreements are minor: OpenAI rates missing schemas as CRITICAL while others note schema gaps at SIGNIFICANT — difference in emphasis, not conclusion.

### Action Items

#### Must-fix (blocking spec stability)

| ID | Action | Source Findings |
|----|--------|----------------|
| A1 | **Inline normalized item schema** — define the adapter → scoring interface contract with fields: source_id, source_type, external_id, title, url, author, published_at, summary, raw_tags, ingested_at, content_hash | OAI-F19 |
| A2 | **Inline candidate record schema** — move from "see input draft §6" reference to spec-internal definition with all fields, lifecycle states, and dedup keys | OAI-F20 |
| A3 | **Add digest-to-candidate identity mapping** — store (digest_id, item_index, candidate_id) in SQLite. Feedback commands resolve via this mapping, not positional guessing | OAI-F4, GEM-REV-004 |
| A4 | **Resolve feedback path: direct Bot API for both delivery AND feedback** — eliminate A4 as open question, update AD-6 to cover both directions. OpenClaw is for LLM inference only | OAI-F3, GRK-AD-6, DS-Q3 |
| A5 | **Fix M1 gate definition** — replace "5 consecutive digests" with "5 qualifying digests reviewed within a 21-day window" AND add volume floor: "at least 10 scan cycles completed" | OAI-F6, GEM-REV-006, GRK-OSC-009 |

#### Should-fix (significant but not blocking)

| ID | Action | Source Findings |
|----|--------|----------------|
| A6 | **Add cost budget breakdown** — items/day × prompt tokens × model rates for low/expected/high volume scenarios. Include Haiku-fallback-to-Sonnet cost impact | OAI-F11, GRK-F11, DS-F6 |
| A7 | **Add heartbeat/health signal** — weekly "Scout healthy, N items scanned, N qualified" summary to distinguish suppressed digest from pipeline failure | OAI-F5 |
| A8 | **Define source registry schema** — source_id, name, url, source_type, check_frequency, enabled, focus_domain, yield_score, last_success_at, parser_config | OAI-F21 |
| A9 | **Add pipeline idempotency rules** — run IDs, duplicate-send guard, idempotent ingest per source/check window | OAI-F12 |
| A10 | **Remove U6/A4 from Open Questions** — they're answered by AD-5/AD-6 (and now A4 above). Reframe as "M0 validation tasks" | DS-F7 |
| A11 | **Add feedback acknowledgement templates** — "Bookmarked #2: [title]", "Research queued for #3: [title] (1 of 1 daily)", "Item #5 not found in latest digest" | OAI-F22 |
| A12 | **Define metric denominators** — bookmark_rate = bookmarks / delivered_items, duplicate_rate = deduped / total_ingested, interesting_rate = (bookmarked + researched) / delivered_items | OAI-F16, GRK-M2 |
| A13 | **Add SQLite WAL mode** to OSC-005 initialization requirements | GEM-REV-005 |
| A14 | **Promote test set composition to OSC-004 AC** — "20 items from v1-v7 findings, 20 from FIF inbox, 10 synthetic edge cases" | GRK-U4 |
| A15 | **Specify triage mode for M0** — item-wise Haiku triage with deterministic rubric, then batch Sonnet ranking for digest ordering | OAI-F13 |

#### Defer (detail during PLAN/action-architect)

| ID | Action | Source Findings | Reason |
|----|--------|----------------|--------|
| A16 | State machine transition table (allowed commands per state, terminal vs. reversible) | OAI-F7 | Implementation detail for PLAN phase |
| A17 | Dedup canonical_pattern mechanism (URL normalization, title similarity, LLM-assisted labeling) | OAI-F8 | Implementation detail for PLAN phase |
| A18 | Security section for Bot API (token storage, sender validation, log redaction) | OAI-F17 | Valid but detail-level; address in PLAN |
| A19 | Graveyard matching mechanism with examples | OAI-F14 | Implementation detail |
| A20 | Raw item purge policy (30-day cleanup for un-triaged items) | GEM-REV-007 | Ops detail for PLAN phase |
| A21 | Ops dashboard/log review mechanism | OAI-F23 | Partly addressed by A7 (heartbeat); full design in PLAN |
| A22 | Cohen's kappa inter-rater metric | GRK-A2 | Over-engineered for M0; simple agreement rate is sufficient |
| A23 | M1 engagement fallback (alt channels before abort) | GRK-A1 | Premature; let M1 data inform pivot options |

### Considered and Declined

| Finding | Justification | Reason Category |
|---------|--------------|-----------------|
| OAI-F27–F34, GEM-REV-001–003, DS-F4, GRK-F1/F2/F5–F7/F9 (UNVERIFIABLE CLAIMs — OpenClaw bugs, vault docs, project status, research dispatches) | These are vault-internal references verifiable by the implementation agent at runtime (project-state.yaml, solution patterns, research dispatches, memory notes). They describe observed local system behavior. Adding external citations would add bulk without utility. | `constraint` |
| OAI-F26 (references to absent "input draft" sections) | The input draft is a project artifact available in the inbox. Schema gap addressed by A1/A2 (inline schemas). | `constraint` |
| GRK-AD-3 (FIF vs. Scout data location inconsistency) | FIF is a system-wide service (`_system/`); Scout is a project. The spec correctly places Scout data under `Projects/`. Different roles, different locations. | `incorrect` |
| DS-F5 (throttle linkage in second-order effects section) | Adding cross-references within the spec adds words without value. Throttles are specified in the Constraints section; the second-order effects section identifies the risk correctly. | `overkill` |
| DS-F8 (Wisdom Library listed as dependency but is future) | Valid editorial point. Rolling into A10 — dependency table entry will note "future, design deferred (OSC-012)". | `out-of-scope` |
| GRK-F8 (DM pairings irrelevant post-AD-6) | Correct — F8 is listed as an environment fact, not a design dependency. No spec change needed. | `constraint` |
| GRK-F3 (delivery validation unquantified) | Delivery success rate is a Tess operations concern. Scout bypasses the problematic path entirely via AD-6. | `out-of-scope` |
| GRK-OSC-007 (3-day AC insufficient, extend to 7) | OSC-007 is cron setup validation. M1 validation (OSC-009, 2-week operational test) provides the longer reliability check. | `constraint` |
