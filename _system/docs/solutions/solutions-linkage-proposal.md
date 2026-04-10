---
type: reference
domain: cross-cutting
status: draft
track: pattern
purpose: Design proposal for Crumb review — fix soft linkage between skills and solutions docs
created: 2026-02-23
updated: 2026-04-04
source: claude-ai peer review session
linkage: discovery-only
tags:
  - kb/software-dev
topics:
  - moc-crumb-operations
---

# Proposal: Mechanical Enforcement of Solutions Doc Loading in Skills

## Problem

The system is good at *capturing* patterns into `_system/docs/solutions/` via compound engineering. It is weak at *consuming* them. The feedback loop is open on the read side.

**Evidence:** Across all 14 skills in `.claude/skills/`, zero have hard-load requirements for solutions docs. Every reference is soft — "if exists, load," "search for relevance," "scan filenames." Whether a relevant solutions doc gets loaded depends on Crumb's in-the-moment judgment, which means it works sometimes and gets skipped sometimes.

Skills affected (those that reference `_system/docs/solutions/` at all):

| Skill | Solutions refs | Load enforcement |
|---|---|---|
| action-architect | 3 | All soft ("search and scan for relevance") |
| systems-analyst | 4 | All soft ("search and scan for relevance") |
| writing-coach | 4 | All soft ("if exists, load") |
| peer-review | 1 | Compound output only (write, no read-back) |
| audit | 6 | Maintenance/consolidation only (no point-of-use loading) |

The remaining 9 skills have zero solutions references — some appropriately (startup, sync, checkpoint), others potentially not (inbox-processor, mermaid, excalidraw, lucidchart).

**Concrete failure mode:** The `ai-telltale-anti-patterns.md` doc exists, the writing-coach skill references it as a conditional load, but there's no enforcement that it actually gets loaded for external-audience writing. Crumb has to already be reading the doc to find the "When to Load" heuristic that says when to load it. The linkage is circular.

## Proposed Fix: Two-Layer Solution

### Layer 1: Skill-Side — `required_context` Field

Add an optional `required_context` field to the skill YAML frontmatter. This declares solutions docs (or other context files) that MUST be loaded when the skill activates under specified conditions.

```yaml
---
name: writing-coach
description: >
  Improve clarity, structure, tone, argument, and brevity of written content.
required_context:
  - path: _system/docs/solutions/writing-patterns/ai-telltale-anti-patterns.md
    condition: audience_external
    reason: "Prevents AI-telltale patterns in deliverables"
  # Future entries as patterns accumulate:
  # - path: _system/docs/solutions/writing-patterns/customer-tone-guide.md
  #   condition: audience_customer
  #   reason: "Customer-specific tone conventions"
---
```

**Field semantics:**

- `path` — Vault-relative path to the solutions doc. MUST exist; skill loading logs a warning if missing (not a hard failure — the doc may have been archived).
- `condition` — When this doc must be loaded. Values are skill-defined strings that the skill's procedure evaluates. Common conditions:
  - `always` — Load on every skill activation. Use sparingly.
  - `audience_external` — Load when the output targets an external audience.
  - `audience_customer` — Load when the output targets a customer.
  - `software_project` — Load when the active project is in the software domain.
  - Skills define their own condition vocabulary in their procedure. The `required_context` field declares the dependency; the skill procedure evaluates the condition.
- `reason` — Human-readable justification. Shown in context inventory log.

**Enforcement point:** Step 1 or 2 of the skill's procedure (context gathering). When a skill activates, it reads its own `required_context` entries, evaluates conditions against the current task context, and loads matching docs. This is a MUST, not a MAY. The context inventory logged to the run-log includes which required_context entries were loaded and which were skipped (with condition evaluation result).

**Context budget interaction:** Required context docs count against the standard context budget (≤5 source docs per skill invocation). If required_context entries would push the skill over budget, the skill logs a warning and prioritizes required_context over discretionary loads. This prevents the mechanism from silently blowing context limits.

