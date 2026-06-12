---
type: reference
status: active
created: 2026-03-01
updated: 2026-03-01
domain: software
tags:
  - system-health
  - architecture
---

# Crumb v2.1 — External System Health Assessment

## Source

ChatGPT analysis of the Crumb design spec v2.1 (2026-03-01). Reviewed and annotated in claude.ai session with Danny. This was an unprompted architectural assessment — ChatGPT was given the spec and asked to evaluate it, not to solve a specific problem.

## Why This Is Worth Reading

This analysis evaluates the systemic risks and friction points in Crumb v2.1 that would affect any new capability built on top of it. The observations are not tied to a specific project — they apply across the board.

This document is the provenance for the **Ceremony Budget Principle** in CLAUDE.md — the reasoning and evidence behind the directive. When the principle is revisited, start here.

## What the Assessment Got Right

### Maintenance gravity is the core systemic risk

The system's biggest long-term threat isn't architectural — it's that the ceremony required to keep it running becomes burdensome enough that it stops being used as intended, or gets used partially in ways that create shadow workflows. The spec is operationally grounded, but operational systems only work if the operator keeps operating them.

This is the right risk to name. It should be evaluated honestly: are there places where the system is already accumulating "I'll do that later" debt?

### Bias toward minimally-valid stubs

The assessment recommends extending the `needs-description` / `needs-extraction` pattern more broadly: wherever a rule exists, provide a default generator path that creates compliant minimal state automatically, even if filled with placeholders. "Doing the right thing" should always be the path of least resistance.

The vault already leans this way in places. The question is whether it leans far enough — or whether there are compliance requirements that currently block rather than stub.

### No single mechanical definition of "active focus"

With ~6 projects in various phases, nothing formally distinguishes "what I'm focused on right now" from "what's technically active." The vault snapshot captures active projects for triage context, but "active" is a loose category. Without a formal focus signal, any system that tries to prioritize context (knowledge surfacing, session startup, digest ordering) has to guess.

Worth evaluating: does the system need a focus artifact (e.g., a field in `project-state.yaml`, a dedicated `focus.md`), or is the current implicit model sufficient?

### MOC maintenance can become "always yelling"

As the KB grows and more notes get `#kb/` tags, MOC synthesis density warnings (vault-check 21) fire more frequently. If the system is constantly nagging about stale synthesis sections, the warnings get ignored — which degrades the enforcement layer that makes MOCs useful.

The assessment suggests a "quiet period" policy: warnings proportional to change (new notes added since last review) rather than absolute state. Attention stays proportional to actual drift.

## What to Discount or Contextualize

### Bridge security recommendations

The assessment includes recommendations on rate limiting, session nonces, and time-bounded capability tokens for the Tess bridge. These are reasonable operational hardening suggestions but are specific to bridge security, not systemic. Evaluate on their own merits during tess-operations or bridge maintenance, not as system-wide concerns.

### DONE vs. ARCHIVED ambiguity

The assessment flags potential ambiguity between DONE and ARCHIVED project states. This is a valid theoretical concern but is already well-managed by the spec's lifecycle definitions and vault-check enforcement. Monitor over time rather than treat as an active problem.

## Observations Worth Sitting With

These don't have obvious action items but are worth keeping in mind as the system evolves:

- **"The main risk isn't 'will it work?' — it's maintenance gravity."** The system is operationally sound. The question is whether it stays pleasant enough to sustain.
- **"Correct but not used" is a failure mode.** Compliance that creates friction eventually gets routed around.
- **"Shadow workflows" emerge when the official path is too heavy.** If something is easier to do outside the system than inside it, it will be done outside the system.
- **Reducing ceremony is higher leverage than adding capability.** Before building new features, check whether existing features have unnecessary friction that could be removed.
