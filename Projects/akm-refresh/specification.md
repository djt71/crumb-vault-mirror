---
type: specification
project: akm-refresh
domain: software
status: active
skill_origin: systems-analyst
created: 2026-07-07
updated: 2026-07-07
topics:
  - moc-crumb-architecture
tags:
  - specification
  - akm
  - kb/software-dev
---

# akm-refresh — Specification

## Problem Statement

AKM's only live trigger (skill-activation) runs on a retrieval mode that collapsed at current corpus scale: BM25 within-domain hit rate fell 71% → 43% while semantic/hybrid improved to 71–100% on the new embedding model. Noise defense — the original design's first constraint — does not work: 344 of 347 retrievals surfaced something, and the keyword-splitting hack manufactures false positives (the Herodotus case). The two feedback loops that would let the system self-correct — consumption tracking and new-content cross-pollination — are respectively unbuilt and dormant.

## Evidence Base

All quantitative claims below derive from `_system/docs/akm-evaluation-2026-07.md` (R1, complete 2026-07-07) and the AKM-EVL re-run raw data at `_system/data/akm/evl-rerun-2026-07-07.json`. Mechanism history and settled decisions: `_system/docs/operator/explanation/information-surfacing-provenance.md`.

All metrics were measured 2026-07-07 — the day this spec was authored — on qmd 2.5.3/embeddinggemma at the 1,701-doc corpus; script line references are current as of the same date. *Revised same day after peer review round 1 (action items A1–A9; `reviews/2026-07-07-specification.md`).*

### Workstreams

- **R1** — measure before tuning: DONE (the evaluation itself)
- **R2** — precision-trigger fix: mode, noise controls, transport (AKM-001…004, AKM-010)
- **R3** — consumption-tracking hook, new primitive (AKM-005/006)
- **R4** — new-content hook, new primitive (AKM-007/008)
- **R5** — query_hints population (AKM-009)
- **R6** — serendipity: out of scope, stays dead

## Facts vs Assumptions

### Facts

- **F1 — Mode inversion.** Within-domain author-hit rates at 1,701 docs on qmd 2.5.3/embeddinggemma: BM25 43% (zero hits on Q1, Q7, Q10, L1), semantic 71%, hybrid 100%. Cross-domain: BM25 28%, semantic 48%, hybrid 40%. The live trigger runs on the collapsed mode.
- **F2 — Latency.** CLI warm: BM25 0.16s, semantic ~1.9s (cold spikes 9.3s), hybrid ~4.8s vs the 2s skill-activation SLO. In-process (`qmd bench`): 3ms / 61ms / 144ms / 121ms — process startup + model load dominates. qmd 2.5 ships `qmd mcp --http --daemon`.
- **F3 — Scores alone cannot gate noise.** Semantic: relevant avg 0.55 (min 0.37) vs noise avg 0.46 (max 0.59) — overlapping. Hybrid rerank scores noise at 0.88–0.93 (relative, not absolute confidence). BM25 emits score-0.0 results the post-filter never drops.
- **F4 — The splitting hack manufactures noise.** For N3 ("skills-library portability"), the true best answer is a project doc that KB-only scope rightly excludes — the session already holds project context, so the filter behaved as designed (this is why the Herodotus case *confirms* C5 rather than contradicting it). With the true match filtered, raw BM25 correctly returns zero results; the wrapper's groups-of-3 keyword splitting in `run_qmd_query()` (`knowledge-retrieve.sh:322`) fabricated fragment matches and a false cross-domain insight. qmd 2.5 structured queries (`lex:` / `vec:` lines) replace the hack directly.
- **F5 — Usage collapsed to one trigger.** 347 retrievals lifetime; 10 in the last 30 days, all skill-activation. new-content: 15 lifetime, 0 recent — it is a CLAUDE.md behavioral obligation, the fourth confirmed behavioral-vs-automated instance.
- **F6 — Quality controls unconfigured.** `query_hints: []` for every skill in `_system/docs/skill-preflight-map.yaml`; no min-score; chronic-miss suppression disabled since 2026-03 (death spiral from behavioral read-tracking).
- **F7 — Regression fixture exists.** `_system/data/akm/bench-fixture.json`, 12 queries, baseline 2026-07-07: recall@5 bm25 0.34 · vector 0.64 · hybrid 0.60 · full 0.70. Terminology: the fixture's *vector* mode is the EVL tables' *semantic* mode (the same qmd vector search); *full* is qmd bench's hybrid-plus-rerank mode. The recall@5 baseline predates the budget observation in F8 — skill-activation surfaces at most 3 items, so a rank-4/5 fixture hit never reaches the brief; acceptance therefore gates on recall@3 and a brief-level check (see the R2 acceptance matrix), with recall@5 tracked for continuity.
- **F8 — Wrapper mechanics.** Mode routing hard-coded in `qmd_mode_for_trigger()` (`knowledge-retrieve.sh:303`): skill-activation → bm25, new-content → hybrid. Budgets: 3 (skill-activation) / 5 (new-content). Post-filter: category decay, diversity caps, PW boost, per-session dedup, cross-domain flagging, feedback logging with `empty_reason` support. Wrapper end-to-end on the BM25 path today: 0.97s.
- **F9 — Prior art constrains design.** Hooks, not behavioral instructions, for skill-time and post-execution obligations (`behavioral-vs-automated-triggers.md`, enforcement mechanism map). Benchmarks filter, live soak decides (`live-soak-beats-benchmark.md`).

