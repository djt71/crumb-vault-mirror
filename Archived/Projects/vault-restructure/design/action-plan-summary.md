---
type: summary
project: vault-restructure
domain: software
status: active
created: 2026-02-20
updated: 2026-02-20
source_doc: Projects/vault-restructure/design/action-plan.md
source_updated: 2026-02-20
skill_origin: action-architect
tags:
  - summary
---

# Action Plan Summary — vault-restructure

**18 tasks across 5 milestones. Estimated 4.5-5.5 hours.**

## Milestones

1. **Phase 0 — Pre-Flight** (7 tasks, ~30 min, low risk): Cleanup, metadata, reference notes,
   external tooling inventory, breakable link fixes. No directory moves.

2. **Phase 1 — docs/ → _system/docs/** (6 tasks, ~2.5 hrs, high risk): Largest phase.
   Update 29 external files + 162-ref spec (two-pass with manual review) + internal
   self-references. One atomic commit with secondary verification.

3. **Phase 1B — Spec v1.8** (1 task, ~30 min, medium risk): Version bump, diagram update,
   file rename. Separate commit from Phase 1 for clean diff.

4. **Phase 2 — scripts/ → _system/scripts/** (2 tasks, ~45 min, high risk): VAULT_ROOT
   depth fix + hook migration. SessionStart hook is the critical constraint.

5. **Phase 3 — reviews/ → _system/reviews/** (2 tasks, ~30 min, low risk): Smallest scope.
   Peer-review skill is the main consumer.

## Key Risks

- **Phase 1 spec manual pass** (VRS-011): 162+ refs, must distinguish live paths from
  historical prose. Decision rule defined; 30-min timebox.
- **Phase 2 hook migration** (VRS-016): SessionStart hook breakage locks out Claude Code.
  Rollback: edit settings.json from terminal.
- **Circular validation** (VRS-013): vault-check.sh modified in same phase it validates.
  Mitigated by secondary verification (test -f, bash -n).

## Dependencies

Phase 0 tasks are independent (gated by commit VRS-007). Phase 1 update tasks are
independent (gated by move+commit VRS-013). Milestones 3-5 are strictly sequential.
Phase 4 (logs) deferred — revisit after 1 week of daily use.
