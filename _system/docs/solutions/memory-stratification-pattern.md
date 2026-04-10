---
type: solution
domain: software
status: active
track: pattern
created: 2026-02-25
updated: 2026-04-04
skill_origin: compound
confidence: high
linkage: discovery-only
durability: durable
valid_as_of: 2026-02-25
validated: 2026-03-26
tags:
  - kb/software-dev
  - agent-memory
  - architecture
topics:
  - moc-crumb-operations
---

# Memory Stratification Pattern

Agent memory stratifies by scope — not a replacement shift from markdown to databases, but a layering pattern. The right persistence layer depends on what you're storing and at what scale.

## Pattern

| Scope | Right Tool | Why |
|-------|-----------|-----|
| Knowledge & design (personal/bounded) | Markdown + git | Transparent, portable, zero-cost, human-editable, agent-readable |
| Operational state (local production) | SQLite (+ sqlite-vec) | ACID, queryable, single-file, vector-capable |
| Enterprise / multi-tenant | Cloud vector + graph DBs | Scale, access control, temporal reasoning |

The industry discourse frames this as "FROM markdown TO vector" — the actual evidence shows stratification, not replacement. File-system agents with basic operations achieved 74% on LoCoMo benchmarks, outperforming specialized memory tools.

## Crumb Implementation

Already following this pattern:

- **Knowledge layer (markdown):** Vault files, knowledge notes, specs, designs, run-logs — all markdown + git
- **Operational layer (SQLite):** x-feed-intel chose SQLite over JSON/markdown for pipeline state after peer reviewer consensus. Data model (canonical_id lookups, cost aggregation, feedback queries) maps naturally to relational tables
- **Retrieval layer (deferred):** qmd (BM25 + vector embedding + neural reranker) identified in spec §9 as candidate. Adoption deferred pending empirical friction — pure keyword/tag search is still sufficient at current vault scale

## Decision Point

The stratification boundary moves when empirical friction exceeds the cost of the next layer. For Crumb: when vault scale or query complexity makes keyword/tag search insufficient, sqlite-vec or qmd is the natural next step — not a migration away from markdown.

## Adjacent: Temporal Knowledge

Zep/Graphiti's bi-temporal model (event time vs. ingestion time, `valid_from`/`valid_until`) addresses a real problem: knowing *when* something was true. Crumb's `updated` frontmatter field provides basic temporal tracking. Worth revisiting if knowledge staleness becomes systematic.

## Evidence

- @1337hero post (2026-02-21): community practitioner discussion on memory shift
- x-feed-intel §7.2: SQLite adoption decision (5/5 peer reviewers concurred)
- vault-mirror: system-artifact boundary (markdown mirrored, operational state stays local)
- LoCoMo benchmark: file-system agents 74% vs specialized memory tools