### Assumptions (each marked for validation)

- **A1** — Daemon transport brings semantic/hybrid end-to-end latency to hook-viable (~100–300ms), inferred from in-process costs. The CLI fallback is *not* assumed viable: F8 implies ~0.8s of wrapper overhead on top of the qmd call today (0.97s end-to-end vs 0.16s call), so CLI semantic (~1.9s call, warm) plausibly exceeds the SLO end-to-end. Deleting the splitting hack removes part of that overhead, but the post-fix figure is unmeasured. *Validate: AKM-001 profiles end-to-end, not qmd-call time alone.*
- **A2** — A structured query (`lex:` keywords + `vec:` task description) matches or beats pure vector quality for skill-activation. Hybrid won within-domain (100%) but trails vector on the fixture's cross-domain aggregate (0.60 vs 0.64). *Validate: AKM-001/002 fixture runs.*
- **A3** — Accept-empty floor + score-0 drop + splitting removal is sufficient noise control despite overlapping score distributions — the floor doesn't need to separate perfectly because empty-is-acceptable removes the pressure to surface something. *Validate: fixture noise queries (N1–N3) in AKM-003.*
- **A4** — Claude Code PostToolUse hooks on Read and Write/Edit expose the file path reliably in the hook payload. *Validate: hook API check before AKM-005/007 design. Contingency: if payloads lack usable path data, R3/R4 descope cleanly by spec amendment (success criteria 4–5 removed or re-scoped) — no workaround hacks on the hook path.*
- **A5** — Positive-only consumption semantics (open = hit; non-open ≠ miss) avoid the 2026-03 death-spiral failure mode that garbage read-tracking caused. *Validate: R3 design review against the graveyard entry.*
- **A6** — A qmd daemon, if adopted, is a manageable operational surface (launchd service + resident model memory). *Validate: AKM-001 measures RSS and failure behavior.*

### Unknowns

- **U1** — Daemon memory footprint, lifecycle, crash/restart behavior, embeddinggemma warmup handling.
- **U2** — Concrete floor values per mode (tuned via fixture, then confirmed in soak).
- **U3** — PostToolUse payload shape for Read vs Write/Edit (available fields for path, tool name, session).
- **U4** — Which skills actually exhibit vocabulary mismatch (fixture `--explain` traces will show).
- **U5** — Whether downstream consumers of the brief (skill-preflight injection, skill procedures) tolerate empty briefs gracefully today.

## System Map

### Components

| Component | Role | Touched by |
|---|---|---|
| `_system/scripts/knowledge-retrieve.sh` (918 lines) | Retrieval wrapper: query construction, mode routing, splitting hack, post-filter, feedback logging | R2 |
| `_system/scripts/skill-preflight.sh` (251 lines) + `_system/docs/skill-preflight-map.yaml` | PreToolUse delivery layer; `query_hints` live here | R2 (empty-brief handling), R5 |
| qmd 2.5.3 + embeddinggemma-300M; `com.crumb.qmd-index` launchd | Engine + index freshness; new `mcp --http --daemon` capability | R2 (transport decision) |
| `_system/logs/akm-feedback.jsonl` | Telemetry; 347 events | R2 (empty-brief events), R3 (schema extension) |
| `_system/data/akm/bench-fixture.json` | Regression gate, baseline 2026-07-07 | R2 (acceptance), R5 (traces) |
| `.claude/settings.json` hooks config | Hook registration | R3, R4 |
| CLAUDE.md signal-scan paragraph | Behavioral obligation R4 supersedes | R4 → VO-037 (deletion owned there) |

### Dependencies

