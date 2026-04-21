---
project: null
domain: software
type: reference
skill_origin: null
status: draft
created: 2026-02-17
updated: 2026-02-19
tags:
  - skill-authoring
  - crumb
---

# Skill Authoring Conventions for Crumb

**Status:** Draft — for review and potential incorporation into Crumb design spec
**Derived from:** Fabric pattern structure conventions (danielmiessler/fabric, 251 patterns, 200+ contributors, 3,500+ commits), adapted for Crumb's stateful, vault-integrated skill system.

---

## Why This Exists

Crumb's design spec prescribes skill file location (`.claude/skills/[name]/SKILL.md`), frontmatter schema, and what a skill should contain (procedure, context contract, compound behavior, convergence dimensions). But it doesn't prescribe a rigid **internal section structure** for the skill body itself. The existing skills in the spec are well-written but follow slightly different organizational patterns from each other.

Fabric's pattern format has been refined by hundreds of contributors across 3,500+ commits. Their section conventions — identity, steps, output constraints, input handling — represent battle-tested prompt engineering. This document adapts those conventions to Crumb's richer skill model (which includes vault integration, overlays, context contracts, and compound engineering that Fabric patterns don't have).

The goal: a consistent, predictable structure that makes skills easier to write, easier for Claude to parse, and easier to audit.

---

## The Structure

Every SKILL.md follows this section order. Sections marked **(required)** must be present in every skill. Sections marked **(when applicable)** are included only when relevant.

```
---
YAML frontmatter (required)
---

# Skill Name (required)

## Identity and Purpose (required)

## When to Use This Skill (required)

## Procedure (required)

## Prerequisites (when applicable)

## Context Contract (required)

## Output Constraints (when applicable)

## Output Quality Checklist (required)

## Compound Behavior (required)

## Convergence Dimensions (required)
```

---

## Section Details

### YAML Frontmatter (required)

Unchanged from current spec. This is what Claude Code uses for routing.

```yaml
---
name: skill-name-kebab-case
description: >
  One to three sentences. First sentence states what the skill does.
  Remaining sentences list trigger phrases and routing keywords.
  This description is what Claude Code's skill matcher reads — write it for the matcher, not for humans.
---
```

**Convention:** The `description` field is a routing document. Front-load the capability statement, then list trigger phrases. Don't waste words on context that only matters inside the procedure.

**Model tier:** The optional `model_tier` field is a routing hint — it tells the session which model class the skill's work warrants, not which exact model to use. Skills declare *what kind of work* they do (`reasoning` or `execution`); the concrete model mapping lives in CLAUDE.md. This keeps skill definitions model-agnostic.

**Optional routing fields** (include when relevant):

| Field | Values | When to use |
|---|---|---|
| `model_tier` | `reasoning`, `execution` | Declares the cognitive tier the skill's work requires. Use `execution` for procedural/mechanical skills (file processing, templating, CLI utilities, diagram generation); `reasoning` for analytical/evaluative skills (specification, design, review, coaching). Omit to inherit session default. See CLAUDE.md Model Routing for delegation behavior. |
| `context` | `main` | Skill runs in main session context (default behavior — include for clarity on skills that make external API calls or need full tool access) |
| `allowed-tools` | Comma-separated tool names | Declares which Claude Code tools the skill uses. Include when the skill requires specific tools (e.g., Bash for API calls) |
| `user-invocable` | `true` | Skill can be triggered by name as a slash command. Include for utility skills the user calls directly (e.g., `/meme-creator`) |

These fields emerged from utility and integration skills (peer-review, meme-creator). They are not required for standard workflow skills.

---

### Identity and Purpose (required)

*Adapted from Fabric's `# IDENTITY and PURPOSE`*

Two to four sentences that establish:
1. **What you are** — the role or expertise this skill embodies
2. **What you produce** — the primary output
3. **What you protect against** — the failure mode this skill prevents (if applicable)

This section primes Claude's behavior before it reads the procedure. It's not a repeat of the frontmatter description — it's a framing statement that shapes how Claude interprets everything that follows.

**Example (systems-analyst):**
```markdown
## Identity and Purpose

You are a systems analyst who transforms vague problems and goals into structured,
actionable specifications. You produce specifications that serve as the foundation
for all downstream work — design, planning, and implementation all flow from your
output. You protect against premature implementation by ensuring problems are
properly understood before solutions are proposed.
```

**Example (writing-coach):**
```markdown
## Identity and Purpose

You are a writing editor who improves clarity, structure, tone, and brevity while
preserving the author's voice. You produce revised text with explanations of
significant changes. You protect against unclear communication by catching
ambiguity, weak structure, and unnecessary complexity.
```

**What NOT to do:**
- Don't list trigger phrases here (that's frontmatter's job)
- Don't describe the procedure (that's the next section's job)
- Don't include motivational language ("Take a step back and think step by step") — Crumb skills operate inside Claude Code with extended thinking; you don't need to prompt for reasoning

---

### When to Use This Skill (required)

*Corresponds to current spec's "When to Use" section*

Bulleted list of activation conditions. These complement the frontmatter description — frontmatter is for the routing matcher, this section is for Claude's judgment when multiple skills could match.

```markdown
## When to Use This Skill

- Starting a new project in any domain
- User presents an ambiguous or unclear request
- Need to clarify scope, constraints, and success criteria
- User explicitly asks for analysis, specs, or problem breakdown
```

Keep it concrete. "User presents an ambiguous request" is actionable. "When analysis is needed" is too vague to disambiguate from other skills.

---

### Procedure (required)

*Adapted from Fabric's `# STEPS`, extended for Crumb's stateful model*

The numbered steps Claude follows to execute this skill. This is the core of the skill and the section that distinguishes Crumb skills from Fabric patterns.

**Key differences from Fabric:**
- Fabric steps are stateless: process input → produce output. Crumb steps interact with the vault, check overlays, manage context budgets, and produce persistent artifacts.
- Fabric steps don't reference external state. Crumb steps read summaries, search tags, and check for existing patterns before doing new work.
- Fabric steps are one-shot. Crumb steps include compound checks that feed the learning system.

**Code blocks are templates, not scripts:** Procedure steps may include bash/curl/Python code blocks as reference patterns showing the *shape* of what to execute — correct commands, parameter names, JSON structures, API endpoints. Claude implements these at execution time, adapting to runtime context (e.g., adding retry loops, adjusting paths, handling errors). Code blocks in a skill procedure are not standalone scripts and are not expected to run verbatim. This is a deliberate consequence of Option A (pure skill, no helper scripts): the skill describes *what* to do precisely enough that Claude can execute it reliably, without maintaining a separate script. If execution drift becomes a problem across 5+ invocations, that's a transition signal for Option B (extract a helper script).

**Conventions:**
1. Number the steps sequentially
2. Each step starts with a verb (Gather, Check, Clarify, Analyze, Create, Write)
3. Steps that interact with the vault specify the file paths or CLI commands
4. The final step is always either a compound check or a handoff instruction
5. Keep the procedure to 4-8 steps for most skills. If you need more, the skill may be doing too much — consider splitting

**Example:**
```markdown
## Procedure

### 1. Gather Context

Read relevant context before beginning analysis:
- If project exists: read `Projects/[project]/specification-summary.md`
- If domain-specific: read `Domains/[domain]/[domain]-summary.md`
- Search for related patterns: tag-based search for relevant solution docs

### 2. Check Overlay Index

Compare the current task against activation signals in `_system/docs/overlays/overlay-index.md`.
If any overlays match, load them — their lens questions apply alongside subsequent steps.

### 3. Clarify Through Questions
...

### 4. Conduct Analysis
...

### 5. Create Summary
...

### 6. Compound Check

If this problem shape recurs or reveals a reusable pattern, route the insight
per compound step protocol (§6 of the design spec).
```

---

### Prerequisites (when applicable)

*Crumb-specific — no Fabric equivalent (Fabric patterns have no external dependencies)*

System tools, libraries, credentials, or OS-specific requirements the skill needs before it can run. Include this section when the skill depends on anything beyond Claude Code's built-in tools.

```markdown
## Prerequisites

- Python 3 with Pillow: `pip3 install Pillow`
- TMDB API token: `~/.config/meme-creator/tmdb-api-key`
- Impact font: `/System/Library/Fonts/Supplemental/Impact.ttf` (macOS)
```

**When to include:** Skills that call external APIs (peer-review), use CLI tools (inbox-processor uses MarkItDown), or require specific libraries (meme-creator uses Pillow). Standard vault-only skills don't need this section.

**Convention:** List each dependency on its own line with the install command or expected path. If a dependency is managed by `_system/scripts/setup-crumb.sh`, note that.

---

### Context Contract (required)

*Crumb-specific — no Fabric equivalent*

Unchanged from current spec. Defines what context this skill needs, may request, and should avoid loading.

```markdown
## Context Contract

**MUST have:**
- User's current prompt (problem/goal description)
- Relevant domain summary if it exists

**MAY request:**
- Previous specification-summary for this project (if iterating)
- Related problem-pattern docs via tag-based search

**AVOID:**
- Raw code or implementation details
- Unrelated project histories
- Full design documents (use summaries)

**Typical budget:** Standard tier (2-4 docs). Extended tier (6-7 docs) for
iteration passes — log justification in context inventory.
```

---

### Output Constraints (when applicable)

*Adapted from Fabric's `# OUTPUT INSTRUCTIONS`*

Explicit constraints on the format, length, or structure of the skill's output. This section exists when the skill produces a specific artifact with format requirements.

Fabric uses this heavily — "Write bullets as exactly 16 words," "Only output Markdown," "Do not give warnings or notes." Most of these are too rigid for Crumb's context-aware skills. But the principle is sound: **if the output has format requirements, state them explicitly rather than hoping Claude infers them.**

**Use this section when:**
- The skill produces a structured document (spec, task list, audit report)
- There are length constraints or formatting standards
- The output feeds into another skill or process that expects a specific format

**Skip this section when:**
- The skill's output format is inherently flexible (e.g., writing coach — the output format matches the input format)

**Example (action-architect):**
```markdown
## Output Constraints

- `action-plan.md` uses H2 for milestones, H3 for phases
- `tasks.md` uses a markdown table with columns: id, description, state, depends_on, risk_level, domain, acceptance_criteria
- Task IDs follow the pattern `[PROJECT]-[NNN]` (zero-padded three digits)
- Acceptance criteria use binary testable format: state not action, YES/NO answerable
- Do not include implementation details in task descriptions — scope only
```

**What Fabric gets right here that Crumb should adopt:**
- Be specific about format (column names, ID patterns, heading levels)
- State anti-patterns explicitly ("Do not include implementation details")
- If the output feeds a downstream process, say what that process expects

---

### Output Quality Checklist (required)

*Crumb-specific — no Fabric equivalent (Fabric relies on OUTPUT INSTRUCTIONS to cover this)*

The pre-completion verification checklist. This is Crumb's equivalent of PAI's ISC — binary testable conditions the skill checks before declaring done.

**Convention borrowed from PAI/Fabric:** Write checklist items as **state, not action**. "Problem statement is clear and specific" (state) not "Write a clear problem statement" (action). Each item should be YES/NO answerable.

```markdown
## Output Quality Checklist

Before marking complete, verify:
- [ ] Problem statement is clear and specific
- [ ] Facts, assumptions, and unknowns are explicitly separated
- [ ] System map identifies high-leverage intervention points
- [ ] Domain and workflow depth are specified
- [ ] Tasks are properly scoped (≤5 file changes each)
- [ ] Summary document is created
- [ ] Risk levels are assigned to tasks
```

---

### Compound Behavior (required)

*Crumb-specific — no Fabric equivalent*

What this skill contributes to the learning system. One to three sentences stating what gets captured and where it goes.

```markdown
## Compound Behavior

Track estimate accuracy (planned tasks vs. actual tasks required) in
`_system/docs/estimation-calibration.md`. When recurring problem shapes are identified,
create or update entries in `_system/docs/solutions/` (track: pattern).
```

---

### Convergence Dimensions (required)

*Crumb-specific — no Fabric equivalent*

The 2-4 dimensions against which this skill's output is evaluated during convergence checks.

```markdown
## Convergence Dimensions

1. **Completeness** — All key sections present (problem statement, facts/assumptions/unknowns, system map, task decomposition)
2. **Clarity** — Unambiguous language, clear definitions, no conflicting statements
3. **Actionability** — Downstream work can proceed without additional clarification; success criteria are measurable
```

---

## What We Took from Fabric

| Fabric Convention | Crumb Adaptation |
|---|---|
| `# IDENTITY and PURPOSE` — prime the role before the steps | `## Identity and Purpose` — 2-4 sentences: what you are, what you produce, what you protect against |
| `# STEPS` — numbered procedural steps with verb-first instructions | `## Procedure` — same, but steps interact with vault, overlays, and context budgets |
| `# OUTPUT INSTRUCTIONS` — explicit format constraints | `## Output Constraints` — same principle, used when applicable, less rigid than Fabric's word-count rules |
| State anti-patterns explicitly ("Do not...") | Adopted in Output Constraints and Output Quality Checklist |
| Binary testable output criteria | Adopted in Output Quality Checklist (state not action, YES/NO answerable) |
| `# INPUT` section at the end | **Not adopted.** Crumb skills receive input through Claude Code's skill matching, not through a piped stdin. No INPUT section needed. |
| "Take a step back and think step by step" | **Not adopted.** Claude Code has extended thinking. Prompting for reasoning is unnecessary and wastes context. |

## What We Kept from Crumb (Not in Fabric)

| Crumb Section | Why Fabric Doesn't Have It |
|---|---|
| Context Contract | Fabric patterns are stateless one-shots with no persistent memory |
| Compound Behavior | Fabric has no learning system |
| Convergence Dimensions | Fabric has no quality evaluation framework |
| Overlay integration (in Procedure) | Fabric has no cross-cutting expert lens system |
| YAML frontmatter for routing | Fabric uses directory names for routing, not metadata |

---

## See Also

- [[agent-skills-best-practices]] — External best practices synthesis (Gechev/Google) with Crumb applicability analysis. Covers: 200-line JiT extraction audit trigger, third-person imperative voice convention, four-phase skill validation methodology, script promotion rule.

## Applying to Existing Skills

The Phase 1a skills (systems-analyst, action-architect, writing-coach, audit, obsidian-cli, checkpoint, sync, inbox-processor) follow these conventions. Later skills (peer-review, meme-creator, startup) drove the addition of optional frontmatter fields and the Prerequisites section — these should be backported to earlier skills where applicable.

---

## Minimal Skill Template

For creating new skills quickly:

```markdown
---
name: skill-name
description: >
  What this skill does. Trigger phrases and routing keywords.
# Optional routing fields — include when relevant:
# model_tier: execution
# context: main
# allowed-tools: Read, Write, Bash, Grep, Glob
# user-invocable: true
---

# Skill Name

## Identity and Purpose

You are a [role] who [produces what]. You protect against [failure mode].

## When to Use This Skill

- [Activation condition 1]
- [Activation condition 2]

## Prerequisites
<!-- Include only if the skill needs external tools, APIs, or libraries -->

- [Tool/library]: `install command`
- [API key]: `expected path`

## Procedure

### 1. Gather Context
[What to read from the vault before starting]

### 2. [Core Step]
[The main work]

### 3. [Output Step]
[What to produce]

### 4. Compound Check
[What to capture for the learning system]

## Context Contract

**MUST have:** [Required inputs]
**MAY request:** [Optional context]
**AVOID:** [What not to load]
**Typical budget:** [Context tier]

## Output Quality Checklist

- [ ] [Binary testable condition 1]
- [ ] [Binary testable condition 2]

## Compound Behavior

[What gets captured and where]

## Convergence Dimensions

1. **[Dimension]** — [Definition]
2. **[Dimension]** — [Definition]
```
