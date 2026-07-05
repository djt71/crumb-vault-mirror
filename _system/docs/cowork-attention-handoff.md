---
type: reference
domain: null
status: active
skill_origin: null
created: 2026-07-05
updated: 2026-07-05
tags:
  - cowork
  - attention
  - handoff
---

# Attention Manager → Cowork Handoff

**Origin:** `.claude/skills/attention-manager/` (skill retired 2026-07-05, operator
decision: "good idea that had poor execution — as with opportunity-scout, this should
move to Cowork"). Full skill definition recoverable from git history. This note is the
durable extract; read it before building any Cowork-based attention practice.

**Governing frame:** the daily attention plan is the mechanism that keeps the three
pillars *visible* day-to-day (Liberation Directive v3) — it caught Q1 2026 running 71%
work on weekdays. It is a channel, not an instrument: it curates and prompts, it never
grades. "I run the 24 hours. The 24 hours doesn't run me."

## Why the first execution failed

**The skill validated; the practice died.** The 30-day soak (completed 2026-04-06,
29/30 artifacts) proved the design — carry-forward escalation, domain balance, quality
evolution all passed. Then usage stopped entirely within weeks. The failure was the
invocation model: a *daily* artifact that required the operator to open a terminal,
start a Claude Code session, and ask for it. Human-initiated ceremony is exactly wrong
for a daily cadence — the plan needs to be waiting for Danny, not summoned by him.
Cowork scheduled runs invert precisely this: rented runtime produces the plan; Danny's
only touch is reading it.

Secondary factor: input rot. The skill's goals source (`goal-tracker.yaml`) required
its own monthly operator refresh — a second ceremony propping up the first. It went
stale within a quarter and was retired with the skill (2026-07-05, git history).

## What survives (validated design, reuse it)

- **The daily artifact format** (soak-proven): 5–8 Focus items, each with *why-now* /
  domain / source; Domain Balance section; Carry-Forward with day counts; Deferred with
  reasoning. Carry-forward escalation at 5+ days: "still a priority, or drop it?"
- **The domain balance check:** flag when work (career + software) exceeds 60% of Focus
  items two days running — this is the pillar-visibility mechanism.
- **The two lenses**, which live on as vault overlays (readable from Cowork):
  `_system/docs/overlays/life-coach.md` (values alignment, whole-person impact, the
  "enough" test) + `_system/docs/overlays/career-coach.md` (skill leverage, relationship
  capital, opportunity cost). Life Coach pairs with
  `Domains/Spiritual/personal-philosophy.md`.
- **Priority heuristic:** non-negotiables (family, health, hard deadlines) always list;
  among discretionary items, bias to external visibility / time decay over
  internal-accountability-only.
- **The monthly review shape:** aggregate the month's dailies → domain distribution,
  chronic carry-forwards and what they signal, completion rates → propose adjustments.
- **Inputs, all vault-readable from Cowork:** `_system/docs/personal-context.md`
  §Strategic Priorities (the goals source now — goal-tracker is gone),
  `Domains/Career/se-management-inventory.md` (cadence-annotated obligations),
  `Projects/*/project-state.yaml` `next_action` fields.

## Reboot constraints (from the current architecture)

- **Surface:** Cowork scheduled run (rented runtime). This is squarely the AS-023 pilot
  class; scheduling ownership rides that pilot's outcome.
- **Write boundary:** the daily plan is a stateful consumable → the enumerated drop zone
  `_system/daily/` (already designated for exactly this in `adr-vault-write-boundary.md`),
  or stateless outside-in delivery (push/Gmail). Operator edits to the artifact are
  authoritative — the plan is a proposal.
- **No grading, ever:** the constitution protects unoptimized pillar time. No streaks,
  no scores, no completion pressure on spiritual/physical items. Curate and prompt only.
- **Degradation-aware:** in winter mode (Directive v3 §Graceful Degradation) the plan
  shrinks or pauses without failure narrative — a cadence that survives low-energy
  periods or degrades gracefully with them.
- **Retired with the skill** (git history if ever needed): `goal-tracker.yaml`, the
  `attention-item` / `daily-attention` / `attention-review` schema types and their
  vault-check checks (§26/§27). Historical artifacts remain in `_system/daily/`.
