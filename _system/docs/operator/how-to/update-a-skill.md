---
type: how-to
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# How to Update a Skill

**Problem:** A skill's behavior needs changing — new steps, modified triggers, updated context requirements, or bug fixes in the procedure.

**Architecture source:** [[skills-reference]], [[05-cross-cutting-concepts]] §vault-check

---

## Prerequisites

- Active Crumb session
- Know which skill to update (see [[skills-reference]] for the full roster)

---

## Steps

### 1. Read the Current SKILL.md

```
Read .claude/skills/<skill-name>/SKILL.md
```

Understand the current structure: frontmatter (name, description, model_tier, required_context), context contract, and procedure.

### 2. Make the Edit

Edit the SKILL.md file. Key sections to modify:

| Section | When to Change |
|---------|---------------|
| `description` | Trigger phrase matching needs adjustment |
| `model_tier` | Delegation behavior should change (execution↔reasoning) |
| `required_context` | New documents needed before execution, or old ones removed |
| Context Contract | Input/output files or budget changed |
| Procedure steps | Workflow logic needs updating |

**Constraints:**
- Code blocks in procedures are templates/patterns, not standalone scripts — Claude implements them at execution time
- Keep procedures under the nine-section structure (frontmatter, description, context contract, procedure, etc.)
- Don't add overlay check steps unless the skill genuinely needs domain-specific lenses

### 3. Run vault-check

vault-check validates skill files as part of the primitive registry check (§28). Verify:

```bash
git add .claude/skills/<skill-name>/SKILL.md
git commit  # pre-commit hook runs vault-check
```

If vault-check fails, fix the issue and try again.

### 4. Verify AKM Pickup

After committing, the skill-preflight hook (`_system/scripts/skill-preflight.sh`) will use the updated SKILL.md on the next skill activation. Verify by triggering the skill in a subsequent session or later in the current session.

### 5. Log the Change

Note the skill update in the active run-log or session-log:
- What changed and why
- Whether model_tier or required_context changed (affects cost routing)

---

## Peer Review (if substantial)

For significant skill changes (new procedure steps, changed inputs/outputs, model tier changes), consider running the peer-review skill on the updated SKILL.md before committing. This catches issues that vault-check can't (logical errors, missing edge cases, stale references).

---

**Done criteria:** SKILL.md updated, vault-check passes, committed. Skill activates correctly on next trigger.
