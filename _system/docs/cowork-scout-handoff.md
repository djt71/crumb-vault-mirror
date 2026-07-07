---
type: reference
domain: null
status: active
skill_origin: null
created: 2026-07-05
updated: 2026-07-06
tags:
  - cowork
  - discovery
  - handoff
---

# Opportunity Scout → Cowork Handoff

**Origin:** `Archived/Projects/opportunity-scout/` (archived 2026-07-05, operator decision:
"good idea, poor execution — move into Claude Cowork, out of the vault"). This note is the
durable extract; read it before building any Cowork-based discovery surface.

> **Reboot built 2026-07-06:** [[cowork-scout-instructions]] is the canonical paste block
> for the Cowork "Opportunity Scout" project. Cadence: on-demand only (operator decision;
> AS-023 closed as a decline, so the scheduling-ownership deferral below is resolved).

**Governing frame:** Liberation Directive v3, Principle 5 (*browse freely; commit on
belief*) — the scout failure was execution, not concept. A cadence of interesting ideas to
browse is sound, under two conditions: **no conversion obligation** (a browsed idea is not
a lead to be worked) and **rented runtime** (Principle 6 — no self-hosted infrastructure).

## Why the first execution failed

1. **Self-hosted machinery.** Daily launchd pipeline, SQLite candidate registry, Telegram
   bot delivery, health heartbeats — maintenance gravity that outweighed the browsing value
   it delivered. Exactly what Principle 6 now forbids. The Cowork incarnation rents all of
   this: a scheduled or on-demand Cowork session *is* the pipeline.
2. **It never learned what "interesting" meant.** Priorities were hardcoded persona copy
   inside prompts (binary: FI-aligned = push, else ignore), which drove three consecutive
   digests into financial-independence framing against Danny's actual Q2 priorities.
   Fixes that came too late but remain valid: three-tier priority model
   (`feedback-priority-tiers-not-binary` memory) and reading priorities from
   `_system/docs/personal-context.md` at run time — never baked into prompt copy.
3. **Conversion pressure.** Scoring/ranking machinery implicitly treated browsed items as
   leads. v3 removed that: the gate sits at commitment (six gates + peer review for
   discovery-originated bets), not at looking.

## What survives (assets for the reboot)

- **Calibration seed** — `Archived/Projects/opportunity-scout/design/calibration-seed.md`:
  the graveyard (5 permanently rejected categories with reason codes — notably all
  DDI/Infoblox-adjacent patterns, which remain PIIA hard-gate exclusions) and the
  high-scoring patterns (DNS hygiene toolkit, expert newsletter, public-domain wisdom
  library, one-time digital products) with the nine-dimension scoring rationale.
- **Anti-firehose discipline** — threshold delivery (no empty digests), attention budget
  (10–15 min/day ceiling), abort criteria. The failure mode "a firehose Danny learns to
  ignore" is medium-independent and applies to any Cowork digest too.
- **Memories:** `feedback-priority-tiers-not-binary`, `feedback-feed-intel-stays-open`
  (filter downstream, keep intake open).
- **Wildcatter skills (recovered 2026-07-06)** —
  `Archived/Projects/opportunity-scout/design/wildcatter-*-skill.md`: the Perplexity
  Computer three-stage pipeline (opportunity-hunter → deal-critic → plan-architect).
  Already salvaged: the hunter's five scan categories → browse lenses in
  [[cowork-scout-instructions]]. Worth pulling **at commitment time** (six-gate review
  of a discovery-originated bet): the critic's memo format (why it could work / what
  most likely kills it / which assumptions invalidate it), the plan-architect's
  grounded/estimated/speculative assumption labels, and the asymmetry taxonomy
  (information/distribution/technology/regulation). Everything else is v2-era doctrine
  — conversion funnel, hardcoded founder profile, 30–90-day revenue urgency — do not
  revive as machinery.

## Reboot constraints (from the current architecture)

- **Surface:** Claude Cowork (rented runtime). Scheduling per the work-surfaces roster;
  scheduling ownership (Cowork-scheduled vs Routines) rides the AS-023 pilot outcome.
- **Write boundary:** findings worth keeping enter via `_inbox/` (knowledge candidates,
  operator-pulled promotion) per `adr-vault-write-boundary.md`. No direct vault writes,
  no new pipeline state anywhere.
- **Hard gates carry over:** PIIA safety (no DDI/DNS-security adjacency, gray zones
  disqualify); peer review fires only at commitment, never at browsing.
- **No standing new-primitive:** no skill, no agent, no schema until real Cowork usage
  pulls one into existence (ceremony budget principle).
