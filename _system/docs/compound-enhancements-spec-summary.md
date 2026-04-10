---
type: specification-summary
domain: software
skill_origin: systems-analyst
status: active
created: 2026-04-04
updated: 2026-04-04
source_updated: 2026-04-04
tags:
  - compound-engineering
  - code-review
  - system-enhancement
---

# Compound Engineering Enhancements — Summary

Three amendments to existing Crumb artifacts, adapted from EveryInc compound-engineering-plugin:

1. **Track-based learning schema** — Add `track: bug | pattern | convention` to solution
   doc frontmatter with standardized body sections per track. Migrate all 17 existing docs.
   Amends: spec §4.4, file-conventions.md, vault-check.sh.

2. **Conditional review routing** — Analyze diff for signals (security, schema, API,
   config, shell) before assembling the review prompt. Same two reviewers, tailored emphasis.
   Amends: code-review SKILL.md (new Step 4b, modified Step 5).

3. **Finding cluster analysis** — Group 3+ findings with shared root cause into systemic
   findings with single action items. Individual findings preserved as sub-items.
   Amends: code-review SKILL.md (new Step 7b, enhanced synthesis structure).

**Execution:** Spec amendments + skill updates, not a formal project. 10 tasks (CE-001
through CE-010). Enhancements are independently shippable. Track schema first, then
routing, then clustering.

**Risks:** Medium for track schema migration (17 file changes); low for routing and
clustering (additive, no behavior change at zero signal/cluster).
