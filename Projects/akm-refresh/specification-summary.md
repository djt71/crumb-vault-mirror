---
type: specification-summary
project: akm-refresh
domain: software
status: active
skill_origin: systems-analyst
created: 2026-07-07
updated: 2026-07-07
summary_of: specification.md
source_updated: 2026-07-07
topics:
  - moc-crumb-architecture
tags:
  - specification
  - summary
  - akm
---

# akm-refresh — Specification Summary

**Problem:** AKM's only live trigger (skill-activation) runs on BM25, which collapsed at 1,701-doc scale (within-domain 71% → 43%; semantic 71%, hybrid 100% on the new embedding model). Noise defense doesn't work — 344/347 retrievals surfaced something, and the groups-of-3 splitting hack manufactures false positives. Consumption tracking and new-content cross-pollination — the self-correction loops — are unbuilt and dormant respectively.

**Scope (from evaluation R2–R5):**
- **R2** — precision-trigger fix: mode flip off BM25 (structured `lex:`/`vec:` or vector), accept-empty floor, kill splitting hack, drop score-0, daemon-vs-CLI transport decision (AKM-001 spike → AKM-002 design → AKM-003 implement → AKM-004 re-baseline + soak definition → AKM-010 soak execution/closure)
- **R3** — consumption-tracking hook: PostToolUse on Read, positive-only evidence into `akm-feedback.jsonl` with minimal linkage model (AKM-005 design w/ approval gate → AKM-006)
- **R4** — new-content hook: PostToolUse on Write/Edit, tag-present-on-save `#kb/` sniff under Sources/, path debounce, self-trigger exclusion (AKM-007 design w/ approval gate → AKM-008); VO-037 deletes the CLAUDE.md paragraph (XD-028, overlap window accepted)
- **R5** — populate `query_hints` from fixture traces (AKM-009)
- R3/R4 contingency: if PostToolUse payloads lack usable path data, both descope cleanly by spec amendment

**Out of scope:** R6 serendipity; chronic-miss re-enable, decay retuning, chapter digests (all await R3 data); trigger-role redesign (settled 2026-03).

**Key constraints:** 2s SLO on the hook path; "noise is the primary risk"; R3/R4 are new primitives → operator approval at design gates; consumption evidence positive-only (death-spiral lesson); KB-only retrieval scope settled.

**Success gates:** R2 passes an all-of matrix (M1–M6): fixture recall@3 ≥ vector's recall@3 (recall@5 tracked for continuity) + EVL within-domain ≥ 71% + brief-level top-3 check (budget is 3 — rank-4 fixture hits don't count) + N3 (Herodotus) empty + ≤2s p95 warm end-to-end + viability rule (nothing passes → design exception to operator, no implementation). Hooks fire mechanically, <50ms p95 added latency, never block the wrapped tool. AKM-010 runs the ≥2-week soak with an operationalized noise-flag convention (fixture filters, soak decides).

**Tasks:** 10 (AKM-001…010), dependency spine 001→002→003→{004→010, 009}; R3/R4 design can parallel R2, implementations land after AKM-003.

**Risks:** fixture blind spots (→ soak), daemon as unmonitored failure point (→ degrade-to-CLI), silent-empty hiding misses (→ R3 data + empty_reason logging). CLI fallback is not assumed SLO-viable (wrapper overhead ~0.8s today — AKM-001 profiles end-to-end).

**Peer review:** round 1 (2026-07-07, 3 reviewers) — unanimous proceed-to-PLAN; A1–A9 applied same day; operator closed the cycle at one round. See `reviews/2026-07-07-specification.md`.
