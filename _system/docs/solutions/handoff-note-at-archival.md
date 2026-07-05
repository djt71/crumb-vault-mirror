---
type: pattern
domain: software
status: active
track: pattern
linkage: discovery-only
created: 2026-07-05
updated: 2026-07-05
tags:
  - system-design
  - archival
  - compound-insight
  - kb/software-dev
topics:
  - moc-crumb-operations
---

# Handoff Note at Archival

## Pattern

When a concept survives its implementation — the operator verdict is "good idea, poor
execution" rather than "bad idea" — the exit deliverable is not just the archival: it is
a **reboot brief**, written at decommission time while the failure analysis is fresh.

The brief has three mandatory sections:

1. **Why the execution failed** — the specific mechanism, not a vibe. ("Self-hosted
   pipeline = maintenance gravity"; "daily artifact behind human-initiated ceremony";
   "hardcoded priorities never learned the operator's taste.") The next builder must be
   able to check their design against each named failure.
2. **What survives** — validated design elements, calibration data, formats that passed
   their soak, with pointers to where each lives (git history, archived design docs,
   overlays, memories). Distinguish *proven* assets from untested leftovers.
3. **Target-surface constraints** — the architectural rules the reboot must honor
   (which runtime, which write boundary, which hard gates), stated from the *current*
   architecture, not the one the dead implementation was built for.

Without the brief, archived design docs rot undiscovered and the reboot either starts
from zero or — worse — rediscovers the original design and repeats its failure mode.
The brief converts an archival from an ending into a compounding step (Directive v3,
Gate 6: artifacts persist and carry into the next attempt).

## Anti-pattern it replaces

"The docs are all in the archive" — true and useless. Nobody reads an archived project
tree before building; everybody reads a two-page brief named after the target surface.

## Evidence

- **2026-07-05, opportunity-scout** → `_system/docs/cowork-scout-handoff.md`. Concept
  (browse freely, Directive v3 Principle 5) rebooted on Cowork; brief carries the
  calibration-seed graveyard, anti-firehose discipline, and rented-runtime constraints.
- **2026-07-05, attention-manager** → `_system/docs/cowork-attention-handoff.md`. Skill
  retired same day, same verdict; brief carries the soak-proven artifact format, the
  60%-work domain-balance threshold, both coaching lenses, and the no-grading rule.
  Second instance hit the promotion threshold; operator approved this doc.

## When it applies

Any decommission where the concept is explicitly rehabilitated (directive, run-log, or
operator statement says execution-not-concept failed) AND a future incarnation is
plausible on another surface. Pure kills (bad idea, superseded need) get a normal
archival — no brief, no ceremony.
