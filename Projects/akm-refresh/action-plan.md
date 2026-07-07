---
type: action-plan
project: akm-refresh
domain: software
status: active
skill_origin: action-architect
created: 2026-07-07
updated: 2026-07-07
topics:
  - moc-crumb-architecture
tags:
  - action-plan
  - akm
---

# akm-refresh — Action Plan

Decomposition of the approved specification (peer-reviewed round 1, revised 2026-07-07). Ten tasks across four milestones. The M1–M6 acceptance matrix in the spec governs all R2 work; M6 (viability rule) is a halt-for-operator gate, not a soft warning.

**Calibration note (estimation-calibration.md):** spec-stage task counts ran 2.6–3.0x under at execution on the last two infra projects. These ten tasks are cut finer than those specs' lines (each already carries acceptance criteria), so expansion should be milder — expect splits in AKM-003 (wrapper vs preflight changes) and AKM-006/008 (hook script vs registration vs verification) rather than new workstreams. Checkpoint-triggered pivots compress: if M6 fires at M1, M2 reshapes and M4 shrinks; if the A4 contingency fires, M3 partially or fully descopes by amendment. Neither is failure — both are the gates working.

## M1 — Transport & Mode Decision (R2 design)

The load-bearing milestone: everything downstream keys off which transport/mode combination can pass M1–M5.

### Phase 1.1 — Daemon latency spike (AKM-001)

Staged per `staged-spike-with-bail.md`:
- **Stage 0 (bail checkpoint, ≤10% of spike budget):** confirm `qmd mcp --http --daemon` exists with usable flags on the *installed* qmd 2.5.3 — local `--help` output, primary source, not release notes. Bail rule: no daemon (or no usable interface) → skip daemon profiling entirely; spike collapses to CLI-only end-to-end profiling.
- **Stage 1:** end-to-end latency profiling (wrapper-entry to brief-emit, splitting hack disabled), p50/p95 warm/cold, ≥3 modes on each available transport; daemon RSS, warmup, and down-daemon failure behavior.
- **Stage 2:** fixture recall@3 baselines per mode (M1 gate inputs).
- Output: decision memo in `design/` stating explicitly whether any combination is projected to pass M1–M5.

### Phase 1.2 — Retrieval design (AKM-002)

Consumes the memo. Decides transport, per-trigger mode, accept-empty floors, score-0 drop, splitting removal plan, empty-brief handling. **Precondition inside this task:** U5 resolved by test — every hooked consumer exercised with an empty brief before the empty-brief design is finalized. **Operator approval gate.** If nothing passes M1–M5, this task becomes the M6 design exception instead — halt, present options (relax SLO / accept lower gate / daemon investment / stay on BM25 + hints only), operator decides.

**M1 success criteria:** operator-approved design projected to pass M1–M5, OR M6 design exception raised and decided. U5 test results on record.

## M2 — Precision Trigger Rebuild (R2 implementation)

### Phase 2.1 — Wrapper implementation (AKM-003)

Mode flip, structured-query assembly, splitting-hack deletion, score-0 drop, accept-empty floor, `empty_reason` logging, preflight empty-brief tolerance. Medium risk — this is the live retrieval path; rollback isolation is an acceptance criterion.

### Phase 2.2 — Re-baseline + soak start (AKM-004)

Fixture v2 baseline; soak checklist (empty-brief rate, surfaced counts, noise-flag convention per success criterion 7) written to run-log with a start date. The 2-week clock starts here.

**Milestone boundary:** run code-review skill on the wrapper/preflight diff before declaring M2 complete (production scripts on the live path; vault-only project still gets review).

**M2 success criteria:** M1–M5 pass on the implemented system; fixture v2 recorded; soak live; code review logged.

## M3 — Feedback-Loop Primitives (R3 + R4)

Designs can run in parallel with M1/M2; implementations require AKM-003 (shared wrapper/feedback-log surface).

### Phase 3.1 — Hook designs (AKM-005, AKM-007 — parallelizable)

The A4/U3 hook-payload validation executes **once**, at the start of whichever design task runs first; the other consumes the result. Each design ends at a **Primitive Creation Protocol operator approval gate**. If payloads lack usable path data: descope by spec amendment (success criteria 4–5 re-scoped), no workaround hacks.

### Phase 3.2 — Hook implementations (AKM-006, AKM-008)

Hook scripts + `.claude/settings.json` registration + fault-injection verification (hook errors must never block the wrapped tool). R4 go-live updates XD-028 (overlap window with the CLAUDE.md behavioral paragraph until VO-037 deletes it).

**Milestone boundary:** code-review skill on both hook scripts before declaring M3 complete.

**M3 success criteria:** both hooks live and verified (<50ms p95 added latency, fault isolation demonstrated), OR clean descope by amendment. XD-028 current.

## M4 — Vocabulary & Closure (R5 + soak verdict)

Runs inside the soak window — the 2-week wait is working time, not idle time.

### Phase 4.1 — query_hints population (AKM-009)

After AKM-003 (mode decision changes hint semantics: hints become `lex:` terms if skill-activation leaves pure BM25). Fixture `--explain` traces + the March miss class identify targets; no regression vs fixture v2.

### Phase 4.2 — Soak execution & closure (AKM-010)

≥14 days from AKM-004's start date. Close with a run-log verdict and an explicit evaluation of success criteria 1–7. This is the project's DONE gate input.

**M4 success criteria:** hints populated and verified; soak verdict logged; all seven success criteria explicitly evaluated.

## Dependency graph

```
AKM-001 → AKM-002 → AKM-003 → AKM-004 → AKM-010
                        ├→ AKM-009
                        ├→ AKM-006 (also ← AKM-005)
                        └→ AKM-008 (also ← AKM-007)
AKM-005 ∥ AKM-007 (designs — parallel with M1/M2; A4/U3 validation shared, runs once)
```

## Operator gates in this plan

1. AKM-002 design approval (or M6 design exception decision)
2. AKM-005 primitive approval (Primitive Creation Protocol)
3. AKM-007 primitive approval (Primitive Creation Protocol)
4. AKM-010 soak verdict acknowledgment → DONE gate

## Out of plan

R6 serendipity; chronic-miss re-enable; decay retuning; chapter-digest indexing (all await R3 data, future project); A10 DeepSeek timeout config (operator item, not project work).
