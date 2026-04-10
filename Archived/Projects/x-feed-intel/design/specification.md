---
type: specification
skill_origin: systems-analyst
project: x-feed-intel
domain: software
created: 2026-02-21
updated: 2026-02-25
version: 0.6.0
tags:
  - openclaw
  - tess
  - automation
  - kb/software-dev
topics:
  - moc-crumb-operations
---

# X Feed Intelligence Pipeline — Project Specification

## 1. Problem Statement

Danny bookmarks 10+ posts per day on X related to agent architecture, agentic coding, Claude Code, Obsidian/PKM, and AI-assisted workflows. These bookmarks accumulate without structured review, and relevant public content that he doesn't encounter in his feed is missed entirely. There is no pipeline to extract, triage, and surface actionable signal from X into the Crumb/Tess ecosystem.

## 2. Objective

Build an automated pipeline that:

1. **Extracts** Danny's X bookmarks via the official X API (pay-per-use)
2. **Discovers** relevant public content via TwitterAPI.io search
3. **Triages** both streams using Tess's operational logic with structured decision output
4. **Delivers** a daily digest to Telegram with categorized, prioritized results and inline feedback controls
5. **Routes** actionable items into the vault for Crumb or Tess to act on

## 3. Architecture Overview

The pipeline operates as two decoupled clocks with a durable queue between them.

```
                        ┌─────────────────────────────┐
                        │       CAPTURE CLOCK          │
                        │  (runs on cron, retries OK)  │
                        └─────────────┬───────────────-┘
                                      │
       ┌──────────────┐     ┌─────────┴──────────┐
       │  X API        │     │  TwitterAPI.io      │
       │  (bookmarks)  │     │  (public search)    │
       └──────┬────────┘     └────────┬────────────┘
              │                       │
              ▼                       ▼
       ┌──────────────────────────────────────────┐
       │         Extractor Layer                   │
       │  bookmark-puller  │  topic-scanner        │
       │                   │  (per-run dedup cache) │
       └──────────┬───────────────┬────────────────┘
                  │               │
                  ▼               ▼
       ┌──────────────────────────────────────────┐
       │         Normalizer                        │
       │  Unified post format w/ canonical_id      │
       └──────────────────┬───────────────────────-┘
                          │
                          ▼
       ┌──────────────────────────────────────────┐
       │         Global Dedup Engine               │
       │  Tracks canonical_id across all runs      │
       └──────────────────┬───────────────────────-┘
                          │
                          ▼
                 ┌────────────────┐
                 │  Durable Queue  │
                 │  (pending items)│
                 └────────┬───────┘
                          │
                        ┌─┴───────────────────────────┐
                        │      ATTENTION CLOCK         │
                        │  (runs at digest time)       │
                        └─────────────┬───────────────-┘
                                      │
                          ┌───────────┴──────────┐
                          ▼                      ▼
               ┌────────────────┐    ┌───────────────────┐
               │  Tess Triage   │    │  Cost Telemetry    │
               │  Engine (LLM)  │    │  (MTD/projected)   │
               └────────┬───────┘    └─────────┬─────────┘
                        │                      │
                ┌───────┴────────┐             │
                ▼                ▼             │
     ┌────────────────┐  ┌───────────────┐    │
     │  Daily Digest   │  │  Vault Router  │   │
     │  (Telegram)     │  │  (actionable)  │   │
     │  + feedback IDs │  └───────────────┘    │
     └────────┬───────┘                        │
              │                                │
              ▼                                ▼
     ┌────────────────────────────────────────────┐
     │  Digest includes: items + cost stats +      │
     │  reply-based control protocol (A01 promote) │
     └─────────────────────────────────────────────┘
```

**Two-clock rationale:** The capture clock (extractors + normalizer + dedup) can run opportunistically, retry on API failures, and accumulate items without triggering triage or spamming Telegram. The attention clock (triage + digest + routing) runs once daily at a fixed time. The SQLite state store (§7.2) serves as the durable queue between them.

## 4. Data Sources

### 4.1 X API — Bookmark Extraction

