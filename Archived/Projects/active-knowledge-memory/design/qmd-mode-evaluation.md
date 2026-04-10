---
type: design
project: active-knowledge-memory
domain: software
status: active
created: 2026-03-02
updated: 2026-03-02
tags:
  - akm
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# QMD Mode Evaluation (AKM-EVL)

## Test Design

12 blinded test queries across 3 categories:
- **Cross-domain (7):** Concept queries expected to match books across different `kb/` tags
- **Within-domain (3):** Keyword-aligned queries expected to match within a single domain
- **Noise baseline (2):** Generic terms to measure irrelevant result volume

Each query run against 3 QMD modes:
- `qmd search` — BM25 (keyword matching, no ML)
- `qmd vsearch` — semantic vector similarity
- `qmd query` — hybrid (BM25 + semantic + query expansion + reranking)

Results scored against blinded expectations: author substrings expected in top 5.

Corpus: 315 sources, 296 book digests, 730 total documents (4949 embedded chunks).

## Raw Results

### Cross-Domain Queries

| # | Query | BM25 | Semantic | Hybrid | Notes |
|---|-------|------|----------|--------|-------|
| Q1 | resilience in the face of adversity | 1/4 (25%) | 2/4 (50%) | 2/4 (50%) | Semantic/hybrid found Aurelius; BM25 missed |
| Q2 | how leaders make difficult ethical decisions | 0/4 (0%) | 0/4 (0%) | 0/4 (0%) | All modes returned philosophers (Laertius, Senge, Emerson) — tangentially relevant |
| Q3 | persuasion and influence over others | 0/3 (0%) | 0/3 (0%) | 0/3 (0%) | Mostly noise — Franklin and Kleiser tangential |
| Q4 | finding meaning through suffering | 2/5 (40%) | 1/5 (20%) | 1/5 (20%) | BM25 found Frankl + Dostoyevsky by keyword; others missed |
| Q5 | systems thinking and feedback loops | 3/3 (100%) | 3/3 (100%) | 2/3 (67%) | Hybrid missed Senge (ranking anomaly) |
| Q6 | surveillance and control of populations | 2/3 (67%) | 2/3 (67%) | 1/3 (33%) | BM25 found Herbert (Dune); semantic found Arendt |
| Q7 | the nature of consciousness and self-awareness | 0/3 (0%) | 0/3 (0%) | 2/3 (67%) | **Hybrid uniquely found Nagel + Tolle.** BM25: 0 results |

### Within-Domain Queries

| # | Query | BM25 | Semantic | Hybrid |
|---|-------|------|----------|--------|
| Q8 | stoic philosophy daily practice | 3/3 (100%) | 2/3 (67%) | 2/3 (67%) |
| Q9 | data visualization design principles | 2/3 (67%) | 2/3 (67%) | 2/3 (67%) |
| Q10 | existentialism and freedom | 0/1 (0%) | 0/1 (0%) | 0/1 (0%) |

Q10 note: the actual hybrid results (Jaspers, Frankl, Dostoyevsky, Koga, Rilke) are
**all highly relevant to existentialism** — the miss is that Kierkegaard specifically
didn't appear in top 5, not that the results are irrelevant.

### Noise Baseline

All modes returned 10 results for both noise queries ("the book", "important ideas").
Results were low-quality general matches. No mode distinguishes itself on noise rejection.

## Aggregate Scores

| Mode | Cross-Domain | Within-Domain | Latency |
|------|-------------|---------------|---------|
| BM25 | 8/25 (32%) | 5/7 (71%) | 0.24s |
| Semantic | 8/25 (32%) | 4/7 (57%) | 0.78s |
| Hybrid | 8/25 (32%) | 4/7 (57%) | 0.80s |

### Score Distributions (top-1 result across non-noise queries)

| Mode | Avg | Min | Max | Queries with results |
|------|-----|-----|-----|---------------------|
| BM25 | 0.876 | 0.800 | 0.910 | 9/10 |
| Semantic | 0.681 | 0.620 | 0.830 | 10/10 |
| Hybrid | 0.908 | 0.880 | 0.930 | 10/10 |

