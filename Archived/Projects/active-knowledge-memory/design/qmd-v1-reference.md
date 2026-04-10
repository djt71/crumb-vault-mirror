---
type: reference-note
status: active
domain: software
project: active-knowledge-memory
created: 2026-03-02
updated: 2026-03-02
tags:
  - kb/software-dev
  - retrieval
topics:
  - moc-crumb-architecture
---

# QMD as v1 Retrieval Engine — Reference Note

## Source

Artem Zhutov (@ArtemXTech), "Grep Is Dead: How I Made Claude Code Actually Remember Things"
Published 2026-03-01. Thread + 42-min video walkthrough.

Original article and images filed in `_inbox/` (2026-03-02).

## Why This Changes the Plan

The AKM spec (2026-03-01) classified QMD as "v2 candidate, not v1 dependency" based on:
- ~2GB model footprint
- Vault-native queries (Obsidian CLI FTS5) judged sufficient at current scale

Artem's production deployment demonstrates:
1. QMD installs in minutes and runs as a CLI tool — no daemon, no server
2. 5,700+ docs indexed across 5 collections, sub-second queries
3. BM25 handles 80% of searches; semantic adds value for unstructured content
4. Session-end hook keeps index fresh automatically — zero recurring ceremony
5. The 2GB model footprint is trivial on Apple Silicon (Mac Studio runs 4-8GB Ollama models)

**Decision (operator-approved 2026-03-02):** QMD moves to v1 retrieval engine. CLI mode, no MCP server for v1.

## What This Collapses

- **AKM-004** (retrieval engine): becomes "install QMD + map vault folders to collections + build retrieval wrapper" instead of building FTS5 query logic
- **AKM-008/009** (embedding architecture, hybrid ranking): partially collapsed — QMD ships BM25 + semantic + hybrid out of the box. Design tasks become QMD configuration, not custom implementation
- **AKM-EVL** (evaluation gate): same structured test, QMD replaces FTS5 as the engine under test. The tiered decision becomes about QMD configuration (BM25-only vs hybrid) rather than "do we need a whole new engine"
- **v1 → v2 progression simplifies**: QMD gives all three search modes from day 1. The question becomes which modes to enable and when, not whether to build a new system

## Key Design Inputs from Artem's Setup

### Collection-per-folder pattern
Vault folders map 1:1 to QMD collections. Our vault structure → collections:
- `Sources/` → sources (book digests, articles, videos)
- `Projects/` → projects (specs, designs, run-logs)
- `Domains/` → domains (MOCs, overviews)
- `_system/docs/` → system (solutions, protocols, conventions)

### Three search modes
- `qmd search` — BM25, deterministic, 0.3s. Primary mode for structured notes
- `qmd vsearch` — semantic embedding, finds meaning without keyword match
- `qmd query` — hybrid (BM25 + semantic), ranked by combined relevance score

### Session export pipeline
JSONL sessions → markdown → QMD index, triggered by session-end hook.
Maps to our AKM-007 (new content arrival) trigger.

### CLI benchmarks (from Artem's "sleep" test)
- grep: 88-200 results, unranked, ~28 noise (includes `sleep()` function calls)
- BM25: 3 results in 0.3s, exact matches only, `"insomnia"` = 0 results
- Hybrid: 5 results in ~5s, ranked by meaning, 89% top score, 4/5 had no matching keywords

## MCP Server Evaluation (deferred)

QMD includes an MCP server but it's not needed for v1. CLI via Bash tool is sufficient (Artem's entire system runs this way). Evaluate MCP upgrade during AKM-012 (end-to-end validation) if CLI parsing becomes a friction point.
