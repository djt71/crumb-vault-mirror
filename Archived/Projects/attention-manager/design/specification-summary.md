---
project: attention-manager
domain: software
type: summary
skill_origin: systems-analyst
source_updated: 2026-03-06
created: 2026-03-06
updated: 2026-03-06
status: active
tags:
  - attention-management
  - system-design
---

# Attention Manager — Specification Summary

## Problem

Danny's attention is fragmented across competing demand streams with no unified mechanism for deciding what gets daily focus. No existing morning planning ritual, no goal-setting practice, SE management tasks scattered across calendar/memory/notes. Result: reactive days where urgency wins over importance.

Governing principle: "I run the 24 hours. The 24 hours doesn't run me."

## Solution Shape

A Crumb skill that reads from multiple vault sources (goal-tracker, SE inventory, project states, customer dossiers, personal-context), applies Life Coach + Career Coach overlay lenses, and produces a curated daily attention artifact — an opinionated short list of 5-8 checkbox items with reasoning, domain balance assessment, carry-forward tracking, and goal alignment.

## Key Design Decisions

1. **Ownership split:** Crumb reasons, operator reviews (<5 min), future web UI delivers. Tess delivery is a separate workstream.
2. **Goal tracker:** Pure YAML at `_system/docs/goal-tracker.yaml`. 3-5 active goals max, monthly/quarterly horizons, free-text progress. No nested milestones. Staleness check at 45 days.
3. **SE inventory:** Static reference doc at `Domains/Career/se-management-inventory.md`. Three categories (recurring, periodic, ad-hoc). No checkboxes — skill infers "due" from cadence annotations + daily artifact completion history.
4. **Daily artifact:** `_system/daily/YYYY-MM-DD.md`. Type `daily-attention`. Checkbox-style Focus items. 90-day retention.
5. **Monthly review:** `_system/daily/review-YYYY-MM.md`. Separate type `attention-review`. Pre-processes daily artifacts into summary digest before loading.
6. **Cadences:** Daily curation + monthly review. Weekly deferred (validate need after first month).
7. **Interaction:** On-demand ("plan my day"), not auto-generated at session start.
8. **Carry-forward:** Finds most recent artifact within 3 days, rolls unchecked items with counter, escalates at 5 days. Gaps >3 days produce fresh lists.
9. **Overlay co-firing:** Life Coach (values, whole-person, sustainability) + Career Coach (skill leverage, relationship capital, opportunity cost).
10. **Calendar:** Out of scope (violates C2). Operator merges calendar during <5 min review.
11. **Priority heuristic:** Non-negotiable commitments always included. Discretionary items biased toward external visibility/time decay.

## Prerequisites

- `_system/docs/goal-tracker.yaml` — Crumb creates template, operator populates with real goals
- `Domains/Career/se-management-inventory.md` — Crumb creates template, operator populates with real SE obligations
- `daily-attention` and `attention-review` types registered in file-conventions.md + vault-check

## Tasks (6)

| ID | Description | Risk | Dependencies |
|---|---|---|---|
| AM-001 | Create prerequisite artifacts (goal-tracker, SE inventory templates) | low | — |
| AM-002 | Register daily-attention + attention-review types (file-conventions, vault-check, directory) | low | — |
| AM-003 | Build attention-manager skill | medium | AM-001, AM-002 |
| AM-004 | Dry-run validation (5 days real use) | medium | AM-003 |
| AM-005 | Monthly review validation | low | AM-004 |
| AM-006 | Documentation and cleanup | low | AM-005 |

## Key Constraints

- Ceremony budget: <5 min operator time per day
- No new infrastructure — vault notes + Crumb skill only
- Graceful degradation — works with partial inputs
- Human override — artifact is a proposal, not a contract
- Write-read path: only verified consumer is operator-in-vault; schema provisional until second consumer validates
- Calendar out of scope — operator merges calendar during review

## Overlays Applied

- **Life Coach:** values alignment, whole-person impact, "enough" test, library grounding
- **Career Coach:** skill leverage, relationship capital, opportunity cost

## Peer Review Status

6-reviewer peer review completed (GPT-5.2, Gemini 3 Pro, DeepSeek V3.2, Grok 4.1, Claude, Perplexity). All must-fix and should-fix items applied. See `reviews/2026-03-06-specification.md`.