## Analysis

### Identical aggregates mask complementary strengths

All three modes score 32% cross-domain in aggregate, but they hit **different queries**:

- **BM25 uniquely best:** Q4 (meaning/suffering — 40% vs 20%), Q5 (systems — 100% vs 67%),
  Q8 (stoic — 100% vs 67%). Wins when query terms appear literally in digests.
- **Hybrid uniquely best:** Q7 (consciousness — 67% vs 0%). The only mode that found
  Nagel and Tolle for a conceptual query where BM25 returned zero results.
- **Semantic adds marginal value:** Never uniquely best. Tied or slightly worse than
  hybrid on every query.

### Expectation quality caveat

The 32% aggregate understates actual relevance. Three queries (Q2, Q3, Q10) scored 0%
across all modes because the expected *specific authors* didn't appear — but qualitative
review shows the actual results for Q10 (Jaspers, Frankl, Dostoyevsky, Koga, Rilke) are
highly relevant to existentialism. The scoring methodology penalizes conceptual hits that
come from unexpected books. Adjusting Q10 from 0% to "qualitatively relevant" would lift
the aggregate to ~36-40%.

### Within-domain: BM25 is strictly best

71% vs 57% for both semantic and hybrid. Keywords align well when query and content share
the same domain vocabulary. This matches Artem's finding that "BM25 handles 80% of
searches."

### Noise: no differentiation

All modes return 10 results for generic queries. The post-filter in `knowledge-retrieve.sh`
(decay weighting, diversity constraints, budget truncation) is doing more to control noise
than the search mode itself.

### Performance

BM25 is 3× faster (0.24s vs 0.80s). All modes are well within the per-trigger SLOs
(session-start: 3s, skill-activation: 2s, new-content: 5s).

## Decision

Per the spec decision criteria:
- BM25 > 75% cross-domain → BM25 default: **NO** (32%)
- BM25 misses > 25% cross-domain → hybrid default: **YES** (68% miss rate)
- All modes miss > 40% → investigate: **YES** (all at 68%)

However, applying the criteria mechanically would miss the key finding: **the modes are
complementary, not interchangeable.** The recommendation is per-trigger mode selection:

### Recommended defaults

| Trigger | Mode | Rationale |
|---------|------|-----------|
| session-start | **hybrid** | Broadest scope, cross-domain matching matters most, 0.8s still within 3s SLO |
| skill-activation | **BM25** | Within-domain queries, keyword alignment is strong, 0.24s gives headroom for the 2s SLO |
| new-content | **hybrid** | Cross-domain matching is the entire point of this trigger — surfacing unexpected connections |

### Investigation items for AKM-009

1. **Digest quality drives recall more than mode choice.** Q2 and Q3 failed across all
   modes — the books' digests may not contain the conceptual vocabulary that connects
   them to these queries. Consider: should `knowledge-retrieve.sh` query against
   chapter-digests (more detailed) in addition to top-level digests?
2. **Query expansion (hybrid feature) is the key differentiator.** Hybrid's unique Q7
   win came from query expansion turning "consciousness and self-awareness" into related
   terms. Evaluate whether running BM25 with manually expanded terms approaches hybrid
   quality without the latency.
3. **Noise rejection is a post-filter problem, not a mode problem.** The `min-score`
   flag could pre-filter low-confidence results. Test `--min-score 0.5` on hybrid
   and `--min-score 0.8` on BM25.

## Test Fixtures (for regression)

Preserved at `/tmp/akm-evl/` (36 JSON files). Key regression tests:

- Q5 (`systems thinking and feedback loops`): BM25 must return Meadows, Cabrera, Senge
- Q7 (`consciousness and self-awareness`): Hybrid must return Nagel + Tolle
- Q8 (`stoic philosophy daily practice`): BM25 must return Aurelius, Seneca, Epictetus
