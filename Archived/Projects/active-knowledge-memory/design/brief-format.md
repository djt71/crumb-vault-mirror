---
type: design
project: active-knowledge-memory
domain: software
status: active
created: 2026-03-02
updated: 2026-03-03
tags:
  - akm
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Knowledge Brief Format

The knowledge brief is the output of `knowledge-retrieve.sh` — a compact, structured
text block that surfaces relevant KB items to the operator or consuming skill. Designed
to be scannable in 5 seconds and parseable by downstream automation.

## Entry Format

Each brief entry follows this pattern:

```
[rank] vault-path -- summary (tag-cluster)
```

**Fields:**
- `[rank]` — Position in the post-filtered results (1-indexed)
- `vault-path` — Relative path from vault root (e.g., `Sources/books/frankl-man-s-search-for-meaning-digest.md`)
- `summary` — Human-readable summary, max 120 characters (see Summary Chain below)
- `(tag-cluster)` — `kb/` tags from the note, comma-separated (e.g., `kb/philosophy, kb/history`)

## Summary Chain

Summaries are extracted using a fallback chain, stopping at the first hit:

1. **Frontmatter `summary` field** — if present, use directly (truncate to 120 chars)
2. **First non-heading paragraph** — first paragraph after the title `#` heading or
   after the first `##` heading, whichever comes first. Strip markdown formatting.
   Truncate to 120 chars with `...` suffix if needed
3. **Title + matched terms** — note title from `# heading` plus the QMD-matched
   terms in parentheses: `"Note Title (matched: term1, term2)"`

Current vault state: no notes use a `summary` frontmatter field. The chain will
typically resolve at step 2 (first paragraph). Step 3 is the safety net for notes
with no prose content (e.g., pure YAML or list-only notes).

## Budget Constraints

| Trigger | Max items | Max tokens |
|---------|-----------|------------|
| session-start | 5 | ~500 |
| skill-activation | 3 | ~300 |
| new-content | 5 | ~500 |

Token estimate: each entry ≈ 80–100 tokens (path ~20, summary ~60, overhead ~15).
5 entries ≈ 400–500 tokens. Within budget.

## Brief Structure

```
### Knowledge Brief
[1] Sources/books/frankl-man-s-search-for-meaning-digest.md -- The fundamental drive of the human spirit is not the pursuit of pleasure or power, but the "will to meaning" (kb/philosophy, kb/history)
[2] Projects/think-different/profiles/albert-einstein.md -- Albert Einstein (1879–1955) was born in Ulm, Germany, to a middle-class Jewish family (kb/history)
[3] Sources/articles/koe-multiple-interests-digest.md -- Specializing in one skill is "almost certain death" in the modern economy (kb/business)
```

When no relevant items found:

```
### Knowledge Brief
(no relevant knowledge items for current context)
```

### Header Variants by Trigger

- `session-start`: `### Knowledge Brief` (displayed in startup summary)
- `skill-activation`: `### Knowledge Brief (ambient)` (loaded silently, logged in context inventory)
- `new-content`: `### Related Knowledge` (appended to run-log entry)

### Cross-Domain Flag

When results span 2+ distinct `kb/` L2 tag clusters, append a flag line:

```
[cross-domain: kb/philosophy + kb/business — potential compound insight]
```

This signals the compound step to evaluate whether the cross-domain connection is
meaningful. Only flagged when the tag clusters are genuinely different (e.g.,
`kb/philosophy` + `kb/business`), not when they're related (e.g., `kb/history` +
`kb/biography`).

## Worked Examples from Real Vault Notes

### Example 1: Session Start — Software + Career Focus

Query context: operator working on feed-intel-framework (TASK) and customer-intelligence (ACT).

```
### Knowledge Brief
[1] Sources/books/wu-attention-merchants-digest.md -- Over the last century, a new business model has emerged: the harvesting of human attention as a raw commodity (kb/history, kb/business, kb/customer-engagement)
[2] Sources/articles/koe-multiple-interests-digest.md -- Specializing in one skill is "almost certain death" in the modern economy (kb/business)
[3] Sources/books/frankl-man-s-search-for-meaning-digest.md -- The fundamental drive of the human spirit is not the pursuit of pleasure or power, but the "will to meaning" (kb/philosophy, kb/history)
[cross-domain: kb/business + kb/philosophy — potential compound insight]
```

Token count: ~310 tokens. Within 500-token budget.

### Example 2: Skill Activation — Systems Analyst

Query context: analyzing agent-to-agent communication patterns.

```
### Knowledge Brief (ambient)
[1] Sources/books/meadows-thinking-in-systems-digest.md -- A system is an interconnected set of elements coherently organized to achieve a purpose (kb/software-dev, kb/philosophy)
[2] Sources/articles/distributed-consensus-patterns.md -- Consensus protocols trade availability for consistency; the CAP theorem bounds apply (kb/software-dev)
```

Token count: ~180 tokens. Within 300-token budget.

### Example 3: New Content — Negotiation Book Promoted

Query context: `voss-never-split-the-difference-digest.md` just promoted with tags `kb/business, kb/psychology`.

```
### Related Knowledge
[1] Sources/books/wu-attention-merchants-digest.md -- Over the last century, a new business model has emerged: the harvesting of human attention as a raw commodity (kb/history, kb/business, kb/customer-engagement)
[2] Projects/think-different/profiles/jane-goodall.md -- Dame Jane Morris Goodall (born 1934) was born in London, England (kb/history)
[3] Sources/books/frankl-man-s-search-for-meaning-digest.md -- The fundamental drive of the human spirit is not the pursuit of pleasure or power, but the "will to meaning" (kb/philosophy, kb/history)
[cross-domain: kb/business + kb/philosophy + kb/history — potential compound insight]
```

Token count: ~350 tokens. Within 500-token budget.

## Deduplication

Within a single day, the brief system tracks surfaced paths. If the same path was
surfaced by a previous trigger, it is excluded from subsequent briefs. This prevents
the same note appearing in both the startup brief and a skill-activation brief.

Tracking is date-scoped — a temp file at `/tmp/akm-surfaced-$(date +%Y%m%d).txt`
holds paths, reset at midnight. This means items surfaced in a morning session will
be suppressed in an afternoon session. The trade-off is accepted: daily dedup
prevents repetition across same-day sessions, and cross-day repetition is desirable
(the operator may have forgotten yesterday's brief).

## Feedback Logging

After each brief is generated, the surfaced paths are logged to
`_system/logs/akm-feedback.jsonl`:

```json
{"timestamp": "2026-03-02T14:30:00Z", "trigger": "session-start", "surfaced": ["Sources/books/frankl-man-s-search-for-meaning-digest.md", "Sources/articles/koe-multiple-interests-digest.md"], "cross_domain": true}
```

### Session-End Hit-Rate Measurement

At session end (step 4b of session-end-protocol.md), Crumb computes hit rate by
comparing today's surfaced paths against files actually read during the session.
A `session-end` entry is appended to the same JSONL:

```json
{"timestamp": "2026-03-03T22:00:00Z", "trigger": "session-end", "session_surfaced": 5, "session_read": 3, "hit_rate": 0.60, "paths_hit": ["Sources/books/frankl-digest.md"], "paths_miss": ["Sources/books/other.md"]}
```

This is the primary quality signal — no operator action required. Accumulating
hit-rate data enables trend detection: declining rates over weeks signal retrieval
quality degradation or system irrelevance.
