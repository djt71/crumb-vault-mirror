---
type: reference
status: active
domain: software
project: active-knowledge-memory
created: 2026-03-01
updated: 2026-03-01
tags:
  - kb/software-dev
  - retrieval
  - evaluation
topics:
  - moc-crumb-architecture
---

# Active Knowledge Memory — FTS5 Evaluation Note

## Context

The v1 decision to use FTS5/BM25 over embeddings was made against a corpus of ~88 notes (43 source notes + 45 profiles). The batch-book-pipeline project is about to land ~300 book digests into the knowledge base within the next week. This changes the evaluation timeline significantly.

## The Decision Still Holds — But the Evaluation Window Compresses

FTS5 is still the right v1 choice. 350 documents don't stress BM25's performance characteristics, and shipping v1 without embedding infrastructure avoids blocking Active Knowledge Memory on the book pipeline or vice versa. The interface abstraction (same input/output contract regardless of retrieval backend) means the swap to embeddings is a backend change when the time comes.

What changes is the timeline for evaluating whether FTS5 is *sufficient*. With 300 books spanning history, philosophy, biography, business, spirituality, fiction, and software — the cross-domain connection problem becomes immediately testable. This isn't "try FTS5 for a quarter and see." It's "evaluate honestly within 1-2 weeks of the books landing."

## What's Needed: A Comprehensive FTS5 Evaluation Plan

Before the book pipeline lands, AKM should have a concrete testing plan ready to execute against the real corpus. The plan should answer one question: **does FTS5 miss connections that matter?**

### Suggested evaluation dimensions

**Cross-domain concept matching (the critical test)**
Can FTS5 surface conceptual connections across domains that don't share vocabulary? This is the specific failure mode that would justify embeddings. Test cases should be designed *before* running the evaluation — not cherry-picked after the fact.

Example test cases (illustrative, not exhaustive):
- Given a task about software system resilience, does FTS5 surface notes on Stoic philosophy, antifragility, or biological adaptation?
- Given a task about fairness in content scoring, does FTS5 surface notes on Rawls' theory of justice or ethical frameworks?
- Given a task about team leadership, does FTS5 surface notes on historical figures who led through adversity?

If these connections require the exact keywords to appear in both the query and the target note, FTS5 is insufficient for the stated requirement ("connections between ideas that cross domain boundaries").

**Within-domain relevance (the baseline)**
For connections where vocabulary naturally overlaps (software architecture notes surfacing during software projects), FTS5 should perform well. Confirm this works as expected — if it doesn't, there's a deeper problem.

**Noise rate**
How many irrelevant results appear in the top N? At 350 documents, BM25 might return too many weak matches for common terms. The budget cap (3-5 items per trigger) means precision matters more than recall.

**Coverage of Danny's future writing**
Personal writing may use different vocabulary than book digests and technical docs. When personal content enters the KB, will FTS5's keyword matching find connections between Danny's writing and the book corpus? This can't be tested until personal writing exists, but the evaluation framework should anticipate it.

### Evaluation protocol

1. **Before books land:** Define 10-15 specific test queries spanning cross-domain, within-domain, and noise scenarios. Document expected relevant results for each (based on known book topics from the pipeline queue).
2. **After books land:** Run each test query against FTS5. Score: relevant results found, relevant results missed, irrelevant results returned.
3. **Decision criteria:** If cross-domain miss rate exceeds ~40% on the test set (i.e., FTS5 fails to surface obviously relevant notes for nearly half the cross-domain queries), that's the empirical signal to move to v2 embeddings. The exact threshold is a judgment call — but having a threshold at all prevents indefinite "it's probably fine" drift.

## Timing

- **Now:** Design the evaluation plan and test cases as part of PLAN or early TASK phase
- **Book pipeline lands (~1 week):** Execute evaluation against real corpus
- **1-2 weeks post-landing:** Make the FTS5-vs-embeddings decision based on data

This keeps Active Knowledge Memory shipping on the v1 path without delay, while ensuring the v2 decision is made promptly and empirically once the corpus is real.
