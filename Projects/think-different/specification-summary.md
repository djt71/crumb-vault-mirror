---
project: think-different
domain: learning
type: summary
skill_origin: systems-analyst
status: active
created: 2026-02-17
updated: 2026-02-17
source_updated: 2026-02-17
tags:
  - summary
  - think-different
---

# Think Different — Specification Summary

## What
Comprehensive vault-native reference on Apple's "Think Different" campaign (1997–2002):
full campaign history, deep intellectual profiles of all 44 real personalities featured,
thematic synthesis, and a master roster.

## Deliverables
1. **campaign-history.md** — Apple's 1997 crisis, TBWA\Chiat\Day, creative development, TV/print campaign, legacy
2. **profiles/[name].md** (×44) — Biography, philosophy, major works, Think Different connection, quotes
3. **profiles/flik.md** — Pixar promotional tie-in note
4. **synthesis.md** — Cross-cutting themes and philosophical patterns across all personalities
5. **roster.md** — Quick-reference table linking to all profiles

## Key Decisions
- One file per person in `profiles/` subdirectory
- Full intellectual depth: worldview, philosophy, not just biographical highlights
- All profiles tagged `#kb/history` for knowledge base discovery
- 45 confirmed figures (44 real people + Flik); sourced from TV spot, 5 print sets, Educator series
- Three-phase workflow (SPECIFY → PLAN → ACT) — learning domain

## Acceptance Criteria
1. Campaign history covers all scoped sections
2. 44 profile files exist, each with 5 required sections
3. Synthesis identifies ≥4 cross-cutting themes with examples
4. Roster links to every profile
5. Valid frontmatter and tags on all files; vault-check clean
