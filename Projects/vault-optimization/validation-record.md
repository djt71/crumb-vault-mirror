---
project: vault-optimization
domain: software
type: reference
skill_origin: null
created: 2026-08-10
updated: 2026-08-10
---

# Functional Validation Record — M5 Soak (VO-009 / VO-036)

Spec end-state deliverable #6: demonstrates the pruned vault still performs its
Tier-1 workflows. Written at VO-036 close-out from run-log provenance
(`progress/run-log.md`, entries 2026-07-04 → 2026-08-08).

## Soak Parameters

| Parameter | Value |
|---|---|
| Window start | 2026-07-04 (B6 commit — full B0–B6 pruned configuration live) |
| End condition | max(start + 14 calendar days, start + 8 working sessions) |
| Window close | 2026-08-08, operator decision (35 days elapsed; WS 5/8) |
| Pass criteria | Zero urgent git restores; no repeated workarounds |
| Failure protocol | Fix-forward vs revert per action plan (never invoked) |

The 8-working-session bound was never reached because the vault went dormant
2026-07-14 → 2026-08-08 — not because sessions stressed the surface and
stalled. The 25-day unattended stretch is itself evidence: the pruned surface
ran with no operator present and nothing needed restoring (confirmed by the
2026-08-08 automated vault-health run and full audit — 0 errors, all counts
consistent).

## Criteria Verdicts

- **Zero urgent restores** — PASS. None in window.
- **No repeated workarounds** — PASS. None recorded in window.

## Tier-1 Workflow Outcomes (design D6)

| # | Workflow | Outcome | Evidence |
|---|---|---|---|
| 1 | Full phase transition with checkpoint protocol | UNEXERCISED → watch item | No phase gate occurred naturally in window |
| 2 | inbox-processor run | UNEXERCISED → watch item | No intake occurred naturally in window |
| 3 | peer-review / deliberation dispatch | UNEXERCISED → watch item | No dispatch occurred naturally in window (deliberation itself retired 2026-07-07, post-keep-set operator delta) |
| 4 | KB query + signal scan | **PASS** (2026-07-06) | skills-library SPECIFY session: skill-preflight hook injected 3-item knowledge brief; signal scan noise gate applied correctly (>15 hits → 7 candidates → 3 selected); sources materially shaped the spec. Zero friction, no retired primitive missed |
| 5 | Session-end sequence | **PASS ×9** (2026-07-04 → 2026-08-08) | Full 7-step protocol runs, every close in window |
| 6 | Skill-routing spot-checks on rewritten descriptions | **PASS ×2** (2026-07-04 fast-pass; 2026-07-06 within-window 8/8) | Fresh prompt set second pass, zero overlap with first, incl. negative-routing edge (retired attention-manager correctly unmatched). Two registry residues found were enforcement-config remediation lag, not routing failures — fixed in-window |

## Verdict

**PASS on all exercised criteria.** Closed at operator discretion
(2026-08-08) with workflows #1–#3 unexercised — unexercised, not failed.
Disposition: carried as **post-soak watch items** — log opportunistically
when a session naturally exercises them; no gate, no scheduled re-test.

**The B0–B6 pruned configuration is accepted as the operating baseline.**

## Post-Soak Watch Items

1. Full phase transition with checkpoint protocol against the pruned surface
2. inbox-processor run against the pruned surface
3. peer-review dispatch against the pruned surface

## In-Window Deltas (recorded, soak-neutral)

- Operator keep-set deltas landed mid-window via the skills-library project
  (2026-07-07): skill roster 15 → 11 (researcher, critic, sync, deliberation
  retired; code-review escalation tier renamed review-panel). Assessed at the
  time as operator decisions, not B5 regressions; routing surface re-verified
  clean.
- Routine retention churn: vault-gc 30-day TTL pruned 8 stale peer-review raw
  JSONs (~2026-07-10). Per design, not a restore or workaround.
