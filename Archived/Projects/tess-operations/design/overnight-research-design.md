---
project: tess-operations
type: design-note
domain: software
status: active
created: 2026-03-09
updated: 2026-03-09
tags:
  - intelligence
  - research
  - tess
---

# Overnight Research — Design Note

Resolves open design questions for TOP-046 (overnight research sessions) before
prompt template implementation. Covers intake routing, stream cadence, model
selection, convergence, output format, FIF overlap, last30days integration,
and escalation to Crumb.

Meeting prep integration (TOP-047) is a separate design concern with different
triggers, timing, and output consumers — see §last30days for the connection
point, but TOP-047 gets its own design note.

## Three-Tier Research Model

| Tier | Actor | Model | Depth | Cost |
|------|-------|-------|-------|------|
| 0 — Capture | FIF pipeline | automated | Signal detection + triage | ~$0/item |
| 1 — Investigation + Promote | Tess (overnight cron) | Opus 4.6 (see §Model Selection) | Browser + vault context + synthesis → signal-note | ~$2-5/session |
| 2 — Evidence pipeline | Crumb (researcher skill) | Opus 4.6 | 6-stage pipeline, citation integrity, 150k tokens | ~$2-5/dispatch |

Escalation flows upward: FIF flags → Tess investigates → Tess escalates to
Crumb when depth exceeds her scope. Each tier adds reasoning depth and cost.

## Intake Mechanisms

Two intake paths with different storage backends. The overnight cron checks
both on every run.

### 1. FIF-flagged items (SQLite)

Dashboard triage action `research` writes to `dashboard_actions` table in FIF
SQLite DB (same pattern as `skip`/`delete`/`promote` in MC-061–064). The
overnight cron queries:

```sql
SELECT da.canonical_id, da.metadata, p.*
FROM dashboard_actions da
JOIN posts p ON da.canonical_id = p.canonical_id
WHERE da.action = 'research' AND da.consumed_at IS NULL
```

On completion, sets `consumed_at` to current timestamp (same consumed pattern
as promote queue).

**Requires:** MC-068 (new MC task — `research` action endpoint + UI button).

### 2. Manual research requests (filesystem)

Operator drops a note in `_openclaw/research/` (dedicated directory, NOT
`_openclaw/inbox/`):

```yaml
---
type: research-request
topic: "whatever you want researched"
stream: manual
priority: normal  # normal | urgent
context: "optional — why this matters, what you already know"
created: 2026-03-09
---
```

The overnight cron scans `_openclaw/research/` for unprocessed requests.
Completed requests are moved to `_openclaw/research/.processed/`.

**Why not `_openclaw/inbox/`:** The inbox is a mixed staging area for captures,
dispatch results, and feed-intel items. Research requests are a distinct intake
stream that shouldn't compete with or be confused during inbox triage.

### Future convenience: Telegram `/research` prefix

The bridge quick-capture system already supports `processing_hint: research`
with `prepareResearchBrief()` (capture-processing-procedure.md). A `/research`
prefix that writes a `type: research-request` note to `_openclaw/research/`
is a minor extension — it feeds into the same filesystem queue. Not a blocker
for TOP-046; note as a future nicety when the capture processor is next touched.

## Stream Cadence

Single nightly cron entry point. Stream selection by day + queue state.

| Stream | Trigger | Cadence | Source |
|--------|---------|---------|--------|
| §8.1 Reactive | FIF research queue non-empty | Any night (priority) | SQLite `dashboard_actions` |
| §8.1 Manual | `_openclaw/research/` non-empty | Any night (priority) | Filesystem |
| §8.2 Competitive/Account | Scheduled | Sunday | Browser + FIF digest + vault dossiers |
| §8.3 Builder Ecosystem | Scheduled | Wednesday | Browser + FIF digest + vault projects |

**Priority rule:** Reactive items (§8.1 from either intake path) run first.
If reactive items consume the session budget, scheduled streams are skipped
that night without accumulating debt. Scheduled streams are low-urgency
rotations — missing one week is fine.

**Cron schedule:** 11 PM ET nightly. `cron-lib.sh` wrapper with `--wall-time 1800`
(30 min hard kill — generous ceiling for multi-item reactive queues),
`--jitter 300` (5 min, avoids predictable scheduling).

## Model Selection

