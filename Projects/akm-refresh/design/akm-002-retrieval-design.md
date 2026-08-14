---
project: akm-refresh
domain: software
type: design
skill_origin: null
created: 2026-08-14
updated: 2026-08-14
topics:
  - moc-crumb-architecture
tags:
  - akm
  - design
---

# AKM-002 — Retrieval Design: Transport, Modes, Floors, Empty-Brief Handling

Consumes: `akm-001-daemon-spike-memo.md` (all latency/RSS/hazard data), spec F1–F9/C1–C7/U2/U5, plus new measurements taken for this design (recall-by-shape, score semantics, U5 tests — all below). Status: **APPROVED by operator 2026-08-14** — daemon lifecycle = Option A (session-startup lazy-start).

## Decisions

### D1 — Transport: daemon primary, CLI structured fallback *(AKM-001 memo; A1, C1)*

Skill-activation retrieval calls the qmd MCP daemon (`http://localhost:8181/mcp`, streamable HTTP JSON-RPC). Wrapper flow per invocation: health-probe (`initialize` round-trip, ~ms; connection-refused in ~30ms when down) → on success, `notifications/initialized` + `tools/call query` → on failure, **CLI fallback** `qmd query 'vec: <task>' --no-rerank` (~630ms stable; see D3 for why the fallback drops the lex line). FTS5/absent-qmd degradation chain below the CLI is unchanged.

Non-negotiable lifecycle rules (AKM-001 hazards 1–3): daemon liveness is verified **only** by the health probe, never stdout/exit code (daemon start reports false success on bind failure); daemon shutdown targets the listener (`lsof -t -iTCP:8181 -sTCP:LISTEN`), never the launcher PID (orphan-child hazard); a warmup query is fired at daemon start (first query otherwise pays 4–7.6s lazy model load).

**Operator decision — daemon lifecycle (pick one):**
- **Option A (recommended): session-startup lazy-start.** `session-startup.sh` starts the daemon (if down) + fires the async warmup. No new launchd service (C3); RSS is only held on days the vault is worked. Cost: daemon lingers after last session until reboot/manual kill; first wrapper call in a race window falls back to CLI harmlessly.
- **Option B: launchd KeepAlive service** (`com.crumb.qmd-mcp`). Always warm, survives crashes, registered in `project-state.yaml` `services`. Cost: a standing service + ~3.5GB resident 24/7 + launchd quirk surface.

Either way the wrapper's probe-then-fallback logic is identical — the choice is operational posture, not correctness.

### D2 — Mode per trigger *(C7: retune modes within settled roles)*

| trigger | mode | evidence |
|---|---|---|
| skill-activation | structured `lex` + `vec`, **rerank on**, daemon | Best measured R@3 (0.408, table below); e2e ~0.8s p50 / ~1.45s p95 — passes M5 (memo) |
| new-content | structured `lex` + `vec`, rerank on, daemon, budget 5 | Cross-pollination role unchanged (C7); hybrid stays per spec AKM-002 note; no 2s SLO on this path |
| dispatch | unchanged construction, moved to daemon transport when up, CLI fallback | Amendment AA semantics preserved; fail-open retained |

Query construction (skill-activation): `lex:` line = extracted keywords + `query_hints`; `vec:` line = raw task description (natural language). Line order is immaterial (measured: identical recall either way). The splitting hack in `run_qmd_query()` is **deleted** — typed lines replace it directly (F4).

### D3 — Recall by query shape *(new measurement, daemon MCP, fixture 12 queries, one scorer)*

| shape | R@3 | R@5 |
|---|---|---|
| lex+vec, rerank | **0.408** | 0.458 |
| vec only, rerank | 0.336 | 0.483 |
| vec only, no rerank | 0.329 | 0.540 |
| lex+vec, no rerank | 0.256 | 0.339 |

(Absolute values are not comparable to `qmd bench` numbers — different scorer; relative ordering within this table is the design signal.) Three consequences: **rerank is load-bearing** (+59% R@3 over no-rerank for lex+vec) — it cannot be dropped for latency, and the budget doesn't require it; **without rerank the lex line actively hurts** (0.256 < 0.329 — RRF admits BM25 junk that rerank would have demoted), so the CLI fallback is `vec:`-only no-rerank; the fixture's single-string queries understate the structured shape (production lex lines get real keywords + hints, not a copy of the vec text) — AKM-004's fixture v2 re-baselines with production-shaped queries.

### D4 — Noise control: scope + accept-empty, floors demoted to trim *(F3, F4, A3; new score-semantics measurement)*

Measured score semantics on the daemon path: **no-rerank scores are rank-reciprocal** (exactly 1, 0.5, 0.33, 0.25… — a floor is a disguised rank cutoff, useless as a relevance gate); **rerank scores overlap completely** (gibberish query's top hit 0.88 vs relevant query's 0.91 — confirms F3 at the daemon layer). N3 (Herodotus): all five raw hits are `projects/` docs — the KB-scope filter alone empties it; with splitting deleted, nothing manufactures fragments (F4, C5 re-confirmed).

