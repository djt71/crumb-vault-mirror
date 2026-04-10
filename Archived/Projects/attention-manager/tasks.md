---
type: tasks
project: attention-manager
domain: software
skill_origin: action-architect
status: active
created: 2026-03-08
updated: 2026-03-08
---

# Attention Manager — Tasks

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| AM-001 | Create goal-tracker.yaml template and SE inventory template | done | — | low | writing | `_system/docs/goal-tracker.yaml` exists with schema per spec §4.1 (goals array, id/domain/description/horizon/target_date/status/progress fields, header comment); `Domains/Career/se-management-inventory.md` exists with frontmatter (type: reference, domain: career) and 3-category body (recurring/periodic/ad-hoc with cadence annotations); both pass vault-check |
| AM-002 | Register daily-attention and attention-review types; vault-check rules | done | — | low | code | `daily-attention` and `attention-review` appear in file-conventions.md type table; vault-check validates both types (location: `_system/daily/`, required frontmatter: type, status, created, updated, skill_origin); vault-check does not error on `.yaml` files in `_system/docs/`; `_system/daily/` directory exists |
| AM-003 | Build attention-manager skill (daily + monthly procedures) | done | AM-001, AM-002 | medium | code | `.claude/skills/attention-manager/SKILL.md` exists; skill description matches trigger phrases ("plan my day", "daily attention", "monthly review"); daily procedure reads goal-tracker, SE inventory, personal-context, and most recent daily artifact; produces `_system/daily/YYYY-MM-DD.md` with type `daily-attention` passing vault-check; monthly procedure aggregates daily artifacts and produces `_system/daily/review-YYYY-MM.md` with type `attention-review` passing vault-check; carry-forward reads unchecked Focus items from prior artifact within 3-day window; 5-day escalation threshold documented; Life Coach and Career Coach overlays referenced in context contract |
| AM-004 | Dry-run validation — 5 consecutive days with real data | done | AM-003 | medium | decision | 5 daily artifacts exist in `_system/daily/`; operator rates ≥4/5 as "useful"; carry-forward items appear correctly on day 2+; ceremony burden confirmed <5 min/day by operator; any skill adjustments logged in run-log |
| AM-005 | Monthly review validation | done | AM-004 | low | decision | `_system/daily/review-YYYY-MM.md` exists; contains ≥2 actionable observations; contains ≥1 goal-tracker update proposal; skill does not exceed extended-tier context budget (7-8 docs) |
| AM-006 | Documentation and cleanup | done | AM-005 | low | writing | Progress-log summary covers full project lifecycle; no orphan scratch artifacts in `_system/daily/` from dry-run; CLAUDE.md reviewed — updated only if attention-manager conventions warrant |
