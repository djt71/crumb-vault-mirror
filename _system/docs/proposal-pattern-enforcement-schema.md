---
type: proposal
status: draft
domain: software
created: 2026-04-21
updated: 2026-04-21
tags:
  - proposal
  - primitive-creation
  - pattern-enforcement
  - durable-patterns
  - harness
related:
  - _system/docs/tess-v2-durable-patterns.md
  - _system/docs/solutions/behavioral-vs-automated-triggers.md
  - Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md
  - _system/scripts/vault-check.sh
  - _system/scripts/skill-preflight.sh
---

# Proposal: Mechanical Enforcement for Durable Engineering Patterns

## Status

Draft proposal. Not a decision. Operator is thinking on it before
scoping implementation. Requires Primitive Creation Protocol approval
before any changes are made.

## Problem

Amendment AC (2026-04-21) preserved 23 engineering patterns from tess-v2
that apply to any future software system project (contract schema, Ralph
loop, staging/promotion, three-gate escalation, observability design,
etc.). The patterns are findable via `_system/docs/tess-v2-durable-patterns.md`
and partially surfaced via `_system/docs/solutions/` for the three
extracted doctrines.

**Gap:** no mechanism ensures the patterns are actually consulted when
new software systems are designed. Application currently depends on:
(a) operator memory, (b) Claude reading the index unprompted, (c) future
skills invoking them by behavioral instruction.

This is the exact behavioral-trigger anti-pattern the patterns themselves
were built to eliminate (see `solutions/behavioral-vs-automated-triggers.md`
and AD-006 mechanical-enforcement-over-behavioral-compliance). Leaving
their application to behavior is ironic and almost certainly unreliable
over time.

## Operator Constraints

- Operator is not a reliable enforcement mechanism (own admission, 2026-04-21)
- Mechanical enforcement preferred over behavioral instructions
- Ceremony budget principle applies — new primitives must justify against
  maintenance gravity
- Patterns should be consulted at **spec authorship time**, not earlier
  (project creation is too early — nothing has been built yet) and not
  later (by implementation, architectural choices are already made)

## Proposed Mechanism (Two Layers)

### Layer 1 — Spec Schema Enforcement (Mechanical)

Extend the spec frontmatter schema for `type: system` + `domain: software`
projects to require declarations keyed to durable-pattern choices. Enum
values drawn from the durable patterns index.

**Proposed required fields:**

```yaml
execution_model: ralph-loop | claude-code-interactive | cron | event-driven | other
verifiability_tier: V1 | V2 | V3 | mixed
escalation_strategy: three-gate | risk-only | none
state_management: contract-lifecycle | stateless | custom
observability_home: external-logs-symlinked | vault | other
promotion_model: staging-then-promote | direct-write | no-writes
credential_source: keychain-runner-injected | env-vars | vault-references
```

**Enforcement:** `vault-check.sh` validates presence and valid enum values
at commit time. Missing or invalid fields block the commit. The same way
the check currently rejects missing frontmatter or invalid `#kb/` tags.

**Why this forces pattern consultation:** the enum values come *from* the
durable patterns doc. Filling `execution_model: ?` is not possible without
knowing Ralph loop exists as a choice. The schema is the vocabulary;
the vocabulary lives in the patterns index.

### Layer 2 — Skill-Preflight Injection (Support)

When `systems-analyst` or `action-architect` activates on a
software-domain task, `skill-preflight.sh` injects
`tess-v2-durable-patterns.md` as `additionalContext`. Claude has the
vocabulary available for answering the Layer 1 schema fields without
hunting.

This layer is not purely mechanical — it surfaces material but doesn't
force application. Its role is to make compliance cheap. The Layer 1
schema check catches non-compliance.

## Concrete Changes Required

| Change | File | Estimated Effort |
|---|---|---|
| Define the schema fields + enum values | `_system/docs/file-conventions.md` | 30 min |
| Add vault-check rule (new function) | `_system/scripts/vault-check.sh` | 1 hr |
| Update systems-analyst skill to scaffold with new fields | `.claude/skills/systems-analyst/SKILL.md` (+ any templates) | 45 min |
| Update action-architect skill to scaffold with new fields | `.claude/skills/action-architect/SKILL.md` (+ any templates) | 30 min |
| Update preflight hook to inject durable patterns on software-domain skills | `_system/scripts/skill-preflight.sh` | 30 min |
| Update `tess-v2-durable-patterns.md` to link patterns to schema field values | `_system/docs/tess-v2-durable-patterns.md` | 45 min |
| End-to-end test: create a fake software/system project, verify enforcement fires | — | 45 min |
| **Total** | — | **~4.5 hours** |