Therefore the noise stack, in order of actual work done:
1. **KB scope** — server-side `collections: ["sources","domains"]` on the daemon call (new capability; also stops the fetch budget being wasted on project docs), plus the existing client-side path filter as defense in depth.
2. **Splitting deletion** — eliminates the manufactured-fragment class outright.
3. **Accept-empty** — zero post-filter results → clean header-only brief, `empty_reason` logged, no pressure to surface anything (A3).
4. **Score-0 drop** — unconditional (BM25/CLI paths emit them; F3).
5. **Floor (U2 provisional): `minScore: 0.35`, rerank path only** — honest framing: this is a weak-tail *budget trimmer*, not a noise gate (observed rerank cliff: rank-1 ≈0.9, rank-2+ ≈0.4–0.55). **No floor on any no-rerank path** (rank-reciprocal scores). Tuned at AKM-004, confirmed in soak.

Residual accepted risk: a semantically-adjacent-but-irrelevant KB doc at high rerank score (the "Moby Dick for sandworms" class) passes every mechanical gate. This is exactly what the soak's noise-flag convention exists to catch (criterion 7: ≥3 confirmed irrelevant surfacings = fail).

### D5 — U5: empty-brief handling *(precondition — tested this session, results verbatim)*

Hooked-consumer inventory: `settings.json` registers exactly one brief consumer — `skill-preflight.sh` (PreToolUse/Skill). new-content and dispatch triggers have no hooked consumer today (R4 builds the former; dispatch has no registered caller).

| test | setup | result |
|---|---|---|
| U5-1: empty brief → skill-preflight | qmd shimmed to return `[]`, KB-eligible skill | **PASS** — no output, exit 0, skill proceeds silently; the existing `^\[` item-line strip (skill-preflight.sh:171) correctly discards header-only briefs |
| U5-2: empty-brief shape, all 3 triggers | wrapper direct, shimmed | **PASS** — all emit well-formed header + `(no relevant…)` line, exit 0 |
| U5-4: non-empty brief sanity | real qmd | **PASS** — valid hook JSON, well-formed brief + cross-domain flag |
| U5-3: reminders with empty brief | reminder-configured skill | **BLOCKED by live defect** — see below |

**Design:** empty briefs are already tolerated; keep the existing strip mechanism, no consumer changes needed. Wrapper adds `empty_reason` (`no_results` | `all_filtered` | `below_floor`) and a new `transport` field (`daemon` | `cli-fallback` | `fts5`) to feedback-log entries so the soak can attribute quality by path. (Schema fields written by AKM-003 code in the same change — not pre-committed.)

**Live defect found during U5:** no python3 on the machine has PyYAML; `skill-preflight.sh`'s `import yaml` fails inside its silent try/except, so **the entire preflight map is dead config** — reminders never inject (verified: systems-analyst, which has 2 configured, injects nothing), `inbox-processor`'s `kb_eligible: false` is ignored, `peer-review`'s `required_inputs` check never runs, and AKM-009's `query_hints` would be a silent no-op. **Fix owned by AKM-003** (it owns this file): replace the yaml import with a dependency-free parser for the map's flat subset (the file is machine-owned and shape-stable), plus a startup self-check that the map parsed non-empty. AKM-009's acceptance implicitly depends on this fix; noted there.

### D6 — Wrapper MCP client mechanics *(AKM-001 memo)*

Per-invocation stateless handshake (initialize → initialized → tools/call): 2 extra local round-trips, single-digit ms — no session caching complexity. `limit: 20` fetch (post-filter needs headroom), curl timeout 3s wired to the fallback path. Distinct-query result caching on the daemon is benign in production (identical re-queries getting cached results is correct behavior).

### D7 — Rollback isolation *(AKM-003 acceptance requirement)*

Mode-routing + query-construction changes land as a discrete block in `run_qmd_query()`/`qmd_mode_for_trigger()` with the old BM25+splitting path preserved behind an env toggle (`AKM_LEGACY_MODE=1`) for one release cycle; revert = flip toggle, no code restore. Toggle removed at AKM-010 close.

### D8 — Projected M1–M5 *(required by acceptance)*

| gate | projection | basis |
|---|---|---|
| M1 | **pass** — chosen shape R@3 0.408 ≥ vector-equivalent 0.329/0.336 (same scorer) | D3 table; `qmd bench` cannot run the chosen shape — this same-scorer comparison is the honest M1 evidence; fixture v2 (AKM-004) re-baselines |
| M2 | **pass (projected)** — July EVL: hybrid within-domain 100% vs bar 71% | F1; re-verified live at AKM-003 |
| M3 | **plausible-pass** — chosen shape has best top-3 concentration; unverified at brief level until AKM-003 post-filter run | D3 |
| M4 | **pass** — N3 empties via scope filter + splitting deletion (measured); score-0 drop unconditional | D4 |
| M5 | **pass** — ~0.8s p50 / ~1.45s p95 e2e (150ms wrapper + 642/1292ms transport); cold excluded via warmup-at-start | memo |

M6 does not fire. No design exception needed.

## Out of scope, unchanged by this design

Trigger roles (C7), KB-only scope (C5), budgets (3/5), post-filter pipeline (decay, diversity, PW boost, dedup), feedback-log location, chronic-miss suppression (stays off — R3's problem).
