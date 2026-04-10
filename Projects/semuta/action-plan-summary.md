---
type: action-plan-summary
status: draft
domain: software
project: semuta
created: 2026-03-18
updated: 2026-03-18
source_updated: 2026-03-18
---

# Semuta — Action Plan Summary

## Structure
3 milestones, 9 tasks (SEM-005 split into 005a interface + 005b shaders). Phase 0 only
(Deep Still mode end-to-end + live URL).

## Phase 0 Definition of Done
All task ACs met + live URL shared beyond Danny + Danny confirms 3+ minutes of
meditative quality.

## Milestones

**M1 — Development Environment + Core Engines** (SEM-001, SEM-005a, SEM-002/003/004)
Scaffold, Mode interface (with lifecycle hooks), GPU engine (format fallback chain,
error scopes, device loss halt), parameter bus (scene recorder, phase transitions),
audio engine (isReady = dry path, convolver fades in later). Success: engines functional.

**M2 — Deep Still Mode** (SEM-005b, SEM-006, SEM-007)
Visual shaders staged (toy sim → Gray-Scott at 512×512 fixed grid) + audio mode
(parallel), then integration. SEM-007: entanglement via structured evaluation with
negative test, screen recordings, scene recorder replay. Success: Danny confirms.

**M3 — Ship** (SEM-008)
Start experience transition (fades, not snaps). Start gated on dry audio path, not IR
decode. Chrome must-have, Safari should-have (Tahoe+). Success: shareable URL.

## Critical Path
SEM-001 → SEM-002 → SEM-005b → SEM-007 → SEM-008

## Key Decisions
- **Resolution independence:** 512×512 simulation grid, decoupled from display. Upscale
  via bilinear. Performance and aesthetic win.
- **Start gating:** isReady = dry signal path. IR convolver fades in when ready.
- **Format fallback:** rgba16float → rgba32float → graceful error.
- **Evolution:** 45 min primary, 35-55 min staggered per-param (no shared periods).
  Filtered noise, not sine LFOs. Phase transitions every 10-20 min.
- **Browser targets:** Chrome (must), Safari Tahoe+ (should), Firefox (not Phase 0).
- **A4 retired:** Vite ?raw is documented tooling, not a hypothesis.

## Key Risks
- SEM-005b: WGSL debugging (R1) + GPU performance (R2) — mitigated by staged approach
- SEM-007: coupling quality (R4) — mitigated by structured evaluation + negative test
- SEM-004: high risk (audio lifecycle) — mitigated by isReady decoupling
- R7 scope creep: 6-week timebox check-in

## Reviews
- **Spec peer review (2026-03-17):** 4 reviewers, 11 action items applied.
- **Action plan peer review (2026-03-18):** 4 reviewers, 2 must-fix + 9 should-fix.
- **External synthesis (2026-03-18):** 5 reviewers across all 4 docs, 5 MF + 14 SF +
  12 NH + 5 DN applied. Design spec bumped to v0.2.

## Full Plan
See `action-plan.md` and `tasks.md` in the project root.
