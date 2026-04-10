---
type: pattern
domain: software
status: active
track: pattern
created: 2026-03-08
updated: 2026-04-04
tags:
  - system-design
  - conventions
  - compound-insight
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Validation Is the Convention Source of Truth

## Pattern

When automated validation (vault-check) and observed practice diverge, the validation defines the convention — not the practice. Fix the practice, or explicitly update the convention with rationale. Never silently weaken validation to accommodate drift.

## Evidence

**tasks.md location (2026-03-08, attention-manager project):**

vault-check enforced `$project_dir/tasks.md` (project root). Newer projects (mission-control, feed-intel-framework, book-scout, attention-manager, and others) placed tasks at `$project_dir/design/tasks.md`. When vault-check flagged this as an error, the fix applied was to make vault-check accept both locations — weakening validation instead of correcting practice or updating the convention.

The permissive fix is pragmatic (many projects already use `design/`) but it obscures the authoritative convention. The correct sequence is:

1. Decide which location is canonical (root or design/)
2. Update the convention doc (file-conventions.md) to state the decision
3. Update vault-check to enforce the decision
4. Migrate existing files if needed

**What went wrong:** Step 1 was skipped. The validation was loosened without a convention decision. This creates ambiguity — future projects don't know which location to use.

## Design Heuristic

1. **vault-check is authoritative.** If vault-check enforces X, then X is the convention until explicitly changed.
2. **Permissive fixes are debt.** Supporting "both A and B" without deciding which is canonical creates drift that compounds over time.
3. **Convention changes require a decision.** When practice has drifted, the operator must decide: revert the practice, or update the convention. Either is fine — but the decision must be explicit and documented.

## Resolution (2026-03-08)

**Decision: tasks.md belongs at project root.** vault-check convention is authoritative.

Actions taken:
- Moved 7 projects' `design/tasks.md` → `tasks.md` (project root)
- Reverted permissive vault-check fix back to strict root-only enforcement
- Markdown table format support in section 10 (active task consistency) retained — that was a genuine parser improvement, not a convention change

## Related

- Behavioral vs. automated triggers: same session, different pattern — both about maintaining system integrity
- Ceremony Budget Principle: convention ambiguity is a form of ceremony (developers must figure out which convention applies)
