---
type: action-plan
project: attention-manager
domain: software
skill_origin: action-architect
status: active
created: 2026-03-08
updated: 2026-03-08
---

# Attention Manager — Action Plan

## M1: Foundation

Create the prerequisite artifacts and register new types so the skill has something to read and validate against. AM-001 and AM-002 are independent — execute in parallel.

### AM-001: Create prerequisite artifact templates

Create `_system/docs/goal-tracker.yaml` with schema per spec §4.1 (YAML, 3-5 goals max, id/domain/description/horizon/target_date/status/progress fields, header comment documenting review cadence and hard cap). Create `Domains/Career/se-management-inventory.md` with frontmatter and three-category body structure per spec §4.2 (recurring with cadence annotations, periodic, ad-hoc). Populate both with realistic example data — the operator will replace with real data before AM-004.

### AM-002: Register types and vault-check rules

Add `daily-attention` and `attention-review` to the type taxonomy in `_system/docs/file-conventions.md`. Add vault-check rules for both: validate location (`_system/daily/`), required frontmatter fields (`type`, `status`, `created`, `updated`, `skill_origin`). Verify vault-check handles `.yaml` files in `_system/docs/` — goal-tracker.yaml is the first non-markdown file in that directory. Create `_system/daily/` directory with a `.gitkeep`.

**M1 success criteria:** Both prerequisite files exist and pass vault-check. Both new types are registered. `_system/daily/` directory exists.

---

## M2: Skill Build

Build the attention-manager skill. This is the core deliverable — the skill that reads input sources, applies overlays, and produces daily attention artifacts.

### AM-003: Build attention-manager skill

Write `.claude/skills/attention-manager/SKILL.md` implementing:

**Daily procedure (9 steps):** Context contract loading (goal-tracker, SE inventory, personal-context, most recent daily artifact within 3 days), active project scan (project-state.yaml `next_action` extraction), SE cadence scan (cadence annotations vs. completion history), goal-tracker scan (active goals, staleness check at 45 days), carry-forward processing (unchecked items, 3-day window, 5-day escalation), prioritization through Life Coach + Career Coach lenses, curation (5-8 items, domain balance check, optional goal references), artifact write, operator presentation.

**Monthly procedure (8 steps):** Pre-processing aggregation of daily artifacts into structured summary digest (domain counts, carry-forward patterns, goal references, completion rates), digest + goal-tracker + SE inventory loading, analysis, Life Coach lens, Career Coach lens, review artifact write, goal-tracker update proposal, operator presentation.

**Context contract:** MUST-load docs, overlay co-firing, mechanical scan for project states, budget tiers (standard for daily, extended for monthly).

**M2 success criteria:** Skill triggers on "plan my day" and "monthly review". Daily procedure produces a `daily-attention` artifact passing vault-check. Monthly procedure produces an `attention-review` artifact passing vault-check. Carry-forward mechanics correctly read unchecked items from prior artifact within 3-day window.

---

## M3: Validation

Real-world validation with operator feedback. AM-004 is the critical gate — this is where the design meets reality.

### AM-004: Dry-run validation (5 days)

Run the skill daily for 5 consecutive days with real data (operator must populate goal-tracker and SE inventory before starting). After each daily artifact, collect operator feedback: was the curation useful? Was anything important missing? Was the ceremony burden acceptable? Adjust skill procedure based on findings. Track carry-forward accuracy across the 5 days.

### AM-005: Monthly review validation

Run the monthly review procedure on the dry-run data (even though it's <1 month of data, the procedure should degrade gracefully). Assess: synthesis quality, goal alignment signal, actionable adjustments proposed.

**M3 success criteria:** Operator rates ≥4/5 daily artifacts as "useful". Ceremony burden confirmed <5 min/day. Monthly review produces ≥2 actionable observations and ≥1 goal-tracker update proposal. Carry-forward accuracy validated across consecutive days.

---

## M4: Cleanup

### AM-006: Documentation and cleanup

Update CLAUDE.md if attention-manager conventions warrant a reference. Clean up any scratch artifacts from the dry-run period. Write progress-log summary closing out the project.

**M4 success criteria:** Progress log summary written. No orphan scratch artifacts. CLAUDE.md reviewed (updated only if warranted).

---

## Dependency Graph

```
AM-001 ──┐
          ├──▶ AM-003 ──▶ AM-004 ──▶ AM-005 ──▶ AM-006
AM-002 ──┘
```

## Cross-Project Notes

- **mission-control (downstream):** The daily attention artifact (`_system/daily/YYYY-MM-DD.md`) is a planned data source for the Mission Control web UI. The artifact schema is provisional (spec C6) — mission-control should validate the schema when it builds the attention panel. This is an informational dependency, not a blocker.
- **customer-intelligence (upstream, soft):** The skill MAY load customer dossiers for career-domain specificity. Graceful degradation applies — the skill works without them.
