---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Project Specification & Planning

Covers the SPECIFY → PLAN transition for formal projects: turning a vague problem into an approved spec, then decomposing that spec into an executable task breakdown.

## Skills in This Workflow

### /systems-analyst
**Invoke:** describe the problem or goal; Claude auto-loads when analysis/spec work is detected
**Inputs:** problem statement or goal, domain context (domain summary if it exists)
**Outputs:** `specification.md`, `specification-summary.md` in `Projects/[name]/design/`
**What happens:**
- Asks ≤5 clarifying questions, then produces problem statement, facts/assumptions/unknowns, system map, and task decomposition
- Classifies domain and recommends workflow depth (2-, 3-, or 4-phase)
- Offers peer review for major specs; minor specs get no mention

### /action-architect
**Invoke:** after spec is approved; triggers on "break this down", "create tasks", "what's the plan"
**Inputs:** approved `specification-summary.md`; for software projects, also design summaries + targeted reads of Constraints/Requirements/Interfaces sections
**Outputs:** `action-plan.md`, `action-plan-summary.md`, `tasks.md` in `Projects/[name]/`
**What happens:**
- Defines milestones (H2) and phases (H3) with success criteria and dependency mapping
- Decomposes into atomic tasks scoped to ≤5 file changes each, each with binary acceptance criteria and risk level
- Offers peer review for high-impact plans; logs estimate data to `_system/docs/estimation-calibration.md`

## Typical Flow

```
systems-analyst (SPECIFY phase)
  → specification.md + specification-summary.md
  → user reviews and approves
  → [optional peer review for major specs]

action-architect (PLAN phase)
  → action-plan.md + tasks.md + summaries
  → user reviews and approves
  → [optional peer review for high-impact plans]

→ TASK phase (task-by-task execution)
→ IMPLEMENT phase (software only)
```

Both skills load `_system/docs/overlays/overlay-index.md` and activate matching overlays automatically. Both check `_system/docs/solutions/` for prior art before proceeding.
