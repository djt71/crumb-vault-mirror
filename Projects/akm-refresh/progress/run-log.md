---
type: run-log
project: akm-refresh
domain: software
status: active
created: 2026-07-07
updated: 2026-07-07
topics:
  - moc-crumb-architecture
tags:
  - run-log
---

# akm-refresh — Run Log

## 2026-07-07 — Project creation

**Trigger:** Same-day chain: qmd 2.0.1 → 2.5.3 upgrade (new embedding model, full re-embed) → operator-requested investigation of information surfacing → provenance sweep (AKM design docs recovered from git `d482332b~1`) → AKM evaluation with AKM-EVL re-run. The re-run found the March 2026 mode tuning inverted at current corpus scale. Operator approved project creation ("create akm-refresh and commit").

**Evidence base (R1 — complete before project creation):**
- `_system/docs/akm-evaluation-2026-07.md` — evaluation, findings, recommendations R1–R6
- `_system/docs/operator/explanation/information-surfacing-provenance.md` — mechanism history, decision graveyard
- `_system/data/akm/bench-fixture.json` — 12-query regression fixture, baseline 2026-07-07 (bm25 recall@5 0.34 · vector 0.64 · hybrid 0.60 · full 0.70)
- `_system/data/akm/evl-rerun-2026-07-07.json` + `evl-rerun-harness.py` — raw results + method

**Headline findings driving scope:**
1. BM25 (the live skill-activation mode) collapsed at 1,701-doc scale: within-domain 71% → 43%. Semantic/hybrid improved substantially on embeddinggemma (hybrid within-domain 100%).
2. Hybrid CLI latency 4.8s busts the 2s hook SLO, but in-process search is 3–144ms — process startup dominates; `qmd mcp --http --daemon` (new in 2.5) is the latency lever to evaluate.
3. Min-score alone cannot separate noise (distributions overlap; hybrid reranker scores noise 0.88–0.93). Noise control = accept-empty + structured queries replacing the groups-of-3 splitting hack (which manufactured the Herodotus false positive) + score-0 drop.
4. new-content trigger is behavioral and dormant (15 fires lifetime, 0 recent) — fourth behavioral-vs-automated instance.
5. Consumption measurement still unsolved; blocks chronic-miss suppression re-enable. Hook-based read-tracking is now the proposed mechanism (positive-only evidence semantics).

**Scope (from evaluation recommendations):**
- R2 — precision-trigger fix: mode flip, accept-empty floor, kill splitting hack, drop score-0, daemon latency evaluation
- R3 — consumption-tracking hook (new primitive — operator approval at design)
- R4 — new-content hook (new primitive — operator approval at design; coordinate with VO-037 CLAUDE.md slim-down)
- R5 — populate query_hints in skill-preflight-map.yaml
- Out of scope: R6 serendipity revival (original decision rule: reduce cost or drop); decay-constant retuning (blocked on R3 data); chapter-digest indexing (blocked on R3 data)

**Operator decisions at creation:**
- Project name/domain confirmed: akm-refresh / software
- Toolchain upgrades executed same-day (items 1–5 + Ollama upgrade); node major held
- Vault-only project — external repo gate skipped

**Context inventory (creation session):** knowledge-retrieve.sh (full read), skill-preflight.sh (full read), skill-preflight-map.yaml, akm-feedback.jsonl (stats), recovered qmd-mode-evaluation.md + qmd-tuning-decisions.md (git), qmd 2.5 bench source (types + scoring), live retrieval test + 15-query re-run.

**Next:** SPECIFY — systems-analyst specification. Key design questions: (a) which mode/structured-query shape for skill-activation within 2s SLO — CLI vs daemon; (b) accept-empty floor semantics per mode; (c) R3 hook event shape + feedback-log schema extension (positive-only); (d) R4 detection mechanics (Write/Edit PostToolUse, `#kb/` tag sniff) + VO-037 handoff.
