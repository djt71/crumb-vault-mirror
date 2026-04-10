---
type: research-note
domain: software
status: active
created: 2026-02-21
updated: 2026-02-21
project: crumb-tess-bridge
task: CTB-010
---

# CTB-010 — Bridge Token Cost Model

## Data Sources

1. **CTB-001 baseline** (2026-02-19): trivial PONG = $0.014, 26,827 cache-read tokens (CLAUDE.md), 4–5s baseline
2. **Partial Sonnet empirical run** (2026-02-21): 5 operations via `measure-token-cost.sh`, token counts captured but cost field unparseable from JSON output. Raw data in `ctb-010-token-cost-sonnet.json`.
3. **Anthropic pricing** (2026-02-21): Sonnet 4 and Haiku 4.5 published rates

## Pricing (per million tokens)

| Model | Input | Output | Cache Read | Cache Write (5min) |
|-------|-------|--------|------------|-------------------|
| Sonnet 4 | $3.00 | $15.00 | $0.30 | $3.75 |
| Haiku 4.5 | $1.00 | $5.00 | $0.10 | $1.25 |

## Per-Operation Cost (Sonnet 4)

Computed from empirical token counts in `ctb-010-token-cost-sonnet.json`:

| Operation | Cache Read | Cache Write | Output | Total | Duration |
|-----------|-----------|-------------|--------|-------|----------|
| query-status | 25,000 | 401 | 229 | **$0.012** | 5.2s |
| query-vault (small) | 16,914 | 8,459 | 349 | **$0.042** | 7.1s |
| query-vault (medium) | 16,918 | 9,228 | 880 | **$0.053** | 9.4s |
| list-projects | 29,703 | 10,331 | 895 | **$0.061** | 14.5s |
| approve-gate (dry run) | 16,944 | 8,499 | 287 | **$0.041** | 6.5s |

**Cost breakdown (query-status, representative):**
- Cache read: 25,000 × $0.30/M = $0.0075
- Cache write: 401 × $3.75/M = $0.0015
- Output: 229 × $15/M = $0.0034
- Input: 4 × $3/M = ~$0.00
- **Total: $0.012**

**Cost breakdown (list-projects, worst case):**
- Cache read: 29,703 × $0.30/M = $0.0089
- Cache write: 10,331 × $3.75/M = $0.0387
- Output: 895 × $15/M = $0.0134
- Input: 5 × $3/M = ~$0.00
- **Total: $0.061**

**Notes:**
- Cache write tokens dominate for tool-using operations (file reads create new prompt context)
- query-status is cheapest — no file reads, just status reporting
- list-projects is most expensive — Glob + multiple Read calls = 8 turns, more cache writes
- approve-gate dry run approximates real cost (reads project-state.yaml)
- reject-gate expected to be similar to approve-gate (~$0.04)

## Per-Operation Cost (Haiku 4.5 projection)

Applying Haiku pricing to same token counts (assumes similar token usage — conservative, Haiku may use fewer output tokens):

| Operation | Sonnet 4 | Haiku 4.5 | Savings |
|-----------|----------|-----------|---------|
| query-status | $0.012 | $0.004 | 67% |
| query-vault (small) | $0.042 | $0.014 | 67% |
| query-vault (medium) | $0.053 | $0.018 | 66% |
| list-projects | $0.061 | $0.020 | 67% |
| approve-gate | $0.041 | $0.014 | 66% |

## Weighted Average Cost

Assumed Phase 1 usage mix (daily operations):
- 40% read-only (query-status, query-vault, list-projects): weighted avg ~$0.039
- 30% approve-gate: $0.041
- 30% reject-gate: ~$0.041 (estimated = approve-gate)

**Weighted average per request (Sonnet 4): ~$0.040**
**Weighted average per request (Haiku 4.5): ~$0.014**

## Monthly Cost Projections

### Sonnet 4

| Requests/day | Monthly cost | Annualized |
|-------------|-------------|------------|
| 5 | **$6.00** | $73 |
| 20 | **$24.00** | $292 |
| 50 | **$60.00** | $730 |

### Haiku 4.5

| Requests/day | Monthly cost | Annualized |
|-------------|-------------|------------|
| 5 | **$2.10** | $26 |
| 20 | **$8.40** | $102 |
| 50 | **$21.00** | $256 |

## Go / No-Go Assessment

### Decision: FULL GO

**Rationale:**
- At 20 req/day (realistic Phase 1 daily use), Sonnet 4 costs $24/month — well within personal project budget
- Haiku 4.5 at $8.40/month is available as a fallback if cost becomes a concern
- The dominant cost driver is cache write (file reads), not CLAUDE.md loading — this means cost scales with operation complexity, not with session overhead
- Phase 2 dispatch (long-running multi-stage tasks) will cost more per dispatch but will be far fewer requests/day (2–5 typical)

**Go/no-go threshold:** $50/month. Both models at 20 req/day are well below this.

**Cost optimization levers (if needed):**
1. Switch to Haiku 4.5 for read-only operations (67% savings, minimal quality impact)
2. Batch API for non-interactive operations (50% discount)
3. Cache warm-up — sequential requests within 5-minute window share cache writes

## Empirical Validation Status

The measurement script (`src/scripts/measure-token-cost.sh`) is ready to run from a plain Terminal session. The Sonnet run captured token counts but the cost field in `--output-format json` returned 0 for all operations (parsing issue, not a zero-cost session). Token counts are reliable — costs computed above use those counts × published pricing.

Full empirical validation (with correct cost parsing) is a nice-to-have. The analytical model from measured token counts + published pricing is sufficient for the go/no-go decision.