Single focused session. Not this session.

## Open Questions (operator to decide before implementation)

1. **Scope boundary.** Apply only to `type: system` + `domain: software`?
   Or broader? Narrow is recommended — knowledge-work and personal
   projects don't need this ceremony.

2. **Enum authority.** `tess-v2-durable-patterns.md` becomes the canonical
   source of enum values. Does that elevate its status in ways that feel
   uncomfortable (e.g., making it feel like a "governance" doc that needs
   higher change ceremony)? Or is it fine as a living reference?

3. **Field set completeness.** Are the 7 proposed fields the right cut?
   Too many? Too few? Any patterns that deserve their own field but aren't
   listed (e.g., `cost_model_applied`, `queue_fairness_applied`)?

4. **Grandfathering.** Existing software/system projects (tess-v2,
   feed-intel-framework, etc.) don't have these fields. Apply only to
   projects created after the rule lands? Or retrofit? Recommend:
   grandfather existing, enforce for new.

5. **"Other" escape hatch.** Each enum has `other` as a valid value.
   Prevents blocking legitimate novel patterns. But `other` risks becoming
   a cargo-cult default. Counter-measure: require a `<field>_rationale`
   sibling field when `other` is selected. Mechanical. Worth it?

6. **Doctrine patterns don't fit the schema.** live-soak-beats-benchmark
   and staged-spike-with-bail are judgment doctrines, not architectural
   commitments. Schema enforcement doesn't reach them. Accepted — Layer 2
   preflight injection is their only lever. Flag as known limitation.

7. **Cargo-cult risk.** Someone (or Claude) could fill
   `execution_model: ralph-loop` without actually using a Ralph loop.
   The schema catches declaration, not truth. To catch truth would
   require a separate design-review gate. Probably not worth the
   ceremony. Accept the limitation.

8. **Maintenance load.** When a new pattern emerges (e.g., a future
   project invents a better-than-Ralph execution model), the enum needs
   extending. Same cadence as canonical `#kb/` tag additions. Manageable
   but real.

## Tradeoffs (for operator consideration)

**Pros:**
- Actually mechanical. Enforcement does not depend on operator memory
  or Claude's diligence.
- Consistent with existing vault-check patterns (#kb/ enforcement,
  frontmatter schema, phase gates). No new ceremony shape.
- Reuses preflight hook infrastructure. No new runtime system.
- Forces architectural commitments at the correct phase (SPECIFY),
  which is when they should be made anyway.

**Cons:**
- Schema-level declarations can be cargo-culted. Mechanical but not
  semantic.
- Adds ~7 required fields per new software/system project spec. Real
  overhead.
- Enum maintenance over time (though same cadence as existing canonical
  lists).
- Doesn't reach doctrine patterns.

## Implementation Sequencing (if approved)

**Phase 0 — Resolve open questions.** Operator decides on questions 1-8
above. ~30 min session.

**Phase 1 — Schema + enforcement.** Write the enum in file-conventions.md,
add the vault-check rule, test against fake spec. Merge. ~2 hours.

**Phase 2 — Skill and preflight updates.** Update systems-analyst,
action-architect, and skill-preflight.sh. Verify with a fresh
systems-analyst invocation on a software-domain prompt. ~1.5 hours.

**Phase 3 — Index linkage.** Annotate `tess-v2-durable-patterns.md` with
the schema-field each pattern maps to (e.g., Ralph loop →
`execution_model: ralph-loop`). ~45 min.

**Phase 4 — Retrospective.** After the first new software/system project
is created under the new rule, review whether the mechanism surfaced the
right patterns at the right moments. Adjust enums / fields based on
observation.

## Related

- `Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md` —
  the amendment that preserved the patterns this proposal enforces
- `_system/docs/tess-v2-durable-patterns.md` — the source of the enum
  vocabulary
- `_system/docs/solutions/behavioral-vs-automated-triggers.md` — the
  doctrine this proposal honors
- `_system/docs/file-conventions.md` — where the schema extension lands
- `_system/scripts/vault-check.sh` — where the enforcement rule lands
- `_system/scripts/skill-preflight.sh` — where the injection lands
- CLAUDE.md "Primitive Creation Protocol" — the gate this proposal
  passes through before implementation

## Decision Status

Pending operator reflection. Not scheduled. Not committed to.
