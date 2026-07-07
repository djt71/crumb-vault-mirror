---
type: explanation
status: active
domain: software
created: 2026-07-07
updated: 2026-07-07
tags:
  - system/operator
topics:
  - moc-crumb-architecture
summary: Provenance and decision history of the vault's information-surfacing stack — which projects built each layer, what was abandoned and why, and the open gaps. Companion to the-vault-as-memory.md (which explains current mechanics).
---

# Information Surfacing — Provenance & Decision History

How the vault's retrieval stack came to be. `the-vault-as-memory.md` explains how surfacing works *today*; this note records **where each layer came from, what was tried and abandoned, and why** — so future tuning doesn't re-litigate settled decisions or repeat known failures.

Investigation date: 2026-07-07 (session sweep across active projects, archived projects, and git-recovered design docs).

## The five layers

| Layer | Mechanism | Originating project | Status |
|---|---|---|---|
| Retrieval engine | AKM (`knowledge-retrieve.sh` wrapping qmd) | **active-knowledge-memory** (2026-03-01 → DONE 03-02; deleted from disk, git-only) | Live |
| Delivery | `skill-preflight.sh` PreToolUse hook → `additionalContext` | attention-manager session (2026-03-08) | Live |
| Compound connections | Signal scan over `Sources/signals\|insights\|research` + skill Step-1b scans | AKM knowledge-utilization-gap investigation (2026-03-07) | Live (behavioral) |
| Structure | `#kb/` taxonomy, `topics:` → Domain MOCs, `*-summary.md` + `source_updated` staleness | Design spec §5.3/§5.6 (pre-AKM) | Live |
| Outbound projections | drive-sync → NotebookLM (`.txt`) + Perplexity Computer; Quartz site for mobile | documentation-overhaul; liberation-directive v1.1; vault-mobile-access (git-only) | Live |

## Layer notes

### AKM — Active Knowledge Memory

The primary retrieval layer. Problem statement (git-only, `Projects/active-knowledge-memory/design/`): *"accumulated knowledge doesn't participate in ongoing work unless you manually retrieve it"* — the KB was passive. Design constraints: Ceremony Budget (no recurring manual actions), fully-local retrieval, category-aware relevance, and **"noise is the primary risk."**

Trigger-role architecture (settled 2026-03-10 in `qmd-tuning-decisions.md`, explicitly "to prevent future oscillation"):

- **skill-activation** — "precision retrieval," BM25 mode, budget 3. The layer that "justifies AKM's existence for day-to-day work."
- **new-content** — cross-pollination, hybrid mode, budget 5.
- **session-start** — was the "serendipity engine" (accept variance, never optimize toward targeting). Later removed entirely: no session context to target against.
- **dispatch** — added by tess-v2 Amendment AA for orchestrator enrichment; survives in the script though its consumer was decommissioned.

Post-filter machinery in `knowledge-retrieve.sh`: category decay half-lives (fast 90d / reference 730d / slow 365d / timeless none; book digests exempt), diversity caps (max 1 per source, max 2 per tag cluster), personal-writing boost (+0.3 when ≥3 PW notes exist), per-session dedup, cross-domain flagging, feedback logging to `_system/logs/akm-feedback.jsonl`.

Empirical anchor (AKM-EVL, blinded, 12 queries × 3 modes, ~730-doc corpus): all three qmd modes scored an identical **32% cross-domain aggregate but on different queries** — complementary, not interchangeable. Hence per-trigger mode routing. Validation passed at 71% hit rate, zero noise.

### Skill-preflight hook

Canonical decision record: `_system/docs/solutions/behavioral-vs-automated-triggers.md`. The behavioral "retrieve at skill activation" obligation failed silently — zero invocations out of three opportunities in one attention-manager session, caught only because the operator tested for it. *"The root cause is salience, not discipline."* Fix: PreToolUse hook + `skill-preflight-map.yaml` (kb-eligibility, query hints, reminders, input validation) + vault-check §29/§30 commit-time nets.

### Signal scan

