---
type: solution
domain: software
status: active
track: pattern
created: 2026-02-22
updated: 2026-04-04
skill_origin: compound
confidence: high
tags:
  - kb/software-dev
  - infrastructure
  - knowledge-management
topics:
  - moc-crumb-operations
---

# Write-Read Path Verification

When building infrastructure that persists knowledge artifacts, verify the read
path exists — not just the write path.

## The Pattern

The write side of a knowledge pipeline is always the obvious part. It gets built
because it's the natural output of the workflow that produces the artifact. The
read side — where a downstream consumer actively searches for and loads the
artifact — is where things silently break. Artifacts accumulate without being
consumed, and the gap only surfaces when someone notices the knowledge isn't
influencing decisions.

**Rule:** Any time compound engineering (or any process) routes artifacts to a
new destination, verify that at least one downstream workflow actively searches
that destination during its context-gathering phase.

## Checklist

1. Identify the write path: what workflow produces the artifact, and where does
   it land?
2. Identify all intended consumers: which skills, phases, or workflows should
   find and use this artifact?
3. For each consumer, verify an **active search step** exists — a grep, glob,
   or query that targets the destination directory/tag. Passive availability
   (the file exists if you know where to look) is not sufficient.
4. If no active search step exists, add one to the consumer's context-gathering
   phase before declaring the pipeline complete.

## Evidence

Derived from `_system/docs/solutions/` gap discovered in crumb-tess-bridge
Session 31 (2026-02-22). Compound engineering faithfully wrote patterns to the
solutions directory per spec §4.4, but neither systems-analyst nor
action-architect searched the directory during SPECIFY or PLAN. The directory
accumulated 6 solution docs over weeks before the read gap was identified.

**Fix applied:** Active search steps added to systems-analyst Step 1 ("Search
for prior art") and action-architect Step 1 ("Search for implementation
patterns").

**First test of closed loop:** researcher-skill's SPECIFY phase — the first
project to enter SPECIFY after the retrieval fix was applied.

## Applicability

This pattern applies to any system that:
- Persists knowledge artifacts (solution docs, pattern libraries, calibration
  data, failure logs) to a known location
- Expects downstream workflows to benefit from those artifacts
- Does not have a push/notification mechanism (artifacts sit until pulled)

It generalizes beyond Crumb: any knowledge management system where "we wrote it
down" is confused with "it will be found when needed."

## Related

- [[solutions-linkage-proposal]] — Proposes mechanical enforcement of this pattern specifically for solutions docs, via `required_context` and `consumed_by` fields in skill/solution frontmatter.
