---
type: progress-log
project: tess-danny-migration
status: active
created: 2026-06-08
updated: 2026-06-08
---

# Tess → Danny Account Migration — Progress Log

High-level milestone tracker. Detailed session notes live in [[run-log]].

## Milestones

| # | Milestone | Phase | Status |
|---|---|---|---|
| M0 | Plan + decisions locked; runbook written | PLAN | ✅ done (2026-06-08) |
| M1 | Task decomposition (P0–P7 → atomic tasks) | TASK | ✅ done (2026-06-08) — 22 tasks in [[tasks]] |
| M2 | P0 freeze + pre-flight + danny admin grant | IMPLEMENT | ⬜ pending |
| M3 | P1 bulk copy + P2 path rewrite | IMPLEMENT | ⬜ pending |
| M4 | P3 secrets + P4 runtime rebuild | IMPLEMENT | ⬜ pending |
| M5 | P5 launchd standup (incl. dup pruning + calendar-interval fix) | IMPLEMENT | ⬜ pending |
| M6 | P6 verification gates green | IMPLEMENT | ⬜ pending |
| M7 | P7 retire tess (post-soak) | IMPLEMENT | ⬜ pending |

## Gating decisions (all resolved 2026-06-08)
- ✅ TDM-001 agent keep/drop: faithful copy; drop 3 (2 disabled email-triage +
  nemotron-load). [[agent-keep-drop-map]]. **Found CalendarInterval works on 26.5 →
  TDM-041 voided; memory corrected.**
- ✅ TDM-002 cloudflared: reuse tunnel UUID, copy 3 files, ingress unchanged.
- ✅ TDM-003 secret manifest: Tier A (11 keychain, re-key) / A′ (re-auth) / B (files
  copy). [[secret-manifest]]. Shrinks TDM-030.

## Flags carried into execution
- Dormant monitoring stack (dashboard + cloudflared + telemetry) — carry vs drop (operator's call).
- nemotron-load DROP recommended (1040× fail) — override available.
