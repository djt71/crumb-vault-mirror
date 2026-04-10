---
type: reference
domain: software
status: active
track: convention
created: 2026-02-24
updated: 2026-04-04
tags:
  - kb/software-dev
topics:
  - moc-crumb-operations
---

# Code Review Patterns

Recurring patterns observed across code reviews. Entries are added when a pattern
reaches 3+ occurrences (per code-review SKILL Compound Behavior section).

## Tier 1 Calibration Data (Devstral Small 2) — Retired 2026-02-25

**Retired:** Replaced by Sonnet inline review. Signal-to-noise ratio ranged from 14% to 71% (median ~58%) across 3 reviews. The subagent dispatch overhead (preflight check, temp files, response parsing, hallucination filtering) existed solely to compensate for model unreliability. Sonnet inline eliminates both the noise problem and the dispatch complexity.

| # | Project | Diff (lines) | Language | Files | Findings | Actionable | S/N | Latency | Date |
|---|---------|-------------|----------|-------|----------|------------|-----|---------|------|
| 1 | feed-intel-framework | 1,338 | TypeScript | 14 | 12 | 7 | 58% | — | 2026-02-24 |
| 2 | crumb-tess-bridge | 107 | Python | 2 | 20 | 3 | 15% | 84s | 2026-02-24 |
| 3 | x-feed-intel | 175 | TypeScript | 5 | 7 | 5 | 71% | 35s | 2026-02-24 |

**Notable model blind spots (historical):**
- TOCTOU race conditions (missed in x-feed-intel pipeline-lock.ts)
- Python stdlib behavior: `setdefault`, `dict.get()` semantics (multiple false positives in bridge review)

## Tier 1 Calibration Data (Sonnet)

| # | Project | Diff (lines) | Language | Files | Findings | Actionable | S/N | Date |
|---|---------|-------------|----------|-------|----------|------------|-----|------|
| | | | | | | | | |