- **Endpoint:** `GET /2/users/:id/bookmarks` (X API v2)
- **Auth:** OAuth 2.0 (user context — requires Danny's authorization)
- **Token management:** The pipeline handles OAuth token refresh automatically using the refresh token. Tokens are stored securely per §10. If token refresh fails, the pipeline queues a notification to Danny and skips the bookmark pull for that run. See §10 for the re-authorization procedure.
- **Pricing:** $0.005 per post read (pay-per-use, no subscription)
- **Billing dedup:** X deduplicates at the billing level within a 24-hour UTC window — requesting the same post ID twice in the same day incurs only one charge. This is a billing optimization, not a results-level dedup.
- **Rate limit:** 180 requests per 15 minutes
- **Max return:** 800 most recent bookmarks per request. The API does not paginate beyond 800. Bookmarks older than the most recent 800 are inaccessible via this endpoint. The initial catch-up pull is therefore limited to the 800 most recent.
- **Spending cap:** Configure in X Developer Console. Recommend $5/month hard cap initially.

**Estimated cost:**
- Initial catch-up pull: ~$4.00 (800 bookmarks × $0.005)
- Daily incremental: $0.05–$0.10 (10-20 new bookmarks)
- Monthly steady-state: $1.50–$3.00

### 4.2 TwitterAPI.io — Public Topic Search

- **Endpoint:** Tweet search (REST)
- **Auth:** API key (no OAuth required for public data)
- **Pricing:** $0.15 per 1,000 tweets returned, no monthly fees
- **Rate limit:** 1,000+ requests/second (effectively unlimited for this use case)
- **Cost bounding:** Topic scanner enforces `max_results` per query per run. Aggregate query volume is bounded by the topic config. No unbounded iteration.
- **Advanced search operators:** TwitterAPI.io supports X-style advanced search operators including `min_faves:N`, `min_retweets:N`, `-filter:replies`, `from:user`, `since:YYYY-MM-DD`, `lang:en`, and `filter:images`. **Phase 0 must verify operator support** against actual API responses and document supported syntax in the topic config design notes. If operator support is absent or partial, fall back to client-side engagement filtering (see §5.2).

**Estimated cost:**
- 2,000–3,000 posts/month across all topic queries
- Monthly: $0.30–$0.45

### 4.3 Combined Monthly Cost Estimate: $2–$4

## 5. Components

### 5.1 Bookmark Puller

Runs on the capture clock schedule. Authenticates as Danny via OAuth 2.0, pulls bookmarks from the X API, and checks the `posts` table for existing `canonical_id` entries. Outputs only net-new bookmarks in normalized format to the durable queue.

**Token refresh:** On each run, the puller checks token validity and refreshes if needed. If refresh fails (e.g., revoked token), the puller skips the run and sends a notification to Telegram: "Bookmark pull failed — OAuth token needs re-authorization."

**State:** Seen bookmark IDs are tracked via the `posts` table in the SQLite state store (§7.2). The `posts.canonical_id` primary key serves as the sole dedup source of truth for all components. Records with `queue_status = 'expired'` older than 90 days are pruned periodically.

**800-bookmark ceiling:** On the first run, only the 800 most recent bookmarks are accessible. After steady-state is reached (daily pulls), this limit is irrelevant unless the pipeline is offline for an extended period, in which case bookmarks beyond the 800 most recent will be missed. The spec accepts this limitation.

### 5.2 Topic Scanner

Runs on the capture clock schedule (configurable — default every 2-3 days). Queries TwitterAPI.io for each topic in the topic config. Outputs only net-new posts in normalized format to the durable queue.

**Per-run dedup cache:** Before fetching results for each query in a batch, the scanner maintains an in-memory set of post IDs already returned by prior queries in the same run. Posts already seen in the current run are skipped. This prevents paying for the same post twice when overlapping queries return the same content within a single batch.

**Topic config:** A YAML or JSON file listing search queries, run frequency overrides, max results per query, and optional search filters. Designed for easy extension — adding a new domain requires only adding an entry to this file.

```yaml
# Global defaults
defaults:
  max_age_days: 7          # Ignore posts older than this (prevents stale content on new topics)
  max_results: 50          # Per-query cap
  filters: ""              # Default search operator string appended to all queries

topics:
  - name: agent-architecture
    queries:
      - "agent architecture LLM"
      - "agentic coding"
      - "multi-agent system"
    max_results: 50
    filters: "min_faves:10 -filter:replies lang:en"

  - name: claude-code
    queries:
      - "claude code"
      - "anthropic claude developer"
      - "claude MCP"
    max_results: 50
    filters: "min_faves:5 -filter:replies lang:en"

  - name: obsidian-pkm
    queries:
      - "obsidian vault"
      - "personal knowledge management AI"
      - "obsidian plugin AI"
    max_results: 50
    filters: "min_faves:10 -filter:replies lang:en"

  - name: ai-workflows
    queries:
      - "developer workflow LLM"
      - "LLM tool use"
      - "AI-assisted development"
    max_results: 50
    filters: "min_faves:20 -filter:replies lang:en"

  # Future: account monitoring
  # accounts:
  #   - username: "example_user"
  #     pull_all: true
```

**Config file location:** `config/topics.yaml` relative to the pipeline repo root (`~/openclaw/x-feed-intel/config/topics.yaml`). This file is version-controlled in the pipeline repo. The topic config loader (XFI-003) reads this path on each capture clock run — no hot-reload or restart required.

**Tess topic management:** Tess can read and modify the topic config on the operator's behalf via Telegram commands. Supported interactions:

- **List topics:** Operator asks what topics are configured. Tess reads `config/topics.yaml` and reports topic names, query counts, and filter settings.
- **Add topic:** Operator requests a new topic. Tess proposes queries and filters (or accepts operator-specified ones), appends the topic entry to the config, runs the topic config loader's validation to confirm valid YAML and schema, and commits the change to git. If validation fails, Tess reverts the edit and reports the error.
- **Remove topic:** Operator requests topic removal. Tess confirms the topic name, removes the entry, validates, and commits.
- **Modify queries/filters:** Operator requests changes to an existing topic's queries or filters. Tess applies the edit, validates, and commits.

All topic config edits follow the same procedure: (1) read current config, (2) apply edit, (3) run topic config loader validation, (4) commit to git on success or revert on failure, (5) confirm to operator. Changes take effect on the next capture clock run.

Tess does not modify topic config autonomously. All changes are operator-initiated via Telegram.

**Filter resolution:** Per-topic `filters` override the global default. When the topic scanner constructs a query, it appends the resolved filter string to the raw query text. If Phase 0 reveals that TwitterAPI.io does not support a given operator, the pipeline falls back to client-side filtering: after fetching results, discard posts below the configured engagement threshold using the engagement data in the normalized format. This fallback is transparent to downstream components.

**Design constraint:** Topic list must be trivially extensible. Account monitoring (Phase 2) is anticipated in the config schema but not implemented in Phase 1.

### 5.3 Normalizer

Converts raw API responses from both sources into a unified internal format with canonical identity:

```json
{
  "canonical_id": "1234567890",
  "source_instances": [
    {
      "source": "bookmark",
      "fetched_at": "2026-02-21T14:00:00Z",
      "search_query": null
    },
    {
      "source": "search",
      "fetched_at": "2026-02-21T14:05:00Z",
      "search_query": "agentic coding"
    }
  ],
  "first_seen_at": "2026-02-21T14:00:00Z",
  "last_seen_at": "2026-02-21T14:05:00Z",
  "author": {
    "username": "handle",
    "display_name": "Name",
    "follower_count": 12345
  },
  "content": {
    "text": "Full post text...",
    "urls": ["https://..."],
    "media": ["image_url_1"],
    "is_thread": false,
    "thread_position": null,
    "conversation_id": null,
    "needs_context": false
  },
  "metadata": {
    "created_at": "2026-02-21T10:30:00Z",
    "engagement": {
      "likes": 150,
      "reposts": 42,
      "replies": 18,
      "bookmarks": 30
    },
    "matched_topics": ["agent-architecture", "claude-code"]
  }
}
```

**Canonical identity:** `canonical_id` is the native X platform post ID, stripped of any prefix or formatting. This is the single key used for global dedup. `source_instances` tracks where and how the post was discovered, allowing a single post to be attributed to multiple sources without duplication.

**`matched_topics` behavior across runs:** The `matched_topics` field is append-only. If a post was first seen via the "agent-architecture" topic query on Monday and is re-encountered via a "claude-code" query on Wednesday, the dedup engine adds "claude-code" to the existing `matched_topics` array in the state store (alongside updating `source_instances` and `last_seen_at`). This preserves multi-topic signal for items still in the `pending` queue. For items already triaged, the update is recorded in the state store but does not trigger re-triage.

**Thread heuristic:** The normalizer detects likely thread posts using simple heuristics (e.g., text contains "🧵", "thread", "/n" pattern, or author self-replies). If detected, `needs_context` is set to `true`. This flag is consumed by the triage engine — it does not trigger additional API calls in Phase 1.

**Phase 0 verification required:** During Phase 0, verify that both API sources return `in_reply_to_status_id` / `conversation_id` fields (or equivalents) in their response payloads. The self-reply heuristic depends on these fields. Document the actual available fields and adjust the heuristic if needed. The string-matching heuristics ("🧵", "thread") will produce false positives on posts that discuss threads conceptually; accept this as a known limitation and rely on the `confidence` field in triage to flag uncertain cases.

### 5.4 Global Dedup Engine

Maintains a rolling manifest of processed `canonical_id` values across all sources and runs via the `posts` table. A post seen in any prior run is not re-queued for triage.

If a post was previously seen via search and is now seen via bookmark (or vice versa), the dedup engine updates the existing record's `source_instances` and appends to `matched_topics` in the state store without re-triaging. If the item is still in `pending` queue status (not yet triaged), the multi-source signal is preserved and available to the triage engine — a post discovered via both bookmark and search may receive a relevance boost during triage.

**Storage:** See §7.2 for storage decision.

### 5.5 Triage Engine

The core intelligence layer. Tess evaluates each batch of net-new posts from the durable queue and produces structured triage decisions.

**Triage context:** At triage time, Tess receives:
- The batch of post texts (10-20 at a time)
- A lightweight vault snapshot: a pre-computed summary of Danny's current context

#### 5.5.0 Vault Snapshot Contract

The vault snapshot is the primary determinant of triage quality. It must be treated as a versioned, bounded artifact — not an ad-hoc vault query.

**Format:** `_openclaw/feeds/vault_snapshot.yaml`

**Fields:**

```yaml
# vault_snapshot.yaml — maintained by Tess, refreshed before each attention clock run
snapshot_version: 1
generated_at: "2026-02-21T07:55:00Z"

active_projects:
  - name: x-feed-intel
    status: PLAN
    focus: "pipeline implementation, triage prompt engineering"
  - name: notebooklm-pipeline
    status: SPECIFY
    focus: "parser design, Chrome extension verification"

current_focus_tags:
  - compound-engineering
  - skill-creation
  - moc-architecture

recent_crumb_topics:
  - "binary attachment support"
  - "vault-check.sh validation"
  - "diagramming skills peer review"

operator_priorities: |
  This week: ship x-feed-intel Phase 0, finalize NLM spec.
  Ongoing: Crumb Phase 1b implementation.
```

**Token budget:** Max 600 tokens. The snapshot is a routing hint, not a knowledge base. If it exceeds 600 tokens, truncate `recent_crumb_topics` first, then `active_projects` descriptions.

**Refresh cadence:** Tess regenerates the snapshot immediately before the attention clock runs (default: 7:55 AM, 5 minutes before triage). Generation reads: active project frontmatter from `Projects/`, the `operator_priorities` field from a designated config location, and recent Crumb session summaries from `_openclaw/outbox/`.

**Input fallback rules:** Snapshot generation must be robust against partial input availability:
- If `_openclaw/outbox/` is empty or contains no recent summaries: set `recent_crumb_topics: []` and proceed normally. An empty outbox is a normal state (e.g., no recent Crumb sessions), not a failure.
- If project frontmatter for an active project is missing or malformed (e.g., missing required fields): skip that project entry, log a warning, and continue with remaining projects. A single malformed file must not cascade into a snapshot generation failure.
- If the `operator_priorities` source file is missing: set `operator_priorities: "No priorities set."` and proceed. The file location is `_openclaw/config/operator_priorities.md` — Danny can edit this directly; it always exists, even if empty.

**Failure mode:** If snapshot generation itself fails (script crash, filesystem error) or the file is missing at triage time, triage proceeds with no context. The digest includes a warning: "⚠️ Vault snapshot unavailable — triage ran without project context. Relevance may be reduced." This failure mode is reserved for actual generation failures, not for partial input streams being empty.

**Operator override:** Danny can edit `operator_priorities` directly to steer triage toward or away from specific topics. This is the manual knob for triage relevance.

**Triage mode:** Batch-oriented. Posts are grouped into batches of 10-20 and submitted in a single LLM call with instructions to evaluate and label each one. The prompt interface supports both single-post and batch mode from day one, but batch is the default.

**Triage prompt engineering is an explicit Phase 1 deliverable.** The prompt must produce consistent, structured output across diverse post types. Expect 2-3 iterations of prompt refinement during Phase 1 implementation, validated against the Phase 0 benchmark sample (see §12). See Appendix A for a v0 prompt skeleton that anchors the expected structure.

#### 5.5.1 Triage Output Schema

Every post receives a structured triage decision. This is the contract between the triage engine and all downstream consumers (digest, vault router).

```json
{
  "canonical_id": "1234567890",
  "priority": "high" | "medium" | "low",
  "tags": ["crumb-architecture", "tool-discovery"],
  "why_now": "Describes a vault-level compound engineering pattern directly applicable to Phase 2 skill creation.",
  "recommended_action": "capture" | "test" | "add-to-spec" | "read" | "ignore",
  "vault_target": null | "_openclaw/inbox/" | "kb/...",
  "confidence": "high" | "medium" | "low",
  "needs_context": false
}
```

**Field definitions:**

- `priority` — high / medium / low. Determines digest section placement and whether the post is routed to vault.
- `tags` — non-exclusive categorization labels (see below).
- `why_now` — one line: why this matters *this week*, referencing current projects or focus areas where possible.
- `recommended_action` — what Danny should do with this:
  - `capture` — a durable pattern, insight, tool, or reference worth preserving. **This is the default for anything interesting.** Use this when the value is in knowing about the pattern/tool/insight, not in taking a specific action in our stack. Most items that pass the quality bar should be `capture`. Items assessed as `capture`-worthy appear in the digest normally but are not auto-routed to KB. Danny uses the `save` command (§5.8) to explicitly request KB staging.
  - `test` — a **specific** tool or technique that we should evaluate in our infrastructure, with a **concrete integration point already identified**. Not "this tool exists" (that's `capture`) but "we should try this tool for [specific Crumb/Tess use case]." Should be rare — 1-2 items per batch maximum. Tess-owned unless also tagged `crumb-architecture`.
  - `add-to-spec` — a **specific** pattern that warrants a change to an **existing** Crumb specification section. Must reference a concrete spec section or design decision that would be modified. Not "this is an interesting architectural pattern" (that's `capture`) but "this changes how we should implement [specific thing in specific spec]." Even rarer than `test` — always Crumb-owned.
  - `read` — worth reading in full but no immediate action
  - `ignore` — low signal, included in digest for completeness
- `vault_target` — where this should land if routed. `null` = digest only.
- `confidence` — Tess's self-assessed confidence in the triage decision. Low-confidence + high-priority items are flagged in the digest for Danny's manual review.
- `needs_context` — inherited from normalizer. If `true` and priority is `high`, the digest notes "thread likely — expand before final decision."

**Categorization tags:**

- `crumb-architecture` — concrete pattern, tool, or decision that could plausibly change current architecture or workflow. This tag triggers routing to `_openclaw/inbox/`.
- `architecture-inspiration` — interesting architectural thinking that doesn't meet the `crumb-architecture` bar. Digest only, does not auto-stage for Crumb.
- `tess-operations` — relevant to Tess's capabilities, agent UX, or operational patterns.
- `tool-discovery` — a tool, library, or service worth evaluating.
- `pattern-insight` — a design pattern, workflow, or approach worth capturing.
- `community-signal` — what the broader community is building/thinking (trend awareness).
- `general-interest` — interesting but not directly actionable.

**Minimum bar for `_openclaw/inbox/` routing:** Only posts tagged `crumb-architecture` with `recommended_action` of `add-to-spec`, `test`, or `capture` AND `confidence: high` are auto-staged to `_openclaw/inbox/`. Medium-confidence items appear in the digest only (operator can manually promote via digest reply). This prevents the Crumb inbox from becoming a link dump. Changed 2026-03-05: raised floor from `medium` to `high` — `medium` was letting 45% of items through as T1.

### 5.6 Vault Router

Posts that meet the routing bar (§5.5) are written to the appropriate vault location:

- **Crumb-relevant items** → `_openclaw/inbox/` as markdown with frontmatter, triage output, and a Tess-generated summary. Format: one file per item, named `feed-intel-{canonical_id}.md`.
- **KB-worthy items** (user-requested via `save` command, §5.8) → `_openclaw/feeds/kb-review/` as markdown with same format as Crumb-routed items plus `save_reason` frontmatter field. Crumb reviews and routes to permanent KB locations during governed sessions. Tess does not write to KB locations autonomously.

**KB tag assignment:** The pipeline's triage tags (`crumb-architecture`, `tool-discovery`, etc.) drive routing decisions within the pipeline. They are not KB tags. When Crumb reviews items in `_openclaw/feeds/kb-review/`, Crumb assigns the appropriate `#kb/` tag from the canonical vault taxonomy (e.g., `#kb/software-dev`, `#kb/software-dev/agent-architecture`). This separation keeps Tess's routing logic independent from the vault's knowledge classification. Tess never assigns `#kb/` tags.

- **Everything else** → included in digest only, persisted in the SQLite state store for historical reference.

**Idempotency rule:** The router uses the canonical filename `feed-intel-{canonical_id}.md` as an idempotency key. Behavior when the file already exists:

- **If the file exists and was not manually edited** (no operator-added content below the `<!-- OPERATOR NOTES BELOW -->` marker): update the frontmatter and triage block in place. This handles re-triage after source_instances updates or priority changes from feedback.
- **If the file exists and contains operator notes** (content below the marker): update only the bounded triage section (frontmatter + triage block above the marker). Never touch operator-added content. This prevents `promote` commands or pipeline re-runs from overwriting Danny's manual annotations.
- **File structure:**

```markdown
---
type: x-feed-intel
canonical_id: "1234567890"
source: bookmark, search
author: "@handle"
priority: high
tags: [crumb-architecture, tool-discovery]
recommended_action: add-to-spec
confidence: high
routed_at: "2026-02-21T08:05:00Z"
---

## Triage Assessment

**Why now:** Describes a vault-level compound engineering pattern directly applicable to Phase 2 skill creation.

**Post:** [Full post text]

**Link:** https://x.com/handle/status/1234567890

<!-- OPERATOR NOTES BELOW -->
```

**Governance invariant:** Any changes to vault schema required for feed-intel notes (e.g., new frontmatter fields, new directory conventions) require a Crumb-governed spec update. This project does not unilaterally modify Crumb's vault schema.

### 5.7 Daily Digest (Telegram)

Tess compiles the day's triaged results into a structured Telegram message at the configured time.

**Digest scaling:** The format below works for typical daily volumes. When item count exceeds `MAX_ITEMS_INLINE` (configurable, default 35), the digest switches to a summary-first format: a short overview message on Telegram with a link to a full digest note in `_openclaw/feeds/digests/YYYY-MM-DD.md`.

**Item IDs:** Each digest item includes a short alphanumeric ID (e.g., A01, B07) that Danny can use in reply-based commands (see §5.8).

```
📡 X Feed Intel — Feb 21, 2026
━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 HIGH PRIORITY (3)

A01 [crumb-architecture] @author
"Key insight excerpt..."
→ Why now: [Tess 1-line assessment]
→ Action: add-to-spec | Confidence: high
🔗 link

A02 [tool-discovery] @author
"Key insight excerpt..."
→ Why now: [Tess 1-line assessment]
→ Action: test | Confidence: medium
⚠️ Thread likely — expand before final decision
🔗 link

A03 [crumb-architecture] @author ⚠️ low confidence
"Key insight excerpt..."
→ Why now: [Tess 1-line assessment]
→ Action: capture | Confidence: low — review manually
🔗 link

━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 MEDIUM (8)

B01 @author — pattern-insight — "excerpt..." 🔗
B02 @author — tess-operations — "excerpt..." 🔗
[...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚪ LOW / FILED (5)

C01 @author — "excerpt..." 🔗
[...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Stats: 16 new (8 bookmarks, 12 search, 4 overlap)
💰 Today: $0.12 | MTD: $1.84 | Projected: $2.76

Reply: [ID] promote | [ID] ignore | [ID] add-topic [name]
```

**Digest timing:** Configurable. Default: once daily (e.g., 7:00 AM local).

**Timezone convention:** All timestamps in the state store, logs, and normalized post data use UTC (ISO 8601 with `Z` suffix). Schedule times (capture clock, attention clock, digest delivery) are specified in local time (America/Detroit). All dates shown in digests use local time (America/Detroit); the state store remains UTC. The pipeline converts between local and UTC at the scheduling boundary. This prevents drift and ensures that "items captured today" queries against the state store are computed correctly regardless of DST transitions.

**Empty days:** "No new signal today." — one line, no empty template.

**Degraded mode:** If one upstream failed during the capture clock, the digest notes it: "⚠️ X API failed this run — bookmarks not included" or "⚠️ Search offline — showing bookmarks only."

### 5.8 Reply-Based Control Protocol

Danny can reply to the digest with simple text commands using item IDs. Tess parses these and acts accordingly. This provides a Phase 1 feedback mechanism without requiring UI or emoji reactions.

**Commands:**

| Command | Effect |
|---|---|
| `A01 promote` | Promote item to `_openclaw/inbox/` if not already routed |
| `B03 save` | Stage item to KB review queue for permanent vault storage during next Crumb session |
| `B07 ignore` | Mark as noise; feeds into relevance tuning |
| `C03 add-topic [name]` | Suggest a new topic based on this post's content |
| `A01 research` | Enrich with thread context and notable replies, then dispatch to Crumb for web research via bridge (§5.8.1) |
| `research {url}` | Standalone (non-reply): dispatch any captured post for enriched research by URL, independent of current digest (§5.8.2) |
| `A02 expand` | Flag for thread expansion in next run (Phase 2 implementation) |

**Error handling:** The feedback listener parses replies against a strict grammar: `{ID} {command} [argument]`. Behavior for invalid input:

- **Malformed command** (e.g., `A01 promot`, `hello`, `thanks`): Tess replies: "Didn't parse that. Format: `A01 promote` / `B03 save` / `B07 ignore` / `C03 add-topic AI-safety`. No action taken."
- **Nonexistent item ID** (e.g., `X99 promote`): Tess replies: "No item X99 in today's digest. Check the ID and try again."
- **Duplicate command** (e.g., `A01 promote` sent twice): Tess replies: "A01 already promoted — no duplicate action taken."

**Conditional confirmation for `promote`:** The `promote` command uses the triage engine's own structured output as a safety gate:

- **If the item already meets the routing bar** (tagged `crumb-architecture` with `confidence: high`): promote executes immediately in one step. Tess confirms: "✅ A01 staged to `_openclaw/inbox/feed-intel-1234567890.md`."
- **If the item is outside the routing bar** (not tagged `crumb-architecture`, or `confidence` below `high`): Tess echoes the intended action and requests confirmation: "A01 is tagged [general-interest] with medium confidence. Promote to Crumb inbox anyway? (yes/no)". Danny replies `yes` to proceed or `no` to cancel.

This gives fast one-tap promotes for obvious items and adds friction only where the triage model flagged uncertainty — using the pipeline's own intelligence as the safety gate.

**`save` command behavior:** The `save` command stages an item to `_openclaw/feeds/kb-review/` as a markdown file using the same format as vault-routed items (§5.6), with filename `feed-intel-{canonical_id}.md` and an additional frontmatter field: `save_reason: "user-requested via digest"`. Tess confirms: "📌 B03 saved to KB review queue." No confirmation gate required (low-stakes, easily reversible). Duplicate `save` on the same item: "B03 already saved — no duplicate action taken."

The `_openclaw/feeds/kb-review/` directory is Tess-owned (write) and Crumb-consumed (read). During Crumb sessions, queued items are reviewed and routed to permanent KB locations with proper frontmatter, domain tags, and cross-linking. Files remain until Crumb processes them — no TTL, since these are explicitly user-requested saves.

`ignore`, `save`, and `add-topic` do not require confirmation — they are low-stakes and easily reversible.

**Standalone commands:** The feedback listener handles two non-reply commands before checking `reply_to_message`: `refresh` (XFI-022b) triggers an immediate capture + digest cycle, and `research {url}` (§5.8.2) dispatches any captured post for enriched research by URL. All other non-reply messages are ignored (messages are matched to digests by Telegram's `reply_to_message_id`).

**Feedback storage:** Commands are logged to the `feedback` table in the SQLite state store. The `command` field records the action (`promote`, `save`, `ignore`, `add-topic`, `expand`, `research`). Over time, accumulated `promote`, `save`, and `ignore` signals are used to adjust per-topic weights and priority thresholds. `save` signals reveal what Danny values for long-term knowledge (distinct from architecture relevance); this data feeds into the Phase 3 learning loop. This is not model fine-tuning — it's simple weight adjustment on triage inputs.

**Minimum sample size:** Topic weights are not adjusted until `MIN_FEEDBACK_EVENTS` (configurable, default 10) feedback signals have been recorded for that topic. This prevents one noisy day from skewing the model. Weight adjustments are stored in the `topic_weights` table.

**Weight adjustment mechanics (Phase 3):** The `topic_weights.weight_modifier` column and feedback accumulation infrastructure are established in Phase 1, but the mechanics of how `weight_modifier` influences triage scoring (e.g., as a multiplier on priority, as input to the triage prompt, or as a threshold adjustment) are a Phase 3 deliverable. Phase 1 captures the signals; Phase 3 defines and implements the closed-loop behavior.

> "Feedback is captured from simple Telegram replies and used to adjust topic weights and high/medium thresholds, not to train a custom model."

#### 5.8.1 Research Command: Context Enrichment

When the feedback listener processes a `{ID} research` command, it enriches the item with full thread context and notable replies before dispatching to Crumb via the bridge. This pulls forward the thread expansion capability deferred to Phase 2 in §7.5, scoped to operator-initiated research dispatch only — not all captured content.

**Trigger:** Enrichment runs only on `research` commands. It does NOT run for `promote`, `save`, or other commands.

**Step 1 — Thread expansion.** If the post has `conversation_id` (persisted in the `posts` table during normalization):

- Fetch the conversation chain via TwitterAPI.io `GET /twitter/tweet/thread_context?tweetId={id}`, which returns the full lineage (parent tweets above, replies below) for any tweet in a thread
- Order chronologically (earliest first)
- Include all posts in the direct reply chain regardless of author — any post where `inReplyToId` points to another post in the chain (direct conversation participants). Exclude bystander top-level replies (those go to step 2)
- Build a `thread_context` array: `[{ position: 1, author: "...", text: "...", created_at: "..." }, ...]`
- Include the original post in its correct thread position
- Note: `thread_context` response may report `has_next_page: true` even when no additional data exists (documented TwitterAPI.io limitation) — paginate only if cursor returns results

If the post has no `conversation_id` or is a standalone post, skip this step. `thread_context` is null.

**Step 2 — Reply mining.** Fetch top-level bystander replies (not part of the direct conversation chain from step 1):

- Use TwitterAPI.io `GET /twitter/tweet/replies?tweetId={root_id}` (returns direct replies, up to 20 per page)
- Exclude any authors already present in `thread_context`
- Sort by engagement (likes + retweets) descending
- Take top N replies (default: `enrichment.max_replies`, configurable in pipeline config)
- Filter out noise: replies with no text, pure emoji replies, replies shorter than `enrichment.min_reply_length` chars
- Build a `notable_replies` array: `[{ author: "...", text: "...", likes: N, retweets: N }, ...]`

If no replies exist or the API call fails, `notable_replies` is an empty array. Enrichment failure is non-blocking.

**Step 3 — Package enriched context.** Write an enriched context file to the investigate directory:

```
_openclaw/feeds/investigate/research-{canonical_id}-context.md
```

The file is UTF-8 encoded (the pipeline's ASCII sanitization applied to the dispatch `context` field does NOT apply here). Contents include: original post with full text and engagement metrics, thread context (if available) with author attribution per post, notable replies ranked by engagement, and the triage decision (priority, tags, rationale, confidence).

**Step 4 — Update dispatch request.** The bridge dispatch `description` field references the enriched context file by path instead of embedding post text inline. The `files` array includes the context file path (which exists at dispatch time, unlike the research output file). This addresses peer review findings about context truncation (OAI-F7), ASCII sanitization data loss (OAI-F6, GEM-F2, DS-F3, GRK-F3), and prompt injection from untrusted content (OAI-F20).

**File naming convention in `_openclaw/feeds/investigate/`:**
- `research-{canonical_id}-context.md` — enrichment input (written by Tess, read by Crumb). Persists for auditability.
- `research-{canonical_id}.md` — research output (written by Crumb after research completes).

**Telegram UX:** The listener sends an initial ack ("🔍 Researching A01 — expanding thread..."), performs enrichment, then sends a second ack ("Context expanded — dispatching to Crumb...") before dispatch. The second ack is suppressed if enrichment took <2s.

**Error handling:**
- API failure on thread expansion: log warning, proceed with original post only. Context file notes: "Thread expansion failed — original post only."
- API failure on reply mining: log warning, proceed with empty replies. Context file notes: "Reply fetch failed."
- Rate limiting: dispatch immediately with whatever context was gathered. Do NOT retry enrichment after dispatch — the research command is a one-shot operator action.
- Both fail: dispatch proceeds with original post text only (current behavior). Enrichment is additive, not blocking.

**Cost impact:** Per enrichment (TwitterAPI.io uniform pricing: $0.15/1000 tweets returned): thread expansion ~$0.00075-0.0015, reply mining ~$0.0015. Total ~$0.002-0.003 per enrichment. At 5 researches/day: ~$0.30-0.45/month.

**Investigate file frontmatter** — add optional enrichment fields:

```yaml
enrichment:
  thread_expanded: true | false
  thread_posts: 8
  replies_fetched: 10
  api_calls: 2
  enriched_at: "2026-02-25T07:30:00Z"
```

**Pipeline config** — add enrichment defaults:

```yaml
enrichment:
  max_replies: 10
  min_reply_length: 20
  enabled: true
```

#### 5.8.2 Backlog Research Command

The `research {url}` standalone command dispatches any previously captured post for enriched research, independent of the current digest. This addresses the ephemeral ID problem: item codes (A01, B03) reset with each digest, so historical posts cannot be referenced via the reply-based `{ID} research` path once a new digest arrives.

**Command format:** Standalone (non-reply) message: `research https://x.com/{author}/status/{id}`. Also accepts `twitter.com` URLs and raw canonical IDs (`research {canonical_id}`). Case-insensitive command word.

**Resolution flow:**
1. Parse URL → canonical ID (numeric tweet ID from URL path, or raw numeric input)
2. DB lookup in `items` table — post must have been captured by the pipeline. If not found: "Post {id} isn't in the database."
3. Dedup check: query `feedback` table for `canonical_id + command = 'research'`. If already dispatched: "Already researched — see `{filename}`" with the actual research output filename for navigation
4. Dispatch via the shared `dispatchResearch()` core — identical enrichment, context file, bridge dispatch, and completion polling as reply-based research

**Feedback storage:** `digest_date` = original capture date from `posts.first_seen_at` (not today). `item_id` = canonical ID (no ephemeral code available). `command` = `research`.

**Telegram UX:** Initial ack includes author + text excerpt (user doesn't have a digest in front of them): "Researching @{author}: "{excerpt}" — expanding context..."

**Cost impact:** Zero incremental vs reply-based research — same enrichment calls, same bridge dispatch.

See `design/x-backlog-research-amendment.md` for full design rationale.

#### 5.8.3 Linked Content Fetch

During enrichment (§5.8.1), posts containing embedded URLs trigger a linked content fetch. This captures article content that the tweet text alone doesn't convey — particularly relevant for X Article-format posts where the tweet body is just a t.co link.

**Trigger:** Any post with an embedded URL (`https?://` pattern in tweet text). The fetch runs between thread expansion (step 1) and reply mining (step 2) in the enrichment pipeline.

**Fetch behavior:**
- Follow HTTP redirects (301/302/303/307/308) from t.co → final URL
- Strip HTML to plain text (remove script/style/nav/footer, decode entities)
- Truncate at 3000 chars on word boundary
- Skip if extracted text < 100 chars (insufficient content)

**X Article guard:** URLs resolving to `x.com/i/article/` are client-side rendered SPAs — HTTP GET returns a JS-disabled error page. These are detected after redirect resolution and skipped with an error note.

**Context file output:** Linked content appears as a `## Linked Content` section in the context file, with the resolved URL and extracted text. Investigate file frontmatter includes `article_fetched: true|false`.

**Cost impact:** Zero API cost — plain HTTP fetch. One additional HTTP request per post with embedded URL.

#### 5.8.4 Compound Insight Output

Research outputs may include structured compound insights — cross-cutting patterns, architecture validations, or actionable signals that extend beyond the specific post being researched. These are captured as `compound_insight` YAML frontmatter in the research output file, enabling machine-readable routing into the vault's compound engineering system.

**Dispatch instruction:** The bridge dispatch `args` field includes a compound insight instruction telling Crumb to add a `compound_insight` block to research output frontmatter when applicable, and omit it entirely for informational-only research.

**Schema:**

```yaml
compound_insight:
  pattern: "1-sentence description of the reusable insight"
  scope: "architecture-decision-record | pattern-document | convention-update | project-specific"
  target: "_system/docs/ or project design/ directory"
  confidence: "low | medium | high"
  durability: "permanent | perishable"
  valid_as_of: "YYYY-MM-DD"  # required when durability is perishable
  related_research: []        # populated by convergence detection (Phase 2)
```

**Scope → routing map:**
- `architecture-decision-record` → `_system/docs/`
- `pattern-document` → `_system/docs/solutions/`
- `convention-update` → existing doc (CLAUDE.md, file-conventions, etc.)
- `project-specific` → relevant project's `design/` directory

**Durability:** `permanent` for architecture patterns and design principles (valid indefinitely). `perishable` for model-dependent or tool-version-specific observations (requires `valid_as_of` date; session startup scan flags insights past a 90-day review threshold).

**Session startup scan (Crumb-side):** The vault session startup script scans `_openclaw/feeds/research/*.md` for unrouted `compound_insight` frontmatter. Reports pending count and stale perishable count. During session, Crumb presents pending insights to operator for routing decision: **route** (create target artifact, mark `routed_at` + `routed_to`), **defer** (stays pending), or **dismiss** (mark `dismissed: true`, skipped on future scans).

**Convergence detection (Phase 2, deferred):** When 2+ unrouted insights share overlapping `pattern` descriptions or identical `target` paths, flag the convergence for operator decision. Requires sufficient research volume to be useful.

**FIF portability:** The `compound_insight` schema is source-agnostic — no source-specific fields. It carries forward to feed-intel-framework unchanged. The startup scan operates on `_openclaw/feeds/research/` regardless of which adapter produced the research.

See `design/x-compound-routing-amendment.md` for full design rationale.

### 5.9 Cost Telemetry

The pipeline tracks costs per run and persists them for ongoing visibility.

**Tracked metrics:**
- `cost_this_run` — estimated cost of the current capture + triage run
- `month_to_date` — cumulative cost for the current billing cycle
- `projected_month` — extrapolated monthly cost based on current run rate

**Storage:** Appended to the `cost_log` table in the SQLite state store (§7.2) with timestamps.

**Digest integration:** MTD and projected cost appear in every digest footer. If `projected_month` exceeds 80% of the X API spending cap, Tess includes a warning: "⚠️ Approaching X API spending cap — projected $4.20 vs $5.00 limit."

**Phase 1 cost guardrail:** If `projected_month` exceeds 90% of the combined budget target ($6), the pipeline automatically reduces `max_results` by 50% for all topic scanner queries on the next capture clock run. This is a conservative, reversible measure — not the full backpressure router (Phase 2). The reduction persists until `projected_month` drops below 80% of the combined target, at which point `max_results` reverts to configured values. The digest notes when the guardrail is active: "⚠️ Cost guardrail active — search volume reduced."

## 6. Scheduling & Orchestration

The pipeline is modeled as two decoupled clocks.

### 6.1 Capture Clock

| Component | Schedule | Notes |
|---|---|---|
| Bookmark Puller | Daily (default 6:00 AM) | Retries up to 3x on failure with exponential backoff |
| Topic Scanner | Every 2-3 days (configurable per topic) | Per-run dedup cache active |
| Normalizer | Runs after each puller/scanner run | Chained |
| Global Dedup | Runs after normalizer | Chained |
| Queue Write | Appends net-new items to durable queue | End of capture chain |

The capture clock can run independently and retry without affecting the attention clock. If an API is down, the capture clock logs the failure, skips that source, and tries again on the next scheduled run.

### 6.2 Attention Clock

| Component | Schedule | Notes |
|---|---|---|
| Queue Read | Daily at digest time (default 7:00 AM) | Reads all pending items from queue |
| Triage Engine | After queue read | Batch mode — processes all pending items |
| Vault Router | After triage | Routes items meeting the inbox bar |
| Cost Telemetry | After routing | Computes run cost + updates MTD |
| Daily Digest | After telemetry | Compiles and sends to Telegram |
| Feedback Listener | Ongoing | Parses Danny's replies asynchronously |

### 6.3 Error Handling

**Principles:**
- No silent failures. Every failure produces a visible signal (log entry + Telegram notification if critical).
- Partial success is acceptable. If bookmarks fail but search succeeds, the digest includes search results only with a degraded-mode note.
- Retry with exponential backoff for transient API failures (3 retries, 30s / 60s / 120s).

**Failure scenarios:**

| Scenario | Behavior |
|---|---|
| X API down or rate limited | Bookmark pull skipped. Retry next capture run. Digest notes degraded mode. |
| TwitterAPI.io down | Search skipped. Retry next capture run. Digest notes degraded mode. |
| OAuth token expired / revoked | Bookmark pull skipped. Telegram alert: "Re-authorize X API token." (See §10 for re-auth procedure.) |
| OpenClaw down (Tess unavailable) | Triage skipped. Items remain in durable queue. Telegram alert: "Triage queued — OpenClaw offline." Digest not sent until triage completes. |
| Mac Studio rebooted mid-run | Durable queue ensures no data loss. Next scheduled run picks up where it left off. |
| Cost cap hit | X API requests blocked by console. Digest notes: "X API cap reached — bookmarks paused until next billing cycle." |
| Batch triage partial failure | If structured output is malformed for one or more posts in a batch, isolate the failed posts, retry them individually in a follow-up call. If individual retry also fails, mark as `queue_status = 'triage_failed'` in the state store and include in digest with a warning: "⚠️ Triage failed for this item — showing raw post." |

### 6.4 Queue Health & Backlog SLOs

The two-clock architecture means the durable queue can grow silently when triage is offline or failing. Without explicit health checks, Danny could return from a week away to an unmanageable backlog.

**Queue SLOs:**

| Metric | Threshold | Behavior |
|---|---|---|
| Max pending items | 100 | If pending exceeds 100, Tess sends Telegram alert: "Queue backlog: {n} items pending." Triage proceeds but switches to summary mode. |
| Max age of oldest item (search) | 7 days | Search-sourced items older than 7 days that haven't been triaged are auto-archived with `queue_status = 'expired'`. They remain queryable in the state store but are excluded from triage and digest. |
| Max age of oldest item (bookmark) | 30 days | Bookmark-sourced items use a 30-day expiry. Bookmarks are user-curated and may remain valuable longer than search-discovered content. After 30 days untriaged, they expire with the same archival behavior. |
| Backlog digest | Triggered when pending > 50 at attention clock time | Instead of a full item-by-item digest, Tess sends a backlog summary: "You missed {n} days. {total} items triaged. {high} high-priority routed to inbox. Here are the top {5} by priority:" followed by only the highest-signal items. Full digest archived to `_openclaw/feeds/digests/`. |

**Expiry source determination:** A post's expiry TTL is determined by its `source_instances`. If a post has at least one `source: "bookmark"` instance, it uses the 30-day bookmark TTL regardless of whether it was also discovered via search. Search-only posts use the 7-day TTL.

**Pipeline liveness check:** A daily cron job (separate from the pipeline itself) verifies that at least one successful pipeline run completed in the last 24 hours. If not, sends Telegram alert: "⚠️ Pipeline health check failed — no successful run in 24h."

**Logging:** All pipeline runs log to `pipeline.log` with timestamps, component status, item counts, and error details.

## 7. Open Decision Points

These require resolution during SPECIFY or early PLAN phase.

### 7.1 Implementation Language

**Options:**
- **Python** — rich ecosystem for API clients, JSON/YAML processing, scheduling. Better choice if this evolves into a general-purpose feed ingester beyond X.
- **Node.js / TypeScript** — aligns with OpenClaw's stack if OpenClaw is Node-based. Shared dependency management, logging, and config libraries.

**Recommendation:** Defer to OpenClaw's runtime. Ensure the chosen language can access macOS Keychain and run via cron or launchd.

### 7.2 State Storage

**Decision: SQLite.**

All five peer reviewers converged on this recommendation. The pipeline's data model (canonical_id lookups, cost aggregation, feedback queries, queue state) maps naturally to relational tables. JSON would require a non-trivial migration within months as Phase 2 analytics come online.

**Schema sketch:**

```sql
CREATE TABLE posts (
  canonical_id TEXT PRIMARY KEY,
  source_instances TEXT NOT NULL,  -- JSON array
  first_seen_at TEXT NOT NULL,     -- ISO 8601
  last_seen_at TEXT NOT NULL,
  author_json TEXT NOT NULL,       -- JSON object
  content_json TEXT NOT NULL,      -- JSON object
  metadata_json TEXT NOT NULL,     -- JSON object (includes matched_topics)
  triage_json TEXT,                -- JSON object (null until triaged)
  queue_status TEXT NOT NULL DEFAULT 'pending',  -- pending | triaged | triage_failed | expired | archived
  queued_at TEXT NOT NULL,
  triaged_at TEXT
);

CREATE TABLE cost_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_at TEXT NOT NULL,
  component TEXT NOT NULL,         -- bookmark-puller | topic-scanner | triage
  item_count INTEGER NOT NULL,
  estimated_cost REAL NOT NULL,
  notes TEXT
);

CREATE TABLE feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  received_at TEXT NOT NULL,
  digest_date TEXT NOT NULL,
  item_id TEXT NOT NULL,           -- A01, B07, etc.
  canonical_id TEXT NOT NULL,
  command TEXT NOT NULL,            -- promote | save | ignore | add-topic | expand | research
  argument TEXT,                   -- topic name for add-topic
  applied INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE topic_weights (
  topic_name TEXT PRIMARY KEY,
  feedback_count INTEGER NOT NULL DEFAULT 0,
  promote_count INTEGER NOT NULL DEFAULT 0,
  ignore_count INTEGER NOT NULL DEFAULT 0,
  weight_modifier REAL NOT NULL DEFAULT 1.0,  -- Phase 1: always 1.0. Phase 3: adjusted per §5.8 weight mechanics.
  last_adjusted_at TEXT
);
```

**Queue status values:**
- `pending` — captured, awaiting triage
- `triaged` — triage complete, included in digest
- `triage_failed` — triage attempted and failed after individual retry; included in digest as raw post with warning
- `expired` — untriaged past TTL (7 days for search, 30 days for bookmarks); archived, excluded from digest
- `archived` — manually archived or post-digest cleanup

**Queue ordering:** Items are processed chronologically by `first_seen_at`. If a backlog exceeds the queue SLO threshold (§6.4), processing switches to newest-first for high-priority items to ensure fresh content isn't starved by stale backlog.

**File location:** `state/pipeline.db` relative to the pipeline repository root (outside the vault). The DB is not vault-resident — it lives alongside pipeline code per §8. Backup is a separate operational concern (e.g., cron rsync to a backup location). The DB can be inspected with any SQLite client.

### 7.3 Vault Integration Format

**Recommendation:** `_openclaw/feeds/` as Tess-owned staging area for raw intake and digests. Items meeting the routing bar (§5.5) are promoted to `_openclaw/inbox/` for Crumb, or written directly to a `kb/` location for operational-level items Tess owns.

**Raw intake filename convention:** `feeds/items/YYYY-MM-DD/{canonical_id}.json` for individual items. `feeds/digests/YYYY-MM-DD.md` for daily digest archives.

### 7.4 Account Monitoring

**Recommendation:** Design the topic config schema to include an `accounts` section from day one. Implement topic search only in Phase 1. Account monitoring is Phase 2 — the config structure just needs to anticipate it.

### 7.5 Thread Handling

**Recommendation:** Phase 1 uses the thread heuristic (§5.3) to set `needs_context=true`. No additional API calls for capture or triage. For `high` priority items with `needs_context=true`, the triage output and digest note "thread likely — expand before final decision."

**Research dispatch enrichment (Phase 1):** On-demand thread expansion is implemented for the `research` command (§5.8.1). When an operator dispatches an item for research, Tess fetches the full conversation thread and notable replies via TwitterAPI.io before dispatching to Crumb. This is scoped to operator-initiated research only — not applied to all captured content. Full Phase 2 expansion (automatic for all flagged items) remains deferred.

## 8. Boundary Compliance

Per the agent boundary reference:

- **Crumb owns:** This project spec, architecture decisions, vault schema for feed-intel notes, convergence review of the triage engine logic and prompt.
- **Tess owns:** Runtime operation of the pipeline, triage execution, digest delivery, `_openclaw/feeds/` management, vault promotion of operational items, feedback processing, topic config management (read/add/remove/modify on operator request with validation-before-commit).
- **Bridge protocol:** Tess writes actionable Crumb items to `_openclaw/inbox/` per existing convention. Crumb reads during sessions. The inbox convention is documented in the agent boundary reference (`tess-crumb-boundary-reference.md`).

**Deployment model:** The pipeline is deployed as a Tess-operated service on the Mac Studio, not as a Crumb skill. Pipeline code lives outside the vault. Only configuration (`_openclaw/feeds/`), state artifacts (`vault_snapshot.yaml`), and routed items (`_openclaw/inbox/feed-intel-*.md`) are vault-resident.

**What this project adds:**
- A new `_openclaw/feeds/` directory (Tess-owned) with `items/`, `digests/`, and `kb-review/` subdirectories
- A topic config file at `config/topics.yaml` (operator-editable, Tess-managed)
- State files for dedup, bookmark tracking, cost telemetry, and feedback (pipeline-owned)
- Optionally, new KB notes for promoted content (standard vault schema)

**What this project does not do:**
- Modify Crumb's core design spec or vault schema
- Any schema changes for feed-intel notes require a Crumb-governed spec update

## 9. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Topic queries return garbage | Medium | Wastes triage effort | Phase 0 benchmark validates queries before pipeline build; advanced search operators reduce noise |
| Triage prompt produces inconsistent output | Medium | Bad categorization | Triage prompt is explicit Phase 1 deliverable with 2-3 iteration cycles; v0 skeleton in Appendix A |
| X API pricing changes | Low | Cost increase | Spending cap limits exposure; TwitterAPI.io is fallback for search |
| TwitterAPI.io shuts down or degrades | Low | Lose search stream | X API search is available as fallback (at higher cost — estimate ~2x, $0.60–$0.90/month for equivalent volume). Switch requires code change to use X API v2 search endpoint. |
| OAuth token management headaches | Medium | Pipeline stalls | Auto-refresh + clear error messaging to Telegram |
| `_openclaw/inbox/` becomes a link dump | Medium | Reduces Crumb inbox signal | Minimum routing bar + `architecture-inspiration` tag for digest-only items |
| LLM triage drift over time | Medium | Degrading categorization accuracy | Periodic re-validation against fresh labeled samples (quarterly). Track confidence averages in telemetry. |
| Queue backlog during extended outage | Medium | Stale content, digest overwhelm | Queue SLOs (§6.4): max 100 pending, differentiated expiry (7d search / 30d bookmarks), backlog digest mode |
| Query noise overwhelming triage | Medium | Wasted LLM calls, diluted digest | Phase 0 operator verification + config-level filters + client-side engagement fallback |

## 10. Security & API Key Management

- **X API OAuth 2.0 tokens:** Stored in macOS Keychain on the Mac Studio. Refresh token used for automatic renewal. Never committed to the vault or any repository.
- **TwitterAPI.io API key:** Same treatment — Keychain or env vars.
- **Spending cap:** X Developer Console hard cap set to $5/month initially. Adjustable as usage patterns stabilize.
- **Rate limiting:** The pipeline respects rate limits and implements exponential backoff. No aggressive polling.
- **Telegram bot token:** Stored in Keychain alongside API keys. The pipeline sends messages asynchronously (fire-and-forget with retry) — digest delivery does not block triage or routing.

**OAuth re-authorization procedure (when token refresh fails):**

1. Tess sends Telegram alert: "Bookmark pull failed — OAuth token needs re-authorization."
2. Danny navigates to the X Developer Console → Projects & Apps → [App Name] → Keys & Tokens.
3. Regenerate the OAuth 2.0 client credentials if needed.
4. Run the pipeline's OAuth setup script: `python scripts/x_oauth_setup.py` (opens browser for authorization flow, stores new tokens in Keychain).
5. Verify by running `python scripts/x_bookmark_test.py` (pulls 5 bookmarks as a connectivity check).
6. Pipeline auto-resumes on next scheduled capture clock run.

This procedure should be documented in a runtime operations guide (`docs/x-feed-intel-ops.md`) as a Phase 1 deliverable.

## 11. Success Criteria

1. Danny receives a daily Telegram digest with triaged X content by the configured time.
2. Bookmarked posts appear in the digest within one capture→attention cycle (typically same-day if bookmarked before the capture clock runs; next-day otherwise).
3. Topic scanner surfaces posts not present in Danny's bookmark stream, validated qualitatively during Phase 0 and ongoing operation.
4. High-priority items meeting the routing bar are staged in `_openclaw/inbox/` for Crumb review.
5. Monthly cost stays under $5.
6. Adding a new topic domain requires only editing the topic config file.
7. The pipeline runs unattended on the Mac Studio with no manual intervention under normal conditions.
8. Failures are visible — no silent data loss or missed runs without notification.
9. Danny can provide feedback on digest items via simple text replies.

## 12. Phasing

### Phase 0: Validation (pre-implementation)
- Set up X Developer Account + OAuth flow
- Set up TwitterAPI.io account
- **Verify TwitterAPI.io advanced search operator support** — test `min_faves:`, `-filter:replies`, `lang:en`, and other operators against actual API responses. Document supported syntax in topic config design notes. If unsupported, plan client-side engagement filtering.
- Run a one-off script to pull ~200 bookmarks + ~200 search results per topic query
- Manually skim results to validate topic queries are in the right ballpark
- Refine queries based on findings before building the pipeline
- Verify API response fields for thread heuristic (§5.3): confirm `in_reply_to_status_id` / `conversation_id` availability
- **Optional:** If bookmark backlog exceeds 800, use X's data export feature to seed the state store with historical bookmark IDs (prevents re-processing if pipeline is later extended to handle older data)
- Estimated cost: ~$1-2 for the benchmark pull

### Phase 1: Core Pipeline
- Bookmark puller with OAuth token refresh
- Topic scanner with per-run dedup and config-level filters
- Normalizer with canonical_id + thread heuristic + append-only `matched_topics`
- Global dedup engine (using `posts` table as sole dedup source)
- SQLite state store with schema from §7.2
- Triage engine (batch mode, structured output schema, per-post failure isolation)
- Vault snapshot generator (§5.5.0) with input fallback rules
- Triage prompt engineering (2-3 iterations, validated against Phase 0 sample)
- Vault router with minimum routing bar and idempotent writes (§5.6)
- Daily digest with item IDs + degraded mode messaging + configurable `MAX_ITEMS_INLINE`
- Reply-based control protocol with error handling and conditional promote confirmation (§5.8)
- Cost telemetry (per-run, MTD, projected) including LLM triage costs
- Phase 1 cost guardrail (§5.9): auto-reduce search volume at 90% of combined budget
- Error handling (retries, failure notifications, partial success, batch isolation)
- Queue health monitoring and backlog SLOs with differentiated expiry (§6.4)
- Pipeline liveness check (§6.4)
- State management (SQLite)
- Spending cap configuration
- Runtime operations guide (`docs/x-feed-intel-ops.md`)

### Phase 2: Enrichment
- Account monitoring (always-pull list)
- Thread expansion for flagged high-priority items
- Vault promotion workflow (KB note creation with proper frontmatter)
- Historical trend analysis ("what's been hot this week/month")
- Triage refinement based on accumulated feedback signals
- Digest scaling (summary-first format for 40+ items)
- Backpressure router: auto-reduce `max_results` when `projected_month` approaches cap (closed-loop cost control — extends Phase 1 guardrail with per-topic granularity)
- Triage confidence averages + hit rate tracking in telemetry
- Noise ratio telemetry: track "triaged as noise / total" per topic to inform Phase 3 tuning
- Digest mobile accessibility (short link or local URI for full digest notes)

### Phase 3: Learning Loop
- Automated topic query suggestion based on discovery patterns (presented as a weekly "topic tuning" section in the digest — no silent reconfiguration)
- Per-topic weight adjustment from feedback history
- Priority threshold tuning based on promote/ignore ratios

## 13. Cost Summary

| Component | Monthly Est. | Hard Cap |
|---|---|---|
| X API (bookmarks) | $1.50–$3.00 | $5.00 (console-enforced) |
| TwitterAPI.io (search) | $0.30–$0.45 | Bounded by topic config max_results |
| LLM triage (Haiku 4.5) | ~$0.36 | Bounded by queue volume |
| **Total** | **$2.16–$3.81** | **~$5.50 all-in soft ceiling** |

**LLM cost assumptions:** Triage uses Haiku 4.5 ($0.80/$4 per M input/output tokens). ~1.5 batch calls/day × ~4,300 input tokens (800 system prompt + 600 vault snapshot + 3,000 post batch) + ~1,200 output tokens per call. Sonnet 4 is available as an upgrade path (~$1.35/month) if triage quality on Haiku proves insufficient during Phase 1 prompt iteration.

**Digest excerpts:** Excerpts shown in the digest are the first 140 characters of the post text, mechanically truncated — not LLM-generated summaries. This avoids an additional LLM call per item and keeps costs predictable. If a post is a thread root with `needs_context=true`, the excerpt appends " [🧵 thread]".

**Combined budget target:** $6/month all-in as a soft ceiling across all cost components. The X API hard cap ($5) covers only X API costs; the combined target includes TwitterAPI.io and LLM triage. The Phase 1 cost guardrail (§5.9) auto-reduces search volume when projected costs approach 90% of this target.

## 14. Dependencies

- X Developer Account (free to create, pay-per-use credits purchased in console)
- TwitterAPI.io account (free to create, pay-per-use)
- OpenClaw running on Mac Studio (required for Tess's triage and digest delivery). If OpenClaw is unavailable, items queue and triage is deferred until it's back online.
- Telegram bot (existing — Tess's messaging channel). Confirm bot is set up and Tess has credentials.
- Vault access (existing — `_openclaw/` directory structure)
- macOS Keychain access for credential storage

## 15. Changelog

### v0.6.0 (2026-02-25) — Backlog Research, Linked Content, Compound Routing

**New sections:**
- **F1:** §5.8.2 — Backlog research command (`research {url}`). Standalone Telegram command dispatches any captured post for enriched research by URL, independent of the current digest. Resolves ephemeral item ID limitation. (§5.8.2)
- **F2:** §5.8.3 — Linked content fetch. Posts with embedded URLs trigger HTTP fetch of linked article content during enrichment. X Article guard skips client-side rendered `x.com/i/article/` URLs. (§5.8.3)
- **F3:** §5.8.4 — Compound insight output. Research outputs include structured `compound_insight` YAML frontmatter for machine-readable routing into the vault's compound engineering system. Schema: pattern, scope, target, confidence, durability (permanent/perishable), valid_as_of. (§5.8.4)

**Command table changes:**
- **F4:** `research {url}` added to §5.8 command table as standalone (non-reply) command. (§5.8)
- **F5:** Standalone commands paragraph updated — `refresh` and `research {url}` are now documented as non-reply commands handled before the `reply_to_message` check. (§5.8)

**Infrastructure:**
- **F6:** Session startup compound scan added to `_system/scripts/session-startup.sh`. Scans `_openclaw/feeds/research/` for unrouted `compound_insight` frontmatter, reports pending and stale perishable counts. Startup skill updated with routing procedure (route/defer/dismiss).

**Amendments integrated:**
- `design/x-backlog-research-amendment.md` (status: draft → integrated)
- `design/x-compound-routing-amendment.md` (status: draft → integrated)

### v0.5.0 (2026-02-25) — Context Enrichment on Research Dispatch

**Amendment:** Adds context enrichment to the `research` command flow (§5.8.1). When an operator dispatches an item for research, Tess fetches the full conversation thread and notable replies before dispatching to Crumb via the bridge.

**New section:**
- **E1:** New §5.8.1 added — full enrichment procedure: thread expansion via TwitterAPI.io `thread_context` endpoint, reply mining via `tweet/replies` endpoint, enriched context file written to `_openclaw/feeds/investigate/`, dispatch references file by path instead of embedding truncated post text. (§5.8.1)

**Schema changes:**
- **E2:** `conversation_id` added to normalized post schema as an explicit field. Previously referenced only in thread heuristic text; now persisted in `posts` table for enrichment lookups. (§5.3)
- **E3:** `research` added to feedback table `command` values. (§7.2)
- **E4:** `enrichment` frontmatter block defined for investigate files: `thread_expanded`, `thread_posts`, `replies_fetched`, `api_calls`, `enriched_at`. (§5.8.1)
- **E5:** Pipeline config `enrichment` section: `max_replies`, `min_reply_length`, `enabled` kill switch. (§5.8.1)

**Behavioral changes:**
- **E6:** Thread filtering includes all direct-chain participants regardless of author (not author-only). Captures multi-author back-and-forth. Bystander top-level replies go to reply mining. (§5.8.1)
- **E7:** Enrichment is non-blocking — all API failures degrade gracefully to current behavior (original post text only). No retry after dispatch. (§5.8.1)
- **E8:** `research` command added to §5.8 command table. (§5.8)

**Phase 2 update:**
- **E9:** §7.5 updated to note that on-demand thread expansion is implemented for research dispatch in Phase 1. Full automatic expansion for all flagged items remains Phase 2. (§7.5)

**Addresses peer review findings:** OAI-F6 (ASCII sanitization), OAI-F7 (context truncation), OAI-F20 (prompt injection), GEM-F1 (non-existent file in files array), GEM-F2, DS-F3, GRK-F3.

### v0.4.3 (2026-02-23) — Phase 0 Benchmark Review + Topic Management

**Operator benchmark review (XFI-009):**
- **B1:** Topic config file path pinned to `config/topics.yaml` relative to pipeline repo root. (§5.2)
- **B2:** Tess topic management capability defined — read/add/remove/modify topics via Telegram with validation-before-commit. (§5.2, §8)
- **B3:** KB tag alignment clarified — triage tags are pipeline-internal; `#kb/` assignment is Crumb's responsibility at review time. Tess never assigns `#kb/` tags. (§5.6)
- **B4:** Topic query tuning from benchmark data — `obsidian-pkm` third query replaced ("second brain agent" → "obsidian plugin AI"); `ai-workflows` first query replaced ("AI automation workflow" → "developer workflow LLM") and `min_faves` bumped to 20. (§5.2)
- **B5:** Labeled benchmark set created: `benchmarks/xfi-triage-benchmark-20260223.json` (20 posts, operator-labeled). (§12)

### v0.4.2 (2026-02-23) — Governance Review + `save` Command Amendment

**Governance review** under Crumb governance (G-01 through G-09):
- **G-01:** Removed `status` field from spec frontmatter (project docs inherit lifecycle from directory).
- **G-02:** Added `topics` field (`moc-crumb-operations`) — required for `#kb/` tagged docs.
- **G-03:** Clarified SQLite DB location: `state/pipeline.db` relative to pipeline repo root, outside the vault. (§7.2)

**`save` command amendment** (from peer review discussion, 2026-02-23):
- **S1:** New `save` command added to reply-based control protocol. Stages items to `_openclaw/feeds/kb-review/` for Crumb review during governed sessions. No confirmation gate — low-stakes, easily reversible. (§5.8)
- **S2:** `_openclaw/feeds/kb-review/` directory added. Tess-owned write, Crumb-consumed read. No TTL — user-requested saves persist until processed. (§5.6, §5.8, §8)
- **S3:** `save` added to feedback table `command` values. Feeds into Phase 3 learning loop for KB value signal. (§5.8)
- **S4:** `recommended_action: capture` clarified — Tess assesses KB-worthiness but does not auto-route. Danny uses `save` to explicitly request KB staging. Human stays in the loop. (§5.5.1)

**Notes for PLAN phase** (not addressed in this version):
- G-04: Register `type: x-feed-intel` in vault type taxonomy
- G-05: Track new `_openclaw/` subdirectories in design spec §2.1
- G-06: Firm up implementation language (Node.js per OpenClaw stack)
- G-08: Vault snapshot outbox dependency is soft (fallback handles it)

### v0.4.1 (2026-02-21) — Weight Mechanics Deferral Clarification

**Specification clarifications:**
- **R15:** `weight_modifier` mechanics explicitly deferred to Phase 3. Phase 1 captures feedback signals and maintains the schema; Phase 3 defines how `weight_modifier` influences triage scoring. (§5.8)
- Schema comment added to `topic_weights.weight_modifier` column. (§7.2)

### v0.4 (2026-02-21) — Second Peer Review Consolidation

Incorporates findings from second-round peer reviews (Claude Opus 4.6, DeepSeek V3.2, Gemini 3 Pro, ChatGPT GPT-5.2, Perplexity/Grok) with consensus-driven changes.

**Schema changes:**
- **R1:** `seen_ids` table removed — `posts` table is now the sole dedup source of truth. Unanimous across all five reviewers. (§5.1, §5.4, §7.2)
- **R2:** `triage_failed` added as explicit `queue_status` value. Previously described in §6.3 error handling but absent from schema. (§6.3, §7.2)
- **R3:** `queue_status` enum now documents all five states: `pending | triaged | triage_failed | expired | archived`. (§7.2)

**Behavioral changes:**
- **R4:** Promote confirmation is now conditional on routing bar — items already meeting the `crumb-architecture` + `confidence ≥ medium` bar promote in one step; items outside the bar require confirmation. Replaces the universal two-step flow. (§5.8)
- **R5:** Queue expiry TTLs differentiated by source: 7 days for search-discovered items, 30 days for bookmarks. Bookmarks are user-curated and should not expire on the same timeline as search noise. (§6.4)
- **R6:** Phase 1 cost guardrail added — auto-reduce topic scanner `max_results` by 50% when `projected_month` exceeds 90% of combined budget target. Reverts at 80%. Conservative closed-loop control without full backpressure router. (§5.9)
- **R7:** `matched_topics` is now append-only across runs. Re-encountered posts accumulate topic matches in the state store without re-triaging. (§5.3, §5.4)

**Specification clarifications:**
- **R8:** Topic config schema gains `filters` field (global default + per-topic override) for search operator strings. (§5.2)
- **R9:** TwitterAPI.io advanced operator support documented in §4.2; Phase 0 verification requirement added to §12. (§4.2, §12)
- **R10:** Vault snapshot input fallback rules defined — empty outbox yields `recent_crumb_topics: []`; malformed project frontmatter skips entry with warning; missing operator_priorities yields default string. (§5.5.0)
- **R11:** `operator_priorities` source file pinned to `_openclaw/config/operator_priorities.md`. (§5.5.0)
- **R12:** Success criterion #3 reworded for mechanical verifiability. (§11)
- **R13:** Digest timezone display convention clarified: local time in digests, UTC in state store. (§5.7)

**New content:**
- **R14:** Appendix A — Triage Prompt v0 Skeleton added. Non-normative reference for Phase 1 prompt engineering. (Appendix A)

**New risk register entry:**
- Query noise overwhelming triage (§9)

**New Phase 2 item:**
- Noise ratio telemetry: per-topic "triaged as noise / total" tracking (§12)

**Deferred (no change from v0.3):**
- D1–D9 items remain as documented in v0.3 changelog

### v0.3 (2026-02-21) — Post-Peer-Review Consolidation

Incorporates findings from five peer reviews (Claude Opus, DeepSeek, Gemini, ChatGPT, Perplexity/Grok).

**Must-fix items resolved:**
- **F1:** Vault snapshot defined as versioned artifact (`vault_snapshot.yaml`) with explicit fields, 600-token budget, refresh cadence, and failure mode (§5.5.0)
- **F2:** Vault write idempotency rule added — canonical filename as key, bounded update section, operator notes protected (§5.6)
- **F3:** Storage decision resolved: SQLite with full schema sketch (§7.2)
- **F4:** Reply protocol error handling and promote confirmation semantics specified (§5.8)
- **F5:** Queue health SLOs added — max pending, max age, backlog digest, pipeline liveness check (§6.4)
- **F6:** Batch triage failure isolation specified in error handling table (§6.3)

**Should-fix items resolved:**
- **S1:** Topic config gains `max_age_days` default to prevent stale content (§5.2)
- **S2:** LLM triage cost modeled — Haiku 4.5 baseline, Sonnet 4 upgrade path (§13)
- **S3:** Thread heuristic Phase 0 verification requirement added (§5.3)
- **S4:** Digest scaling threshold now configurable via `MAX_ITEMS_INLINE` (§5.7)
- **S5:** Feedback cooldown: `MIN_FEEDBACK_EVENTS` before weight adjustment (§5.8)
- **S6:** `recommended_action` ownership mapping: `add-to-spec` → Crumb, `test` → Tess unless `crumb-architecture` (§5.5.1)
- **S7:** Pipeline liveness check added (§6.4)
- **S8:** Success criterion #2 corrected to "one capture→attention cycle" (§11)
- **S9:** Digest excerpts defined as mechanical (first 140 chars), not LLM-generated (§13)
- **S10:** Queue processing order specified: chronological, newest-first on backlog (§7.2)
- **S11:** OAuth re-authorization procedure documented (§10)
- **S12:** Timezone convention specified: UTC storage, local scheduling (§5.7)
- **S13:** TwitterAPI.io fallback cost quantified in risk register (§9)

**New risk register entries:**
- LLM triage drift over time
- Queue backlog during extended outage

**Deferred to Phase 2+:**
- D1: Backpressure router (auto-reduce max_results near cost cap)
- D2: Phase 3 topic suggestion presentation format
- D3: 800-bookmark manual export for historical backlog (noted in Phase 0)
- D4: Digest mobile accessibility
- D6: Triage validation benchmark (50-post labeled dataset)
- D7: Triage drift risk — periodic re-validation
- D8: Confidence averages + hit rate telemetry
- D9: Runtime operations guide (noted as Phase 1 deliverable)

---

## Appendix A: Triage Prompt v0 Skeleton (Non-Normative)

This skeleton anchors the expected prompt structure for Phase 1 implementation. It is a starting point — expect 2-3 iterations during prompt engineering.

```
System:

You are Tess, an intelligence triage agent. Your job is to evaluate a batch
of posts from X (Twitter) and produce a structured triage decision for each.

Danny is building a personal operating system (Crumb + Tess). Your triage
decisions determine what reaches his attention and what gets routed to his
vault for deeper work.

## Current Context (Vault Snapshot)

{vault_snapshot}

## Scoring Guidance

For each post, assess:

1. RELEVANCE to active_projects and current_focus_tags. A post that directly
   addresses a current project or focus area scores higher than general
   interest in the same domain.

2. ACTIONABILITY. Prefer concrete patterns, tools, and techniques over
   commentary or opinion. "Here's how I built X" > "I think X is important."

3. TIMELINESS via operator_priorities. If the operator says "this week: ship
   x-feed-intel Phase 0", posts about feed pipeline patterns score higher
   than posts about unrelated projects.

4. NOVELTY relative to recent_crumb_topics. If Crumb recently worked on
   "binary attachment support", a post about the same topic is lower priority
   unless it offers a meaningfully different approach.

## Tag Definitions

- crumb-architecture: concrete pattern, tool, or decision that could
  plausibly change current Crumb/Tess architecture or workflow. This is
  the highest-signal tag — use it sparingly.
- architecture-inspiration: interesting architectural thinking that doesn't
  meet the crumb-architecture bar.
- tess-operations: relevant to Tess's capabilities, agent UX, or
  operational patterns.
- tool-discovery: a tool, library, or service worth evaluating.
- pattern-insight: a design pattern, workflow, or approach worth capturing.
- community-signal: what the broader community is building/thinking.
- general-interest: interesting but not directly actionable.

## Handling needs_context

If a post has needs_context=true, it is likely part of a thread. You may
have incomplete information. Reflect this in your confidence field — use
"low" or "medium" unless the standalone post text is sufficient to triage.

## Output Contract

Return a JSON array with exactly one object per input post, in the same
order as the input. Each object must conform to this schema:

{
  "canonical_id": "<post ID from input>",
  "priority": "high" | "medium" | "low",
  "tags": ["<one or more tags from the list above>"],
  "why_now": "<one sentence: why this matters this week>",
  "recommended_action": "capture" | "test" | "add-to-spec" | "read" | "ignore",
  "vault_target": null | "_openclaw/inbox/" | "kb/...",
  "confidence": "high" | "medium" | "low",
  "needs_context": <boolean, inherited from input>
}

## Action Selection Guide

IMPORTANT: Most items that pass the quality bar should be `capture`. Reserve
`test` and `add-to-spec` for items with a specific, concrete next step:

- "Agent memory architecture using persistent state" → `capture` (pattern
  worth knowing about)
- "New tool X that solves our specific feed pipeline gap" → `test` (concrete
  integration point identified)
- "Pattern Y that contradicts our spec §3.2 design decision" → `add-to-spec`
  (specific spec change needed)
- "Interesting approach to multi-agent coordination" → `capture` (NOT
  add-to-spec — no specific spec section referenced)
- "Cool new CLI tool for vault management" → `capture` (NOT test — unless
  we have a documented gap it fills)

Expected distribution per batch: ~70% capture, ~15% read, ~10% ignore,
~5% test/add-to-spec combined. If you are assigning test or add-to-spec to
more than 1-2 items per batch, reconsider — most "interesting tools" and
"architectural patterns" should be `capture`.

Rules:
- vault_target = "_openclaw/inbox/" ONLY when tags include
  "crumb-architecture" AND confidence is "medium" or "high"
- vault_target = null for all other items (digest only)
- Return ONLY the JSON array — no preamble, no markdown fences, no
  commentary

User:

Posts to triage:

{post_batch_json}
```

**Notes on this skeleton:**
- The `{vault_snapshot}` placeholder is replaced with the YAML contents of `vault_snapshot.yaml` at runtime.
- The `{post_batch_json}` placeholder is replaced with a JSON array of normalized post objects (10-20 per batch).
- The prompt explicitly constrains output format to prevent parsing failures.
- The scoring guidance ties directly to snapshot fields, making triage context-aware.
- This skeleton does not include few-shot examples — those should be developed during Phase 1 using real Phase 0 sample data.
