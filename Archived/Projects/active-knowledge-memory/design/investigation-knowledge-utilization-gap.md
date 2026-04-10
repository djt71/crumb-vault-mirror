---
type: investigation
project: active-knowledge-memory
status: active
domain: software
created: 2026-03-07
updated: 2026-03-07
tags:
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Investigation: Knowledge Utilization Gap in Design/Creative Sessions

## Origin

Observed during Mission Control Phase 0 (MC-001 through MC-010, ~10 design tasks).
Raised in claude.ai review session, confirmed empirically via `akm-feedback.jsonl`.
Updated with design rationale analysis results (2026-03-07).

## Finding

**0% hit rate across all recorded sessions** — not just Phase 0. 5 session-end
entries, 71 total items surfaced, 0 ever read.

AKM *does* surface design-relevant content. During Phase 0 sessions, it surfaced:
- `ware-information-visualization-chapter-digest.md` (3 times)
- `yablonski-laws-of-ux-chapter-digest.md` (1 time)
- `tufte-visual-display-index.md` (1 time)
- `knaflic-storytelling-with-data-digest.md` (1 time)

The query mechanism finds some relevant books. The consumption mechanism doesn't
convert surfacing into reading. Items appear in the Knowledge Brief at session
start and are never referenced during task execution.

## Two Distinct Problems (confirmed by design rationale analysis)

The original diagnosis proposed two plausible explanations. The design rationale
analysis (`Projects/mission-control/design/design-rationale.md`) confirmed both
are real and distinct:

### Problem 1: Query Gap — relevant sources not surfaced

**Few's *Information Dashboard Design*** is the single most relevant source for
the mission-control project. It directly addresses dashboard layout, gauge vs.
bar encoding, bullet graphs, single-screen constraints, and data-dense display
design. It contains the only direct contradiction found in the analysis (Few
argues against circular gauges and invented the bullet graph as their replacement).

**AKM never surfaced Few's digest during Phase 0.** The domain-concept mapping
for "software" doesn't include terms like "dashboard design", "data visualization",
or "information display" — so BM25 search on domain terms misses it entirely.

This is not a chronic-miss problem (Few wasn't surfaced and suppressed). It's a
query construction problem: the search terms don't match the task domain.

**Scope of the gap:** The rationale analysis used 7 source books. Of those, AKM
surfaced 4 (Ware, Yablonski, Tufte, Knaflic) and missed 3 (Few, Cairo, Ware's
second book *Visual Thinking for Design*). Few was the most consequential miss.

### Problem 2: Consumption Gap — surfaced sources not read

**Ware's *Information Visualization* chapter digest** was surfaced 3 times during
Phase 0 sessions. It would have informed **8 of 10 design decisions** evaluated
in the rationale analysis:

| Decision | Ware relevance |
|----------|---------------|
| Status palette (4 colors) | Preattentive color channel limits — directly addressed |
| SVG arc gauges | Spatial encoding effectiveness — directly addressed |
| Urgency-colored borders | Preattentive border/position features — directly addressed |
| KPI strip scannability | Visual search and pop-out effects — directly addressed |
| Timeline color-coded dots | Integral vs. separable dimensions — directly addressed |
| Cards-within-panel | Gestalt grouping (proximity, common region) — directly addressed |
| Four-state visual patterns | Discriminability thresholds — directly addressed |
| Dark background | Polarity sensitivity — addressed (neutral finding) |

Despite being surfaced 3 times and being relevant to 8 decisions, it was never
opened. The knowledge was delivered to the session; the session never consumed it.

## Impact Assessment — Revised Upward

**Medium.** The original assessment said "low-medium" because design quality wasn't
degraded. The rationale analysis confirms quality was acceptable but identifies
concrete value left on the table:

- **Gauge contradiction caught post-hoc, not during design.** Few's bullet graph
  recommendation would have informed MC-002 (aesthetic direction) and the gauge
  budget decision (MC-006). The design mitigates the concern (budget cap + redundant
  KPI encoding) but the mitigation was incidental, not principled.
- **5 discoveries for Phase 1** that would have been available during Phase 0 if
  sources had been consumed: bullet graph widget type, integral/separable dimension
  validation, Shneiderman's mantra mapping, single-screen constraint, simultaneous
  contrast risk on stale-state gray.

## Diagnosis (updated)

The two problems require different interventions:

| Problem | Root Cause | Fix Category |
|---------|-----------|--------------|
| Query gap (Few not surfaced) | Domain-concept mapping for "software" lacks design/visualization terms | Query enrichment |
| Consumption gap (Ware surfaced but unread) | Knowledge Brief is temporally disconnected from task execution | Workflow integration |

### On overlay sufficiency

The overlays (Design Advisor, DataViz, Web Design Preference) carried the design
work successfully — 7/10 decisions are well-supported. But the overlays don't
encode everything. Few's bullet graph recommendation and the gauge contradiction
are **not** in any overlay. The overlays distill general principles; they don't
contain source-specific recommendations for specific widget types.

Conclusion: overlays are necessary but not sufficient. Source material adds value
when the task involves specific design choices (gauge vs. bar, encoding selection)
rather than general aesthetics.

## Recommended Actions

### Near-term (low ceremony) — IMPLEMENTED 2026-03-07

1. **Project-tag concept enrichment in session-start queries.**
   `knowledge-retrieve.sh` now reads `tags:` from each active project's
   `project-state.yaml` and injects tag values directly as QMD search terms.
   No static mapping — hybrid mode's query expansion handles semantic neighbors.
   Added `tags: [dashboard, dataviz]` to mission-control's project-state.yaml.
   Addresses: query gap.

2. ~~**Manual "always surface" list for Few's digest.**~~ Superseded by #1 —
   dynamic tag enrichment makes static pinning unnecessary. "dashboard" as a
   search term matches Few's digest via QMD without manual curation.

### Medium-term — IMPLEMENTED 2026-03-07

3. **Task-context AKM trigger at IMPLEMENT task pickup.**
   Added system behavior in CLAUDE.md: when starting work on an IMPLEMENT task,
   run `knowledge-retrieve.sh --trigger skill-activation --project <project>
   --task "<task title>"`. Uses existing BM25 mode (fast, keyword-focused, 3-item
   budget). Task-specific terms like "gauge", "timeline", "color palette" become
   the query — closing the temporal gap between session-start surfacing and
   actual task execution. Addresses: consumption gap.

4. **Overlay source surfacing at overlay load time.**
   Added instruction to overlay-loading steps in 4 skills (systems-analyst,
   action-architect, learning-plan, writing-coach): after loading an overlay and
   its companion doc, scan for `## Vault Source Material`, extract `[[wikilink]]`
   entries, present to operator as ambient context. No QMD query needed — overlays
   already curate their source references. Operator decides whether to read any.
   Addresses: both gaps (surfaces the right sources at the right time).

### Deferred

5. **Skill-telemetry validation.** When mission-control M9 produces
   `overlays_loaded` and `lens_questions_answered` data, validate whether overlays
   are actively used or just loaded. If loaded-but-ignored, the consumption
   problem extends beyond source material to overlays too.

## Related

- `_system/logs/akm-feedback.jsonl` — raw surfacing/consumption data
- `design/qmd-tuning-decisions.md` — 2026-03-06 chronic-miss + diversification tuning
- `Projects/mission-control/design/design-rationale.md` — full cross-reference analysis
- `Projects/mission-control/design/action-plan.md` M9 — skill/overlay telemetry spec
