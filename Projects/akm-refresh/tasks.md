---
type: tasks
project: akm-refresh
domain: software
status: active
skill_origin: action-architect
created: 2026-07-07
updated: 2026-07-07
topics:
  - moc-crumb-architecture
tags:
  - tasks
  - akm
---

# akm-refresh — Tasks

Source: `specification.md` (approved 2026-07-07, post peer review) via `action-plan.md`. The M1–M6 acceptance matrix (spec §Success Criteria) governs AKM-001…004. States: `pending` → `in-progress` → `done` (or `descoped` via amendment).

| id | description | state | depends_on | risk_level | domain | acceptance_criteria |
|----|-------------|-------|------------|------------|--------|---------------------|
| AKM-001 | Daemon latency spike (staged; Stage-0 bail on daemon availability per staged-spike-with-bail) | pending | — | low | software | Stage-0 verdict recorded (daemon flags confirmed from local `--help`, or bail invoked)? End-to-end p50/p95 (wrapper-entry→brief-emit, splitting disabled) recorded for ≥3 modes on each available transport? Fixture recall@3 baselines recorded per mode? Daemon RSS + down-daemon failure behavior recorded (if daemon exists)? Memo states explicitly whether any combination is projected to pass M1–M5? |
| AKM-002 | Retrieval design: transport, per-trigger mode, floors, splitting removal, empty-brief handling | pending | AKM-001 | medium | software | Design doc in `design/` with operator approval recorded in run-log? U5 empty-brief test run against every hooked consumer with results in the doc? Every decision traceable to spec facts or AKM-001 data? Projected M1–M5 pass documented — or M6 design exception raised and operator decision recorded instead? |
| AKM-003 | Implement wrapper changes (mode flip, structured queries, delete splitting, score-0 drop, accept-empty, empty_reason logging, preflight tolerance) | pending | AKM-002 | medium | software | M1–M5 all pass on the implemented system? All three triggers exercised post-change with well-formed briefs or clean empties (no hook errors, no malformed injection)? shellcheck clean? Rollback path documented and tested with mode-routing/query-construction changes isolated? |
| AKM-004 | Fixture v2 re-baseline + soak definition and start | pending | AKM-003 | low | software | Fixture `version: 2` baseline recorded? Soak checklist in run-log with start date? Empty-brief-rate and noise-flag conventions (success criterion 7) documented? |
| AKM-005 | R3 consumption-hook design (new primitive — Primitive Creation Protocol) | pending | — | medium | software | A4/U3 payload validation result recorded (shared with AKM-007)? Approved design covers event shape, linkage fields (path, session, timestamp, surfacing-event ID when resolvable), schema extension, reconciliation window, failure isolation? Operator approval recorded — or descope amendment written if A4 fails? |
| AKM-006 | Implement consumption hook (script + settings.json registration + schema extension) | pending | AKM-005, AKM-003 | medium | software | Real Read of a Sources/ file after a surfacing session produces a consumption event linked to the surfaced item? Zero events for non-KB paths? Added latency <50ms p95 warm on eligible and fast-exit paths? Zero miss records exist (positive-only verified)? Hook failure never blocks Read (fault injection verified)? |
| AKM-007 | R4 new-content-hook design (new primitive — Primitive Creation Protocol) | pending | — | medium | software | Approved design implements normative semantics (tag-present-on-save, path debounce, self-trigger exclusion, no fire on rename/move)? A4/U3 result consumed (from AKM-005 or run here first)? Operator approval recorded — or descope amendment written? XD-028 updated with go-live plan? |
| AKM-008 | Implement new-content hook (script + registration + loop-prevention verification) | pending | AKM-007, AKM-003 | medium | software | Creating a `#kb/` note under Sources/ fires new-content retrieval with a feedback-log entry? Zero fires on non-KB writes? Zero re-trigger loops (verified)? Added latency <50ms p95? Hook failure never blocks Write/Edit (fault injection verified)? |
| AKM-009 | Populate query_hints from fixture --explain traces + March miss class | pending | AKM-003 | low | software | Hints populated for every skill showing vocabulary mismatch in traces? A previously-missed doc demonstrably surfaces in a verification trace? Fixture shows no regression vs the v2 baseline? |
| AKM-010 | Execute and close the ≥2-week soak | pending | AKM-004 | low | software | Soak window ≥14 days from AKM-004 start date completed? Run-log verdict written (pass, or failures enumerated with disposition per criterion-7 fail rules)? Success criteria 1–7 each explicitly evaluated in the closure entry? |

## Milestone boundaries (not tasks — enforcement notes)

- **M2 close:** code-review skill on the wrapper/preflight diff (vault-check §23 expects review evidence for completed code tasks).
- **M3 close:** code-review skill on both hook scripts.
- **M6 fire or A4 fire:** spec amendment before any downstream task proceeds — update this file's affected rows to `descoped` with the amendment reference.