- **Inbound:** qmd daemon feature (external tool, v2.5+); Claude Code hook API (PostToolUse payload shape — U3).
- **Outbound:** vault-optimization VO-037 consumes R4's hook to delete the CLAUDE.md signal-scan paragraph (tracked as XD-028 in `cross-project-deps.md`).
- **External repo:** none — vault-only project; all deliverables are vault scripts, config, and hooks (repo gate skipped per CLAUDE.md §3b, recorded at creation).

### Constraints

- **C1** — 2s end-to-end SLO for the skill-activation hook path.
- **C2** — "Noise is the primary risk" — the original design's first constraint still governs; a fix that raises recall while adding noise fails.
- **C3** — Ceremony Budget: no recurring manual actions; new primitives justified against maintenance gravity.
- **C4** — R3 and R4 are new primitives → operator approval required at their design gates (Primitive Creation Protocol).
- **C5** — KB-only retrieval scope (project docs excluded) is settled and correct — the Herodotus case confirmed it. Do not relitigate.
- **C6** — Consumption evidence must be positive-only; negative inference is what caused the chronic-miss death spiral.
- **C7** — Trigger-role architecture (precision / cross-pollination) is settled 2026-03-10 "to prevent future oscillation" — this project retunes modes within roles, it does not redesign roles.

### Levers (highest impact first)

1. **Mode flip** — quality: within-domain 43% → 71–100%.
2. **Accept-empty + kill splitting + score-0 drop** — noise: eliminates the manufactured-false-positive class outright.
3. **Daemon transport** — latency: unlocks semantic/hybrid inside the SLO.
4. **Consumption hook (R3)** — measurement: prerequisite for chronic-miss re-enable, decay retuning, chapter-digest decisions.
5. **query_hints (R5)** — vocabulary: closes the Query Gap half of the utilization-gap diagnosis.

### Second-Order Effects

- Empty briefs become normal output — downstream consumers must treat "no brief" as a valid, quiet outcome (U5 check).
- A daemon adds a persistent service: launchd plist, memory residency, restart-on-crash — register in `project-state.yaml` `services` if adopted.
- R3 data enables three deferred decisions (chronic-miss re-enable, decay constants, chapter digests) — **explicitly not acted on in this project**; R3 only builds the instrument.
- R4 unblocks VO-037's CLAUDE.md slim-down (ceremony reduction compounds).
- The fixture becomes a standing upgrade gate: every future qmd/model/corpus change gets a mechanical regression check.

## Domain Classification & Workflow Depth

**software / system** — full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT). Rationale: production changes to the live retrieval path, two new primitives requiring approval gates, and measurable regression/SLO acceptance criteria justify the full workflow. Vault-only (no external repo).

## Success Criteria

### 1–3. R2 acceptance matrix — ALL rows must pass; no row compensates for another