### Layer 2: Solutions-Side — `consumed_by` Frontmatter Field

Add an optional `consumed_by` field to solutions doc frontmatter. This declares which skills should load this doc, enabling new patterns to auto-surface without editing skill definitions.

```yaml
---
type: solution
domain: software
status: active
skill_origin: compound
confidence: high
consumed_by:
  - skill: writing-coach
    condition: audience_external
  - skill: systems-analyst
    condition: always
tags:
  - kb/software-dev
---
```

**How it works:** When a skill activates, after checking its own `required_context`, it also checks the solutions directory for any docs with `consumed_by` entries matching the skill name. If found, those docs are loaded under the same condition-evaluation logic.

**This inverts the dependency:** New solutions docs can attach themselves to skills without editing the skill definition. The compound engineering step that creates a solutions doc can set `consumed_by` at creation time — closing the read-back loop in the same step that writes the pattern.

**Precedence:** If the same doc appears in both `required_context` (skill-side) and `consumed_by` (solutions-side), deduplicate — load once. `required_context` takes precedence for condition evaluation if they differ.

### Layer 3: Audit Validation

The audit skill's weekly check gains two new items:

1. **Orphaned solutions check (exists, strengthened):** Solutions docs without either a `consumed_by` field or a corresponding `required_context` entry in any skill are flagged. These are patterns that were captured but have no read-back path — exactly the current failure mode.

2. **Stale linkage check (new):** `required_context` entries pointing to paths that don't exist, or `consumed_by` entries naming skills that don't exist, are flagged for cleanup.

## Migration

This doesn't require a big-bang migration. The rollout is incremental:

**Immediate (this session or next):**
1. Add `required_context` to writing-coach for `ai-telltale-anti-patterns.md` with `condition: audience_external`
2. Add `consumed_by` to `ai-telltale-anti-patterns.md` pointing back to writing-coach
3. Update writing-coach Step 3 to check `required_context` as a MUST, not a MAY

**Next compound cycle:**
4. Add `required_context` to action-architect and systems-analyst for the relevant solutions docs they currently soft-reference
5. Add `consumed_by` to existing solutions docs that have clear skill affinities

**Ongoing:**
6. When compound engineering creates a new solutions doc, set `consumed_by` at creation time
7. Audit skill flags orphaned solutions docs weekly

## What This Does NOT Change

- Solutions docs remain optional for skills that don't need them (startup, sync, checkpoint, etc.)
- The "search and scan" pattern for discovery-oriented skills (action-architect, systems-analyst) remains — `required_context` is for known dependencies, not for exploratory searches
- Context budget rules are unchanged — required_context docs count against the budget
- Compound engineering procedure is unchanged — this only affects the read side, not the write side

## Related

- [[write-read-path-verification]] — General pattern this proposal mechanically enforces for solutions docs. This proposal extends write-read-path-verification §3 by making consumption compliance mechanical via `required_context` and `consumed_by` fields.

## Scope

This is a CLAUDE.md-level convention change (skill frontmatter schema) plus individual skill definition updates. It does not modify the design spec's core architecture. It could be specced as a convention addition to `file-conventions.md` and applied incrementally.

## Decision Points for Crumb

1. **Does `required_context` belong in skill YAML frontmatter, or in the skill body (procedure section)?** Frontmatter is machine-parseable and auditable; procedure-section is more flexible but harder to validate automatically.

2. **Should `consumed_by` scanning happen at skill activation (every time) or be pre-indexed?** Per-activation scanning of the solutions directory is simple but adds I/O on every skill load. Pre-indexing (e.g., a solutions registry file rebuilt by the audit skill) is faster but adds a maintenance artifact.

3. **Condition vocabulary:** Should conditions be standardized across all skills, or skill-defined? Standardized is more auditable; skill-defined is more flexible.
