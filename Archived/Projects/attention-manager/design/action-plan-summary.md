---
type: summary
project: attention-manager
domain: software
skill_origin: action-architect
source_updated: 2026-03-08
status: active
created: 2026-03-08
updated: 2026-03-08
---

# Attention Manager — Action Plan Summary

## Milestones

| Milestone | Tasks | Risk | Gate |
|---|---|---|---|
| M1: Foundation | AM-001, AM-002 | low | Both artifacts exist, types registered, vault-check passes |
| M2: Skill Build | AM-003 | medium | Skill triggers correctly, produces valid artifacts, carry-forward works |
| M3: Validation | AM-004, AM-005 | medium | 4/5 daily artifacts useful, <5 min/day, monthly review actionable |
| M4: Cleanup | AM-006 | low | Docs updated, no orphans |

## Task Count

6 tasks total: 2 low-risk writing, 2 low-risk code/decision, 2 medium-risk code/decision.

## Dependency Chain

AM-001 and AM-002 are independent (parallel). AM-003 depends on both. AM-004 → AM-005 → AM-006 are strictly sequential.

## Critical Path

M2 (AM-003) is the skill build — medium risk, largest scope. M3 (AM-004) is where design meets reality — 5-day soak with real operator feedback. Everything before M2 is mechanical setup; everything after M3 is documentation.

## Cross-Project

- mission-control (downstream): daily artifact is a planned data source for the web UI attention panel
- customer-intelligence (upstream, soft): dossiers are optional input, graceful degradation applies

## Estimated Scope

- M1: 2 tasks, ~3-4 files each, 1 session
- M2: 1 task, 1 primary file (SKILL.md), 1 session
- M3: 2 tasks, 5+ days calendar time (soak period)
- M4: 1 task, documentation only, 1 session