**Decision: Opus 4.6 for all streams.** Operator override (2026-03-12).

**Rationale:** Research items require judgment calls on applicability to Crumb
architecture, fit within existing systems, and cross-project implications.
This is Opus-level reasoning — the same quality bar as an interactive Crumb
session. Sonnet's cost advantage is not worth the risk of shallow assessments
that miss architectural connections or produce briefs the operator dismisses.

**Prior recommendation (Sonnet 4.6) superseded:** The original Sonnet
recommendation was based on cost optimization. Operator feedback: research
items almost always become KB articles, so the assessment must be high-quality
on the first pass — there's no "review and rework" step in the workflow.

**Cost impact:** At 2-3 sessions/week on Opus, ~$2-10/week (~$8-40/month).
Within the chief-of-staff cost envelope ($30-70/month projected). Acceptable
given that research output stages to `_openclaw/research/output/` for operator
review before vault promotion.

**Execution:** Runs as `claude --print` (Claude Code CLI), not OpenClaw.
This bypasses the OpenClaw `--model` override bug (#9556) and provides
full Claude Code tool access (Read, Write, Grep, WebFetch, WebSearch).

**Spec update needed:** §8.1 and §11 (model allocation table) reference Haiku 4.5
for research sessions. Update to Opus 4.6 with the rationale above.

## Convergence Heuristics

No time-based constraints — Haiku/Sonnet has no clock awareness during a
session. The cron wrapper's `--wall-time` is the external safety net (hard kill
at 10 min), not a prompt-level heuristic.

**Prompt-level convergence rules:**
- **Source cap:** 5 sources per topic. Stop searching, start synthesizing.
- **Link-follow depth:** 3 clicks max per source. Prevents rabbit holes.
- **Reactive items:** Process all queued items in a single run. No per-night
  throttle — this is an overnight task, runtime is not a constraint. Process
  oldest first, write output for each item before starting the next.
- **Scheduled streams:** Cover 2-3 topics per rotation (e.g., 2 competitors +
  1 industry trend for §8.2). Not exhaustive — these accumulate over weekly cycles.

## Output Format

### Primary Output: Signal-Notes (auto-promote)

Research items that are actionable (expected ~90%) are written directly as
signal-notes to `Sources/Signals/` — the same format as feed-pipeline
promotions. No intermediate "research brief" step; the research enrichment
IS the signal-note content.

**Naming:** follows existing signal-note convention (kebab-case slug from
title, e.g., `cloudflare-crawl-endpoint-claude-code-skill.md`).

**Frontmatter:** standard signal-note frontmatter per file-conventions.md,
plus research-specific fields:

```yaml
---
type: signal-note
status: active
created: 2026-03-10
updated: 2026-03-10
source_id: FIF-SIG-xxx
source_type: x | rss | hn | arxiv | yt
canonical_id: x:2031906819908780189
skill_origin: tess-overnight-research
research_stream: reactive | competitive | builder | manual
sources_consulted: 4
tags:
  - kb/software-dev
topics:
  - moc-software
---
```

### Body Structure

```markdown
# [Descriptive Title]

## Summary
[2-3 sentence executive summary — what it is, why it matters]

## Key Findings
- [Finding 1 with source attribution]
- [Finding 2 with source attribution]
- [Finding 3]

## Applicability
[How this connects to Crumb/Tess/current projects — the Opus judgment call]

## Sources
1. [URL or vault reference] — [relevance note]
2. [URL or vault reference] — [relevance note]

## Vault Connections
[Wikilinks to relevant vault notes — dossiers, signal-notes, project docs]
```

### Non-Promotable Output: Research Briefs

Items assessed as not actionable (~10%) get a lightweight research brief in
`_openclaw/research/output/` explaining why — so the operator knows it was
evaluated, not dropped. Named `research-brief-YYYY-MM-DD-{slug}.md` with
`type: research-brief`, `status: assessed-not-actionable`.

### Escalation Output

Items that need deeper investigation get the signal-note written (partial
findings) plus a bridge dispatch to Crumb's researcher skill. See §Escalation
below. Signal-note frontmatter: `escalated_to_crumb: true`.

## Execution Model

**Option (a): Cron wrapper orchestrates, not Tess.**