| # | Gate | Pass condition |
|---|---|---|
| M1 | Engine recall | Fixture recall@3 for the chosen mode ≥ vector's recall@3 (recall@3 baselines measured in AKM-001; recall@5 ≥ 0.64 tracked for continuity with the 2026-07-07 baseline) |
| M2 | Within-domain | EVL within-domain author-hit ≥ 71% (semantic's current rate) for the chosen mode |
| M3 | Brief-level | On EVL within-domain queries, the expected doc appears among the ≤3 items actually surfaced post-filter — a rank-4 fixture hit is a miss here (budget check, F7/F8) |
| M4 | Noise | N3 (Herodotus) produces an empty brief; noise queries surface nothing above floor; score-0 results never surface |
| M5 | Latency | Skill-activation end-to-end ≤ 2s p95 warm, measured wrapper-entry to brief-emit; cold starts excluded from p95 and handled separately (daemon warmup, or documented cold-path behavior) |
| M6 | Viability rule | If no transport/mode combination passes M1–M5 together, R2 halts at a design exception for operator decision — AKM-003 does not proceed |

### 4–7. Remaining criteria

4. **Mechanized cross-pollination:** creating a `#kb/`-tagged note under `Sources/` fires new-content retrieval via hook. "Zero behavioral steps" holds fully only after VO-037 deletes the CLAUDE.md signal-scan paragraph (XD-028); during the overlap window both mechanisms are live and double-surfacing is possible — accepted, documented in XD-028. Subject to the A4 contingency.
5. **Consumption measured:** real Read activity on KB paths produces positive-only events in `akm-feedback.jsonl`, linked to prior surfacing via the minimal linkage model (AKM-005). Subject to the A4 contingency.
6. **Vocabulary:** `query_hints` populated for every skill showing mismatch in traces; the March known-miss class resolves (skill subject diverging from project domain — e.g., attention-manager sessions retrieving on project vocabulary instead of attention/focus/priority terms).
7. **Soak:** ≥2 weeks live observation post-R2 (AKM-010) with no confirmed noise regressions. Operationalized: a noise flag is a run-log entry naming the surfaced item and why it was noise; soak **fails** on any recurrence of the manufactured-fragment class (splitting-type false positive) or ≥3 confirmed irrelevant surfacings; otherwise it **passes** at window close with a run-log verdict. Fixture is the filter, soak is the verdict (F9).

## Task Decomposition

Initial cut — action-architect refines at PLAN/TASK. IDs `AKM-0NN`.

| ID | Task | Tags | Risk | Depends on |
|---|---|---|---|---|
| AKM-001 | Daemon latency spike | #research | low | — |
| AKM-002 | Retrieval design: transport, mode, query shape, floors | #decision | medium | AKM-001 |
| AKM-003 | Implement wrapper changes | #code | medium | AKM-002 |
| AKM-004 | Fixture re-baseline + soak definition | #code | low | AKM-003 |
| AKM-005 | R3 consumption-hook design (new primitive — approval gate) | #decision | medium | — (A4/U3 check first) |
| AKM-006 | Implement consumption hook | #code | medium | AKM-005, AKM-003 |
| AKM-007 | R4 new-content-hook design (new primitive — approval gate) | #decision | medium | — (A4/U3 check first) |
| AKM-008 | Implement new-content hook | #code | medium | AKM-007, AKM-003 |
| AKM-009 | Populate query_hints from traces | #research #code | low | AKM-003 |
| AKM-010 | Execute and close the soak | #research | low | AKM-004 |

### AKM-001 — Daemon latency spike (#research, low)

Evaluate `qmd mcp --http --daemon` against CLI. First: confirm the daemon capability and exact flags against the installed qmd 2.5.3 (`--help` output captured in the memo). Measure **end-to-end wrapper latency** — wrapper-entry to brief-emit, including post-filter overhead with the splitting hack disabled, not qmd-call time alone (A1: the CLI fallback's viability turns on the post-fix overhead figure) — p50/p95, warm and cold, for semantic, hybrid, and structured queries on both transports; daemon RSS; warmup behavior; failure mode when the daemon is down. Record fixture recall@3 per mode (M1 baselines). Output: decision memo in `design/`.
**Acceptance:** daemon flags confirmed from local `--help` output; end-to-end p50/p95 for ≥3 modes on both transports; recall@3 baselines recorded; memory recorded; go/no-go recommendation. If no transport/mode is projected to pass M1–M5, the memo says so explicitly and AKM-002 becomes a design-exception decision for the operator (M6).

### AKM-002 — Retrieval design (#decision, medium)

Consumes AKM-001. Decide: transport; mode per trigger (skill-activation → structured `lex:`+`vec:` vs pure vector; new-content stays hybrid unless evidence says otherwise — C7); accept-empty floor semantics and provisional values per mode (U2); score-0 drop; splitting-hack removal plan; empty-brief handling in `skill-preflight.sh`. **Precondition:** U5 resolved by test before the empty-brief design is finalized — exercise every hooked consumer with an empty brief and record behavior (no errors, no malformed injection). Fixture-predicted outcomes for each choice against M1–M5.
**Acceptance:** design doc approved by operator; every choice traceable to F1–F9 or AKM-001 data; U5 test results included; matrix pass projected for the chosen combination — or a design exception raised to the operator instead (M6).

### AKM-003 — Implement wrapper changes (#code, medium — live retrieval path)

Mode flip, structured-query assembly, delete groups-of-3 splitting, score-0 drop, accept-empty floor in `knowledge-retrieve.sh`; empty-brief `empty_reason` logging; `skill-preflight.sh` empty-brief tolerance if AKM-002 requires. Dispatch trigger path: leave untouched unless the mode function refactor forces a change (log if so).
**Acceptance:** M1–M5 pass on the implemented system; all three triggers exercised post-change (skill-activation, new-content, dispatch) producing well-formed briefs or clean empties — no hook errors, no malformed injection; shellcheck clean; rollback path documented and tested, with mode-routing/query-construction changes kept isolated so a revert stays contained.

### AKM-004 — Fixture re-baseline + soak definition (#code, low)

Re-run fixture post-change; record new baseline (fixture `version: 2`); define the 2-week soak: what to watch in `akm-feedback.jsonl` (empty-brief rate, surfaced-item counts, operator flags), where flags land (run-log).
**Acceptance:** new baseline recorded; soak checklist in run-log with start date.

### AKM-005 — R3 consumption-hook design (#decision, medium, new primitive)

PostToolUse on Read filtered to `Sources/`|`Domains/` paths; reconciliation into `akm-feedback.jsonl` (schema extension, positive-only per C6). Minimal linkage model (normative): a consumption event carries at least note path, session identifier, timestamp, and the surfacing-event ID when resolvable; reconciliation matches read-path to surfaced-path within a bounded time window. Precondition: validate A4/U3 against the hook API; if payloads lack usable path data, descope R3 by spec amendment (A4 contingency) rather than work around. **Operator approval gate (Primitive Creation Protocol).**
**Acceptance:** approved design covering event shape, linkage fields, schema, reconciliation, and failure isolation (hook errors must never block Read).

### AKM-006 — Implement consumption hook (#code, medium)

Hook script + `.claude/settings.json` registration + feedback-log schema extension.
**Acceptance:** a real Read of a Sources/ file after a surfacing session produces a consumption event linked to the surfaced item; no events for non-KB paths; added end-to-end hook latency <50ms p95 warm, measured on both eligible and fast-exit (non-KB) paths; positive-only semantics verified (no miss records exist).

### AKM-007 — R4 new-content-hook design (#decision, medium, new primitive)

PostToolUse on Write|Edit detecting `#kb/`-tagged files under `Sources/` → `knowledge-retrieve.sh --trigger new-content`. Normative trigger semantics (design inputs): fire when the written file's path is under `Sources/` AND its current content contains a `#kb/` tag (tag-present-on-save, not tag-newly-added); debounce by path so repeated edits to one file within the window fire once; exclude self-triggered writes (files written by AKM or the hook's own pipeline); renames/moves do not fire. Precondition: A4/U3 validated; descope by amendment if payloads lack path data. CLAUDE.md behavioral signal-scan paragraph: deletion owned by VO-037 (XD-028); until then both mechanisms are live — overlap window accepted and documented there. **Operator approval gate (Primitive Creation Protocol).**
**Acceptance:** approved design; XD-028 row updated with the overlap window.

### AKM-008 — Implement new-content hook (#code, medium)

**Acceptance:** creating a `#kb/` note under Sources/ fires new-content retrieval and logs to the feedback jsonl; no fire on non-KB writes; no re-trigger loops; hook errors never block Write/Edit.

### AKM-009 — Populate query_hints (#research #code, low)

Use fixture `--explain` traces plus the known March miss class to identify vocabulary mismatch; populate `query_hints` for affected skills in `skill-preflight-map.yaml`. Note: if the AKM-002 decision moves skill-activation off BM25, hints become `lex:` terms in structured queries — semantics shift with the mode decision.
**Acceptance:** hints populated for every skill showing mismatch; a previously-missed doc demonstrably surfaces; no fixture regression.

### AKM-010 — Execute and close the soak (#research, low)

Run the ≥2-week soak defined in AKM-004: observe `akm-feedback.jsonl` (empty-brief rate, surfaced-item counts) and operator noise flags per the success-criterion-7 convention.
**Acceptance:** soak window completed; run-log verdict written (pass, or failures enumerated with disposition); success criterion 7 evaluated explicitly.

## Out of Scope

- **R6 serendipity revival** — stays dead per the original decision rule; the cheap Cowork-digest fold is available later if wanted.
- **Chronic-miss suppression re-enable** — R3 builds the instrument only; re-enable is a future decision on real data.
- **Decay-constant retuning** and **chapter-digest indexing** — both blocked on R3 consumption data by design.
- **Trigger-role redesign** — C7; roles are settled, only modes/mechanics change.

## Risks

| Risk | Level | Mitigation |
|---|---|---|
| Mode flip degrades some query class the fixture doesn't cover | medium | Fixture is the filter, 2-week soak is the verdict (success criterion 7); single-function rollback |
| Daemon becomes an unmonitored failure point | medium | AKM-001 measures failure behavior; wrapper must degrade to CLI (or empty brief) when daemon absent; service registration |
| Hook overhead on every Read/Write (R3/R4) | low | <50ms acceptance bar; path-filter fast-exit like skill-preflight's non-eligible fast path |
| Accept-empty hides genuine misses (silence looks like health) | medium | R3 consumption data + fixture recall floor keep quality observable; empty_reason logged |
| Feedback-log schema change breaks existing consumers | low | Additive-only fields; verify stats tooling after extension |
