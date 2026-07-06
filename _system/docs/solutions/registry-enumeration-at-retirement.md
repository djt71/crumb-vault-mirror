---
type: solution
track: pattern
domain: software
status: active
created: 2026-07-06
updated: 2026-07-06
confidence: high
linkage: discovery-only
topics:
  - moc-crumb-operations
tags:
  - compound
  - decommission
  - operations
  - vault-hygiene
  - kb/software-dev
source_projects:
  - vault-optimization
  - agentic-sunset
source_artifacts:
  - Projects/vault-optimization/progress/run-log.md
  - _system/logs/session-log.md
---

# Registry Enumeration at Retirement

## Claim

When retiring a primitive (skill, script, service, schema), a reference-grep
answers "what *points at* this name?" — but registries, allowlists, hook maps,
and fast-path lists don't point at a name, they **authorize** it. An allowlist
entry for a deleted skill produces no dead wikilink, no runtime error, no
warning — it silently permits something that no longer exists, which means it
is invisible to both reference-sweeps and runtime failure signals. A retirement
sweep can therefore grep-verify "zero live references" and still leave permit
surfaces stale. **Retirement sweeps need an explicit registry-enumeration
step — walk the known permit surfaces and diff their entries against disk
reality — in addition to the reference-grep.**

The deeper mechanism (generalizes the trigger-driven-sweep problem): sweeps fix
what their trigger enumerates. A reference-grep's trigger is "the retired
name appears" — registries match that trigger textually but not semantically,
because removing the entry requires recognizing the *containing structure* as a
permission surface, not just the line as a mention. Structures that permit
rather than reference need their own enumeration pass.

## Evidence

Promotion threshold: second direct occurrence (flagged for next-occurrence
promotion in the 2026-07-05 VO session-end compound evaluation; operator
approved promotion 2026-07-06).

- **attention-manager allowlist residue (2026-07-06):** the 2026-07-05
  attention-manager retirement sweep was thorough — 13+ docs remediated,
  grep-verified "zero live references post-sweep" — yet `vault-check.sh`
  `REGISTERED_SKILLS` still allowlisted the deleted skill. Found only by the
  VO-035 #6 registry-consistency pass (deliberate enumeration: list on disk vs
  list in validator). Benign direction this time (stale *allowed* name can't
  fire a false warning), but the same miss on a deny-list or routing map would
  misroute silently.
- **excalidraw/lucidchart preflight keys (retroactive instance):** both skills
  were retired long before vault-optimization began, yet their
  `skill-preflight-map.yaml` key blocks survived *every* intervening sweep —
  including B5's full skills-batch remediation (noted 2026-07-04 as adjacent
  finding, removed 2026-07-06). Keys never fired (no matching skill), so no
  behavioral signal ever surfaced them.
- **Class-parent (2026-07-05 audit):** architecture docs "refreshed" in July
  retained pre-sunset framing because the remediation sweep fixed only the
  files on its trigger list — same root cause (sweeps fix what the trigger
  enumerates) expressed at the document level rather than the registry level.

## How to Apply

1. **At any primitive retirement**, after the reference-grep, enumerate the
   vault's known permit surfaces and check each for the retired name:
   - `_system/scripts/vault-check.sh` — `REGISTERED_SKILLS` and any other
     inline allowlists/check sections (§-numbered checks tied to schemas)
   - `_system/docs/skill-preflight-map.yaml` — per-skill keys
   - `_system/scripts/skill-preflight.sh` — bash fast-path list
   - `_system/docs/overlays/overlay-index.md` — activation-signal rows
   - `_system/docs/kb-to-topic.yaml` — tag→MOC mappings
   - `.claude/settings.json` hooks + permission allowlists
   - launchd plists / backup + sync filter lists (for scripts and services)
2. **Prefer bidirectional validators:** vault-check's skill check warns on
   *unregistered skill on disk* but not on *registered skill missing from
   disk* — a one-way check. When touching a validator, make list↔disk
   comparisons symmetric so registries self-report staleness instead of
   depending on sweep discipline.
3. **When writing a changeset pack** for a batch retirement, give permit
   surfaces their own checklist section — don't fold them into "consumer
   remediation," which reads as reference-consumers and invites the grep-only
   pass.

Related: [[infrastructure-teardown-discipline]] (producer/consumer sweeps at
teardown — this pattern extends discipline #2 to non-referencing permit
surfaces). Signal overlap: [[chrysb-openclaw-agent-failure-modes]] (state
drift as the central agent failure mode — registries drifting from disk
reality is the vault-native instance).