The nightly cron script runs data-gathering tools first (last30days, FIF digest
reads, etc.), then launches the Tess LLM session with gathered data as context
input. Tess synthesizes — she does not orchestrate data collection.

```
┌──────────────────────────────────────────────────┐
│  overnight-research.sh  (cron-lib.sh wrapper)    │
│                                                  │
│  1. Check intake queues (SQLite + filesystem)    │
│  2. Select stream (reactive priority, else       │
│     scheduled by day-of-week)                    │
│  3. Run data-gathering tools:                    │
│     - last30days.py --emit context --include-web  │
│       (if watchlist topics match stream)          │
│     - Read FIF digest (see below)                │
│     - Read vault dossiers (for account streams)  │
│  4. IF data-gathering produced no useful output  │
│     → skip Tess session, log, exit               │
│  5. Launch Tess session (Opus 4.6 via claude      │
│     --print) with gathered data as context input │
│  6. Tess synthesizes → writes brief(s) to         │
│     _openclaw/research/output/ (staging)         │
│  7. Mark intake items as consumed                │
│  8. Log metrics via cron_finish()                │
└──────────────────────────────────────────────────┘
```

**Why not option (b) (Tess invokes tools mid-session):**
- If last30days fails, we skip the Tess session entirely — no tokens burned
  on a session with no input data
- Tess doesn't need bash execution capability for data gathering
- Data-gathering failures are isolated from synthesis failures
- Simpler debugging: check script output files vs. debugging LLM tool use

**Wall-time budget split:** ~3 min for data-gathering, remainder for Tess synthesis
(scales with queue depth). `--wall-time 1800` on the outer wrapper;
data-gathering tools get their own subprocess timeouts (last30days.py: 300s,
file reads: trivial).

### "Read FIF digest" — What Exactly

The cron wrapper reads the most recent FIF digest file from the FIF repo's
state directory: `~/openclaw/feed-intel-framework/state/digests/`. Files are
named `YYYY-MM-DD-<sourceType>.md` (e.g., `2026-03-09-x.md`). The wrapper
reads all digest files from the last 24 hours (there may be one per adapter —
X, RSS, YouTube). These are markdown files with frontmatter `type: feed-intel-
digest` containing triaged items with scores and excerpts.

For reactive items specifically, the intake query hits the FIF SQLite database
directly (`~/openclaw/feed-intel-framework/state/pipeline.db`) — see §Intake
Mechanisms above.

## last30days Integration

### What It Is

[mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill) —
a Python research engine that scrapes Reddit, X, YouTube, TikTok, Instagram,
HN, Polymarket, and general web with recency enforcement, engagement scoring,
dedup, and normalization. Has `--emit context` (compact snippet for injection
into other prompts), `--emit md` (structured markdown), `--include-web` (Brave
web+news search — mandatory for B2B), watchlist mode (persistent topic tracking
with SQLite), and briefing generation (daily/weekly digests with trend detection).

### Status: Validated — Adopted with `--include-web` Required for B2B

**Validated 2026-03-09.** Four industry/competitor queries tested in two rounds.

**Round 1 (Reddit/HN/TikTok/Instagram/Polymarket only):** 0/4 actionable.
Reddit and HN returned generic trending content (homelab posts, job advice,
3D-printed server racks) that fuzzy-matched on keywords but had zero B2B
enterprise signal. Polymarket returned sports betting. Confirms the original
concern: social sources are noise for niche B2B topics.

**Round 2 (+ Brave web search via `--include-web`):** 4/4 actionable.
- **BlueCat Networks:** Horizon SaaS launch (Feb 2026), VP Channel hire (Jeff
  McCullough), coverage across 8+ trade outlets (Help Net Security, ITOps Times,
  Channel Post MEA, GlobeNewswire)
- **EfficientIP DDI:** EMA analyst research ("only 35% report full DDI success"),
  e92plus partnership, Cisco integration blog, IPDR compliance article
- **Infoblox DNS security:** .arpa phishing research (BleepingComputer,
  SecurityBrief), DNS-AID for agentic AI blog, Universal DDI Q2 innovations,
  CyberWire podcast, partner program announcements
- **IPAM network automation:** Infoblox DDI innovations, Ansible+phpIPAM
  integration, Netbox automation, IPAM tooling comparisons, hiring signals

