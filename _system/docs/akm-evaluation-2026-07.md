---
type: reference
status: active
created: 2026-07-07
updated: 2026-07-07
domain: software
tags:
  - system-health
  - akm
summary: Evidence-based evaluation of AKM against its original design intent, including a re-run of the AKM-EVL mode benchmark on qmd 2.5.3/embeddinggemma at 1,701-doc scale. Finds mode-selection inversion, usage collapse to one trigger, and noise-control gaps. Recommendations R1-R6.
---

# AKM Evaluation — 2026-07

**Context.** Triggered by the 2026-07-07 information-surfacing investigation (see [[information-surfacing-provenance]]) and the same-day qmd 2.0.1 → 2.5.3 upgrade (new embedding model: embeddinggemma-300M; full re-embed of 9,012 chunks / 1,701 docs). Original AKM design docs recovered from git (`d482332b~1`).

**Verdict.** Infrastructure green; design intent one-third fulfilled. The precision trigger (skill-activation) runs on a retrieval mode that has collapsed at current corpus scale; the cross-pollination trigger is behaviorally wired and dormant; the serendipity trigger was deliberately removed. "Noise is the primary risk" — the design's first constraint — has no working defense, and consumption remains unmeasured.

## Current state (evidence)

- **Infrastructure:** healthy. `com.crumb.qmd-index` green (exit 0, correct PATH, absolute binary paths). Index fresh post-upgrade. Wrapper end-to-end 0.97s, within the 2s skill-activation SLO.
- **Usage:** collapsed. `akm-feedback.jsonl`: 347 retrievals lifetime (2026-03-02 → 07-06), **10 in the last 30 days, all skill-activation**. new-content: 15 lifetime, 0 recent — it is a CLAUDE.md behavioral obligation, not a hook (fourth instance of the behavioral-vs-automated anti-pattern).
- **Quality controls:** 344/347 retrievals surfaced items — the system almost never returns an empty brief. No min-score. Chronic-miss suppression disabled (death spiral, 2026-03). `query_hints` empty for every skill in `skill-preflight-map.yaml` — the Query Gap fix sits unconfigured.

## AKM-EVL re-run (2026-07-07)

Method: identical to 2026-03 — expected-author substrings in top-5, 10 scored queries + noise baseline, three modes. Additions: 2 live-work queries (L1 dashboards, L2 attention), 1 live noise query (N3, the skills-library case). Caveats: Q1–Q4, Q6–Q7, Q9 expectation sets partially reconstructed (original `/tmp/akm-evl/` fixtures lost to GC); corpus 730 → 1,701 docs; embedding model changed. Treat per-query deltas as soft, mode *rankings* as solid.

Harness + raw results: `_system/data/akm/evl-rerun-harness.py`, `evl-rerun-2026-07-07.json`.

### Author-hit rates (March 2026 → July 2026)

| Mode | Cross-domain | Within-domain | CLI latency (warm) |
|---|---|---|---|
| BM25 | 32% → **28%** | 71% → **43%** | 0.24s → 0.16s |
| Semantic | 32% → **48%** | 57% → **71%** | 0.78s → ~1.9s (cold spikes 9.3s) |
| Hybrid | 32% → **40%** | 57% → **100%** | 0.80s → **~4.8s** |

### Key findings