Born from the utilization-gap investigation, which was triggered by Mission Control Phase 0's brutal datapoint: **0% hit rate — 71 items surfaced, 0 read.** Diagnosis split the failure into a **Query Gap** (the single most relevant source never surfaced — domain-concept mapping lacked the vocabulary) and a **Consumption Gap** (the right source surfaced 3× and was never opened). The signal-note substrate itself descends from feed-intel's `Sources/signals/` intake and its "surfacing layers ordered by friction" design.

## The graveyard — abandoned & superseded

| Approach | Fate | Why |
|---|---|---|
| FTS5/BM25-only v1, embeddings deferred to v2 | Superseded pre-build (2026-03-02) | qmd ships BM25 + vectors + reranking at the same deploy cost. Run-log lesson: "re-evaluate 'heavy' assessments when production data arrives" |
| Session-start trigger | Removed | No session context to target against; serendipity role deliberately never optimized |
| Consumption/hit-rate tracking | Removed | Read-tool metric couldn't distinguish "brief consumed in context" from "full file opened" → 0% across all sessions |
| Chronic-miss suppression | Disabled (`load_chronic_misses()` → `{}`) | "Death spiral": behavioral read-tracking produced garbage data that penalized ALL KB content toward exclusion. Third confirmed behavioral-vs-automated instance |
| Cross-session (daily) dedup | Reduced to per-session | Morning surfacing blocked afternoon re-surfacing when context changed |
| Static "always-surface" pin lists | Superseded | Dynamic project-tag enrichment instead |
| Per-skill "Step 0: Knowledge Retrieval" (behavioral) | Superseded | Silent failure → PreToolUse hook |
| Tess `vault_search` 3-layer integration (Amendment AA) | Mooted | Tess/OpenClaw decommissioned (agentic-sunset); `vault-search.sh` never shipped |
| qmd MCP server; Obsidian MCP | Deferred | CLI via Bash sufficient; MCP adds dependency without capability |

**The recurring lesson** (three independent instances): behavioral instructions fail silently; only hooks and commit-time checks enforce. Surfacing improved every time measurement or delivery moved from "Claude remembers" to mechanical.

## Open gaps (as of 2026-07-07)

- **Consumption measurement unsolved.** No working metric for "was the surfaced item actually used." Re-enabling chronic-miss suppression is blocked on automating read-tracking (SessionEnd hook was the proposed path).
- **Corpus doubled since tuning.** AKM-EVL ran against ~730 docs / ~4,900 chunks; the 2026-07-07 rebuild embedded 1,701 docs / 9,012 chunks. → **Re-validated 2026-07-07**: mode rankings inverted at scale (BM25 collapsed, semantic/hybrid improved). See [[akm-evaluation-2026-07]] and the regression fixture at `_system/data/akm/bench-fixture.json`.
- **Embedding model changed.** qmd 2.0.1 → 2.5.3 (2026-07-07) swapped in embeddinggemma-300M; the March mode-evaluation results are superseded by the re-run in [[akm-evaluation-2026-07]].
- **Deferred from AKM v1:** chapter-digest indexing (gated on hit rate <60%), min-score thresholds, BM25 manual query-expansion.
- **Unbuilt:** native vault tools (`vault_read/grep/list`, Amendment AA), MOC synthesis skill, automated MOC delta refresh, graph metrics — all "build-when-needed" deferrals in the design spec §9.

## Where the deleted design docs live

`Projects/active-knowledge-memory/` and `Projects/vault-mobile-access/` were removed under the vault-optimization storage policy ("git history is the archive"). Recover via `git show <deletion-commit>~1:<path>` — e.g. the AKM problem statement, `qmd-tuning-decisions.md`, `qmd-mode-evaluation.md`, and `investigation-knowledge-utilization-gap.md`.

## Related

- [[the-vault-as-memory]] — current mechanics narrative
- `_system/docs/architecture/03-runtime-views.md` §6 — AKM surfacing sequence diagram
- `_system/docs/solutions/behavioral-vs-automated-triggers.md` — the enforcement pattern
- `_system/scripts/knowledge-retrieve.sh` — the engine itself (header comments record removals in-line)