**Key finding:** `--include-web` is mandatory for B2B queries. Without it,
last30days is a consumer/developer tool. With it, Brave's web+news results
surface trade press, company blogs, press releases, and analyst coverage —
exactly the signal meeting prep and competitive intel need.

**Validation script:** `_openclaw/scripts/last30days-validation.sh`
**Installation path:** `/Users/openclaw/.claude/skills/last30days/`
**Config:** `/Users/openclaw/.config/last30days/.env` (SCRAPECREATORS_API_KEY,
BRAVE_API_KEY)

**CLI correction:** The design originally referenced `--agent` flag. This flag
does not exist in last30days v2.9.1. Correct invocation:
`python3 scripts/last30days.py "<topic>" --emit md --include-web`
Use `--emit context` for compact injection into other prompts.

**Cross-project consumer:** customer-intelligence dossier maintenance can use
`last30days "<account>" --emit context --include-web` to refresh the "Recent
Intelligence" section during Crumb sessions. Same tool, different write path
(dossier persistence vs. meeting prep point-in-time assembly). CI skill update
tracked separately in customer-intelligence project.

### Cost Assessment (Required Before Deployment)

| Dependency | Cost Model | Estimated Usage |
|-----------|-----------|-----------------|
| SCRAPECREATORS_API_KEY | Required. 100 free credits, then PAYG | ~25 account topics + 5 competitors + 5 builder terms = ~35 topics/week |
| Optional: xAI API key | X search enhancement | Per-query |
| Optional: Brave API key | Web search supplement | Per-query |

**Action:** Check ScrapeCreators pricing for ~35 queries/week before deployment.
If cost is >$10/month, evaluate whether the signal quality justifies it.

### Positioning Relative to FIF

last30days provides two things FIF does not:

1. **On-demand topic research** — "what is the internet saying about
   [account/competitor] right now" across platforms FIF doesn't cover
   (TikTok, Instagram, Polymarket, general web). This is the meeting prep
   use case. Point queries, not a persistent pipeline.

2. **Ambient discovery bridging FIF's M5 gap** — via the watchlist feature,
   last30days can cover HN, Reddit, and YouTube now, while FIF's M5 adapters
   (FIF-039 through FIF-042) are still on the roadmap. Once FIF builds those
   adapters, watchlist topics for those platforms can be retired.

**last30days does NOT replace any FIF adapters.** FIF's adapter contract
provides triage, dedup, vault routing, and feedback loops that last30days
doesn't offer. The relationship is:

| Platform | FIF Status | last30days Role |
|----------|-----------|-----------------|
| X/Twitter | Live (M2) | **Redundant** — do not use |
| RSS | Live (M3) | Not applicable (no RSS in last30days) |
| YouTube | Soak (M4) | **Bridge** until FIF adapter confirmed |
| Hacker News | Planned (M5, FIF-039) | **Bridge** — retire when FIF-039 ships |
| Reddit | Planned (M5, FIF-040–041, API terms TBD) | **Bridge or fallback** — if Reddit API terms hostile, last30days's OpenAI routing becomes permanent path |
| arxiv | Planned (M5, FIF-042) | Not applicable |
| TikTok | Not planned | **Unique coverage** — last30days only |
| Instagram | Not planned | **Unique coverage** — last30days only |
| Polymarket | Not planned | **Unique coverage** — last30days only |
| General web | Not planned as adapter | **Unique coverage** — last30days only |

**FIF-reusable patterns:** FIF-039 (HN) could borrow from last30days's
`lib/hackernews.py` — both use the Algolia API. Patterns worth adopting;
the adapter itself should still be FIF-native for lifecycle integration.

### Watchlist Model

For §8.2 (competitive/account intel), last30days watchlists replace freeform
browser research with structured, scheduled data gathering:

- **Account watchlists:** One topic per account or account cluster
  (e.g., "Steelcase technology investment", "BorgWarner EV strategy")
- **Competitor watchlists:** Per-competitor topics
  (e.g., "BlueCat Networks", "EfficientIP", "Men&Mice")
- **Builder watchlists:** Per-ecosystem topics
  (e.g., "OpenClaw", "Claude Code skills", "local LLM inference")

Watchlists run on a weekly rotation via last30days's built-in cron scheduling.
The overnight research cron reads accumulated findings — it doesn't trigger the
watchlist runs itself.

