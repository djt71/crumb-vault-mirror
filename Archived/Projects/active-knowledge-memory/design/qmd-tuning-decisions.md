---
type: design
project: active-knowledge-memory
domain: software
status: active
created: 2026-03-02
updated: 2026-03-10
tags:
  - akm
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# QMD Tuning Decisions (AKM-009)

Applied based on AKM-EVL empirical results (12 queries × 3 modes).

## Per-Trigger Mode Selection

| Trigger | Mode | QMD Command | Rationale |
|---------|------|-------------|-----------|
| session-start | hybrid | `qmd query` | Cross-domain matching matters most at session start; query expansion finds conceptual connections (e.g., "consciousness" → Nagel, Tolle where BM25 returned 0) |
| skill-activation | BM25 | `qmd search` | Within-domain keywords align well (71% vs 57%); 3× faster (0.24s vs 0.80s); query terms come from project/task context which share vocabulary with KB content |
| new-content | hybrid | `qmd query` | The entire point is surfacing unexpected cross-domain connections between new content and existing KB |

### Implementation

`knowledge-retrieve.sh` function `qmd_mode_for_trigger()` maps trigger → mode.
- BM25 path: splits keywords into groups of 3 (multi-query merge pattern)
- Hybrid path: passes full keyword string to `qmd query` (internal expansion + reranking)

## Performance

| Trigger | Cold Start | Warm | SLO | Status |
|---------|-----------|------|-----|--------|
| skill-activation (BM25) | 1.19s | ~1.0s | 2s | PASS |
| session-start (hybrid) | 1.85s | 1.80s | 3s | PASS |
| new-content (hybrid) | 15.35s | 1.70s | 5s | PASS (warm) |

Cold-start: hybrid's 1.7B query expansion model loads on first call (~13s overhead).
Session-start is always the first trigger per session, so new-content never hits cold-start
in practice. First session-start call is 1.85s (within 3s SLO) because the model loads
during query execution, overlapping with signal construction.

## FTS5 Fallback

When QMD is unavailable (not installed or index broken), the script falls back to
Obsidian CLI full-text search if Obsidian is running. Fallback behavior:

1. Check `qmd status` — if fails, check `obsidian status`
2. If Obsidian available: use `obsidian search` with first 3 keywords, filter to
   Sources/ and Domains/ paths, assign flat 0.5 scores
3. If neither available: print "(QMD not available)" and exit 0

FTS5 fallback produces lower-quality results (no semantic matching, no ranking) but
ensures the brief section is populated rather than empty. The post-filter (decay,
diversity, budget) still runs on FTS5 results.

## Ranking Adjustments

No changes to post-QMD ranking from AKM-004. The existing pipeline is:

1. Decay weighting (D4 — category-aware half-lives)
2. Personal writing boost (+0.3 when ≥ 3 notes, currently inactive)
3. Diversity constraints (max 1 per source, max 2 per L2 tag cluster)
4. Budget truncation (5/3/5 items per trigger)

### EVL Investigation Items (tracked, not actioned)

1. **Chapter-digest indexing:** Q2 and Q3 failed across all modes — top-level digests
   may lack conceptual vocabulary. Chapter-digests have more detail. Consider: should
   QMD search return chapter-digests alongside top-level? Risk: inflates result count,
   same-source clustering. Defer to post-AKM-012 if hit rate < 60%.

2. **Min-score thresholds:** Not applied in v1. All modes return results even for
   noise queries. The post-filter handles noise reduction via diversity + budget
   constraints. Revisit if noise complaints arise.

3. **Manual query expansion for BM25:** Hybrid's unique Q7 win came from query
   expansion. Could approximate by adding synonym groups to BM25 queries. Deferred —
   complexity not justified when hybrid is available for the triggers that need it.

## Trigger Role Architecture (design decision, 2026-03-10)

Session-start cannot know session intent — it reads project state but has no signal
about what the operator is about to work on. This is an architectural constraint, not
a gap to fix. The two triggers serve different roles:

| Trigger | Role | Value proposition | Success metric |
|---------|------|-------------------|----------------|
| session-start | **Serendipity engine** | Broad cross-domain discovery; resurfaces KB content the operator isn't actively thinking about | Occasional surprise that changes what the operator does — measured over weeks, not per-session |
| skill-activation | **Precision retrieval** | Task-relevant content surfaced when context is available | Per-invocation relevance to the active task |

### Implications

1. **Accept session-start variance.** Any single run may miss domain-relevant content
   (validated: 1/5 runs returned zero data-viz books during a dashboard-design session).
   This is correct behavior for an exploratory trigger, not a failure. Random sampling
   across domain concept pools ensures breadth over time.

2. **Do not optimize session-start toward targeting.** Future maintenance should not
   attempt to make session-start predict session intent — that pulls against its role
   and creates oscillation between "make it broader" and "make it more relevant."
   If intent-based retrieval is needed before skill-activation fires, the correct fix
   is a new trigger type with explicit intent input, not retrofitting session-start.

3. **Evaluate session-start on its own terms.** If the operator consistently ignores the
   session-start brief, the right response is to reduce its cost (fewer items, less screen
   real estate) or drop it — not to make it more targeted. A serendipity engine that
   nobody reads is ceremony.

4. **Skill-activation carries the precision load.** Task-relevant KB content reliably
   surfaces here because task context provides strong keywords. This is the layer that
   justifies AKM's existence for day-to-day work.

### Provenance

Decision prompted by structured validation (2026-03-10): 8-test suite confirmed all 6
retrieval fixes working. The 4/5 session-start hit rate and 1/5 miss raised the question
of whether session-start's breadth is a problem or the correct design. Settled as design
decision to prevent future oscillation.