1. **Mode inversion.** The March tuning ("BM25 for skill-activation: within-domain 71%, 3× faster") is dead. BM25 within-domain fell to 43% (0 hits on Q1, Q7, Q10, L1); semantic and hybrid now beat it everywhere. Cause: corpus dilution (2.3×) punishes keyword matching; embeddinggemma substantially improved vector quality. **The only live trigger runs on the collapsed mode.**
2. **Hybrid latency now busts the SLO.** 4.8s per CLI call vs the 2s skill-activation SLO. But `qmd bench` (in-process) shows the search itself costs 3ms (bm25) / 61ms (vector) / 144ms (RRF hybrid) / 121ms (full rerank) — **CLI process startup + model load dominates**. The March "MCP server deferred — CLI sufficient" decision deserves revisit: `qmd mcp --http --daemon` (new in 2.5) would make semantic/hybrid hook-viable at ~100ms.
3. **Min-score is not the clean noise fix the March deferral assumed.** Distributions overlap: semantic relevant-hits avg 0.55 (min 0.37) vs noise avg 0.46 (max 0.59); hybrid rerank scores rate *noise at 0.88–0.93* — the same band as real hits (rerank confidence is relative, not absolute). BM25 scores are unusable (noise at 0.82; also returns score-0.0 results that the post-filter never drops — one-line fix).
4. **The Herodotus case (N3) decoded.** For "skills-library portability," semantic/hybrid rank the *correct* answer #1 — the skills-library spec — but that's a project doc, which AKM rightly excludes (KB-only scope; the session already has project context). With the true match filtered out, raw BM25 returns **zero** results — the correct outcome — but the wrapper's groups-of-3 keyword-splitting hack manufactured fragment matches ("portability" → *Portable* Greek Historians) and surfaced them, then flagged a false cross-domain insight. **Noise control = accept-empty + kill the splitting hack**, not thresholds alone. qmd 2.5 structured queries (`lex:`/`vec:` lines) replace the hack directly.
5. **Regression fixture now exists.** `_system/data/akm/bench-fixture.json` — 12 queries, expectations pinned to 2026-07-07 observed-good rankings. Run `qmd bench _system/data/akm/bench-fixture.json` at every qmd upgrade / model change / major corpus growth. Baseline: bm25 recall@5 0.34 · vector 0.64 · hybrid 0.60 · full 0.70.

## Recommendations

- **R1 — Measure before tuning: DONE 2026-07-07** (this document + fixture).
- **R2 — Fix the precision trigger (reshaped by data):** flip skill-activation off pure BM25 → structured query (`lex:` keywords + `vec:` task description) or vector mode; drop score-0 results; accept empty briefs when nothing clears a floor (~0.5 semantic, tuned via fixture); delete the groups-of-3 splitting. Evaluate `qmd mcp --http --daemon` for hook latency (~100ms vs 1.9–4.8s CLI). SLO-check before adopting.
- **R3 — Mechanize consumption tracking:** PostToolUse hook on Read (Sources/|Domains/ paths) reconciled into `akm-feedback.jsonl`. Positive-only evidence (open = hit; non-open ≠ miss). Prerequisite for ever re-enabling chronic-miss suppression. *New primitive — operator approval required.*
- **R4 — Wire new-content as a hook:** PostToolUse on Write/Edit detecting `#kb/`-tagged files under Sources/ → `--trigger new-content`. Revives the dormant cross-pollination role; lets VO-037 delete the behavioral signal-scan paragraph from CLAUDE.md. *New primitive — operator approval required.*
- **R5 — Populate `query_hints`** for skills with vocabulary mismatch, using fixture `--explain` traces.
- **R6 — Serendipity: leave dead** per the original decision rule ("reduce cost or drop rather than make relevant"). Cheap revival exists (fold 1–2 timeless items into the Mon/Thu Cowork digest) if wanted.

Explicitly not recommended: speculative decay-constant retuning (wait for R3 consumption data); chapter-digest indexing (decide after R3 provides hit-rate data — original gate was <60%).

## Follow-on

R2–R5 cross the workflow threshold (production script changes + two new primitives) → proposed project: **akm-refresh** (software domain, SPECIFY → PLAN → TASK → IMPLEMENT), pending operator approval.

## Related

- [[information-surfacing-provenance]] — mechanism history and decision graveyard
- `_system/data/akm/` — fixture, harness, raw results
- `_system/scripts/knowledge-retrieve.sh` — the wrapper under evaluation
- Recovered originals: `git show d482332b~1:Projects/active-knowledge-memory/design/qmd-mode-evaluation.md` (and `qmd-tuning-decisions.md`)
