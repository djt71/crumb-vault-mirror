---
type: solution
domain: software
status: active
track: convention
created: 2026-02-24
updated: 2026-04-04
skill_origin: compound
confidence: high
topics:
  - moc-crumb-operations
tags:
  - kb/software-dev
  - knowledge-management
  - workflow
---

# Archive Conventions

Patterns for archiving projects cleanly and reopening them when needed.
Applies to all project types (four-phase software, three-phase knowledge,
two-phase personal).

## Pre-Archive Checklist

Advisory, not a gate. The checklist forces explicit acknowledgment and recording
of the project's state at archival. It does not prevent archival with gaps — it
makes the gaps visible so the decision is reversible and the reopening cost is
known.

Run this checklist during the archive confirmation flow. Record the output as a
structured block in the final run-log entry, co-located with the archive decision.

### The Six Checks

**1. Acceptance criteria audit**

For each task in the project: met, partially met, or waived? Partially met and
waived items require a one-line justification.

Format in run-log:
```
Acceptance: 5/7 met, 1 partial (NLM-003: 2/6 fixtures filled — deferred remaining
source types), 1 waived (NLM-005: 1/5 e2e runs — pipeline functional, full coverage
deferred)
```

**2. Fixture / validation coverage**

What was planned vs. what was actually tested? Express as a ratio. If coverage
is below the plan, state what's untested and the risk of that gap.

Format in run-log:
```
Validation: 2/6 fixture slots filled (both books, copy-paste path). Untested:
article, podcast, video, messy export, Chrome extension path. Risk: parser may
fail on non-book source types or extension export formatting.
```

**3. Deferred items inventory**

List everything consciously deferred. Classify each as:
- **Won't-do:** Nice to have, not pursuing. (Clean — no reopening risk.)
- **Someday:** Needed but not urgent. (Mild risk — may never happen.)
- **Needed-next:** Required for full utility, just not now. (Signal that archival
  may be premature — record why you're archiving anyway.)

The **needed-next** category deserves extra scrutiny. If most deferred items are
needed-next, consider whether the project should stay active with a parked status
rather than archiving.

**4. Deliverable location audit**

Are durable deliverables in their permanent locations? Can someone find and use
the outputs without reading the project history?

Check:
- Templates, skills, reference docs promoted out of project directory
- No orphaned deliverables still in project/design/ or project/progress/
- Wikilinks from other vault notes point to promoted locations, not project paths

**5. Reopening cost estimate**

If you had to reopen this in 3 months, how much context reconstruction would
be needed?

- **Low:** Deliverables are self-contained. Reopening = read the deliverables +
  enhancement scope. (Clean archive.)
- **Medium:** Need to re-read the spec to understand design decisions. (Acceptable
  — most projects land here.)
- **High:** Need to re-read spec + run-log + reconstruct decisions that aren't
  documented anywhere. (Smell. Either document the missing context before archiving,
  or don't archive yet.)

**6. KB exception check**

Does this project contain standalone knowledge artifacts that should stay in the
active graph? If yes, use the KB exception path (project stays in Projects/ with
phase: ARCHIVED) per CLAUDE.md.

### Example: Complete Checklist Block

```markdown
### Archive Checklist — 2026-02-20

- **Acceptance:** 5/7 met, 1 partial (NLM-003: 2/6 fixtures), 1 partial (NLM-005: 1/5 e2e)
- **Validation:** 2/6 fixtures (both books, copy-paste). Untested: article, podcast,
  video, messy export, Chrome extension path
- **Deferred:**
  - Domain backlinks to MOC — someday (v2 with MOC system)
  - Batch metrics — won't-do (low value without scale)
  - URL normalization — needed-next (affects dedup for web sources)
  - Media-specific frontmatter — needed-next (timestamp handling untested)
  - Remaining fixtures — needed-next (parser untested on non-book sources)
- **Deliverables:** Templates promoted to _system/docs/templates/notebooklm/.
  Sentinel contract in place. Inbox-processor skill updated. Workflow guide linked
  from learning-overview.
- **Reopening cost:** Low — deliverables self-contained, spec available for reference
- **KB exception:** No — no standalone KB artifacts
```

## Maintenance Reopening Pattern

When enhancement work targets an archived project's existing deliverables without
changing the architecture, reopen the project rather than creating a new one.

### Decision Framework

**Reopen when:**
- You're revising existing deliverables in their current locations
- The original architectural decisions still hold
- No new dependencies or interfaces are introduced
- The work is naturally described as "make the existing thing better"

**New project when:**
- New infrastructure, new architecture, or new interfaces
- The scope has grown beyond the original project's purpose
- The work would confuse the original project's run-log narrative
- Use `related_projects` in project-state.yaml to link back

**The test:** If someone reads the original project's run-log, would the new work
feel like a continuation or a tangent? Continuation = reopen. Tangent = new project.

### Reopening Procedure

1. Reactivate the project per CLAUDE.md (move back from Archived/, restore phase
   from phase_before_archive, update companion note paths, vault-check, commit)
2. Add a run-log entry documenting the maintenance scope — what's being enhanced
   and why. Reference the original archive checklist if gaps are being closed.
3. Add an enhancement spec as a design artifact (permitted under the maintenance
   carve-out in Completed Project Guard)
4. Execute the work
5. Run the pre-archive checklist again before re-archiving

### What Makes This Work

The pattern depends on durable deliverables being in stable, permanent locations
outside the project directory. If templates, skills, and reference docs were still
inside the project directory when it archived, reopening is straightforward. If
they were promoted to `_system/` or other durable locations (as they should be),
the project directory is just coordination artifacts (specs, run-logs, plans) and
the deliverables are already where they need to be.

This is why check #4 (deliverable location audit) matters at archival time — it's
what makes future reopening cheap.