### `--emit=context` for Meeting Prep

The `--emit=context` flag produces a compact snippet designed for injection into
other skill prompts. This is the integration point for TOP-047 (session prep):
before a customer meeting, the prep workflow pulls the context snippet for that
account's watchlist topics and injects it into the pre-session brief. Detailed
design in a separate TOP-047 design note.

## FIF Overlap Resolution

Tess overnight research is **synthesis and investigation**, not parallel
signal collection. The prompt must enforce this boundary explicitly.

| Stream | FIF's role | Tess's role | Non-FIF sources |
|--------|-----------|-------------|-----------------|
| §8.1 Reactive | Captured the signal, flagged for research | Follow links, gather context, write deeper brief | Browser: linked articles, GitHub repos, docs, forums |
| §8.2 Competitive | Captures from curated X/RSS feeds | Synthesize FIF signal + last30days watchlist findings + vault dossier context | last30days: TikTok, Instagram, Polymarket, web, Reddit (bridge), HN (bridge). Browser: company websites, job boards, press releases, SEC filings |
| §8.3 Builder | Captures from curated X/RSS feeds | Synthesize FIF signal + last30days watchlist findings + vault project context | last30days: Reddit, HN, web. Browser: GitHub repos, npm/PyPI, blog posts, Discord showcase |

**Prompt instruction:** "Read FIF's most recent digest and last30days watchlist
findings as input context. Do not re-scan sources FIF already monitors (X feeds,
RSS). Your unique value is cross-source synthesis + vault context + deeper
investigation where the data warrants it. If FIF or last30days already captured
a signal, your job is to connect it to vault knowledge and assess significance —
not to find it again."

## Escalation: Tess → Crumb

### Mechanism

Bridge dispatch protocol `invoke-skill` operation. Already designed and
documented in crumb-tess-bridge dispatch-protocol.md §12.2, with `skill:
researcher` as the explicit example.

Tess writes a dispatch request to `_openclaw/outbox/`:

```json
{
  "operation": "invoke-skill",
  "skill": "researcher",
  "payload": {
    "question": "[research question]",
    "deliverable_format": "research-note",
    "rigor": "standard",
    "context": "[Tess's partial findings — summary, sources gathered, why escalating]",
    "source_brief": "research-brief-2026-03-10-reactive.md"
  },
  "confirmation_required": true,
  "budget": {
    "max_stages": 10,
    "max_tool_calls": 100,
    "max_wall_time_seconds": 600
  }
}
```

The bridge runner picks up the dispatch, Crumb processes it through the
researcher skill pipeline. Tess's partial findings are included as context
so Crumb doesn't re-do the legwork.

### Escalation Criteria

Tess escalates when any of these apply:
- Topic too broad for 50k token ceiling (needs multi-stage investigation)
- Sources contradict each other and need deeper evaluation with citation integrity
- Findings have architectural or strategic implications beyond operational scope
- Operator explicitly requested deep research (manual request with `priority: urgent`
  or `escalate: true`)

### Visibility

- Research brief frontmatter: `escalated_to_crumb: true`, `status: escalated`
- Morning briefing: "Tess escalated 1 topic for deep research: [title]"
- Attention-manager: surfaces as a software/learning domain item if operator
  needs to review the dispatch

## Cross-Project Tasks

| Task | Home Project | Description | Depends On |
|------|-------------|-------------|------------|
| **MC-068** | mission-control | Add `research` triage action — endpoint + UI button on signal cards | MC-062 (skip/delete pattern) |
| **TOP-046** | tess-operations | Overnight research cron prompt + script + plist | TOP-014 (M1 gate), MC-068 (FIF intake path) |
| **XD-016** | cross-project-deps | TOP-046 reactive stream blocked on MC-068 | — |

**Note:** The researcher skill (DONE project) does not need modification. It
already accepts Tess input per SKILL.md Step 1 ("The research brief comes from
the operator (direct) or Tess (bridge dispatch)"). The bridge dispatch protocol
already documents the `invoke-skill` mechanism. No new cross-project work needed
for escalation.

**Note:** TOP-046 can proceed with §8.2 and §8.3 (scheduled streams) without
MC-068. Only the §8.1 reactive stream requires the dashboard research action.
The prompt template should handle "no FIF research queue available" gracefully.
