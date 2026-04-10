---
project: null
domain: software
type: reference
skill_origin: null
status: active
created: 2026-02-28
updated: 2026-02-28
tags:
  - kb/software-dev
  - agent-architecture
  - skills
  - crumb
topics:
  - moc-crumb-architecture
---

# Agent Skills Best Practices — Synthesis & Applicability

Source: [mgechev/skills-best-practices](https://github.com/mgechev/skills-best-practices) (Minko Gechev, Angular/Google)

This note distills the principles from Gechev's guide and evaluates each against Crumb and Tess. The guide targets GitHub Copilot / agentskills.io skill authoring, so the packaging conventions are platform-specific — but the underlying design principles transfer well.

---

## Principles Worth Adopting

### 1. Progressive Disclosure / Just-in-Time Loading

**The idea:** Keep the primary skill file lean (<500 lines) as a navigation and dispatch layer. Offload dense content — schemas, cheatsheets, templates — to subdirectories (`references/`, `assets/`). Instruct the agent *when* to read each file rather than dumping everything into context upfront.

**Crumb applicability:** High. Crumb's design spec already practices this (§-references, separate version history, file-conventions as a loaded-on-demand doc rather than inlined in CLAUDE.md). The principle to formalize: **if a skill or workflow doc exceeds ~200 lines, audit it for content that can be extracted into a reference file with a JiT read instruction.** The file-conventions.md rewrite (187 lines) is approaching this threshold — if it grows further, split binary/attachment conventions from core frontmatter rules.

**Tess applicability:** Moderate. Tess's operational scope is narrower (Telegram bot, message routing, memory persistence), so context bloat is less of a risk. But if Tess's behavior definitions grow, the same extraction pattern applies.

### 2. Deterministic Scripts Over LLM Improvisation

**The idea:** If the agent performs a fragile or repetitive operation, wrap it in a tested script rather than asking the LLM to generate the logic each time. Scripts should be tiny CLIs with descriptive stdout/stderr so the agent can self-correct on failure.

**Crumb applicability:** High. Crumb already follows this pattern — `vault-check.sh`, the inbox processor, MarkItDown integration, the pre-commit hook. The guide reinforces the design instinct: **if Claude Code does the same fiddly operation more than twice, it should become a script in `_system/scripts/`.** Candidates to watch for: any compound-step evaluation logic that's currently inline in workflow instructions, any file-manipulation sequences that recur across skills.

**Tess applicability:** High. The crumb-tess-bridge already uses atomic file exchange scripts. The OpenClaw daemon infrastructure is scripted. This principle is already embedded in practice.

### 3. Third-Person Imperative for Agent Instructions

**The idea:** Write skill instructions as direct commands: "Extract the text..." not "You should extract..." or "I will extract..." This produces more consistent agent behavior because it removes ambiguity about who the actor is.

**Crumb applicability:** Medium. Worth auditing existing skill and workflow files for voice consistency. The spec itself is written in a mix of descriptive and imperative — the procedural sections (skill definitions, workflow steps) should consistently use third-person imperative. This is a low-effort, high-signal cleanup.

### 4. Terminology Consistency

**The idea:** Pick one term per concept and use it everywhere. Don't alternate between "template," "markup," and "view" when you mean the same thing.

**Crumb applicability:** Medium. The vault is generally disciplined here, but drift happens over time as new features get added across sessions. Periodic terminology audits (during spec version bumps) would catch inconsistencies before they propagate. The file-conventions doc and CLAUDE.md are the most important files to keep terminologically tight since they're loaded frequently.

### 5. Skill Validation Methodology

**The idea:** A four-phase loop for stress-testing skills using an LLM:

1. **Discovery validation** — Test whether the skill's metadata triggers correctly (and doesn't false-trigger) by asking an LLM to generate positive and negative trigger prompts
2. **Logic validation** — Feed the full skill to an LLM, ask it to simulate execution step-by-step, flag any point where it's forced to guess or hallucinate
3. **Edge case testing** — Ask the LLM to attack the skill: find failure states, missing fallbacks, implicit assumptions
4. **Architecture refinement** — Apply fixes and re-verify progressive disclosure is enforced

**Crumb applicability:** High. This maps naturally to Crumb's existing peer review process (multi-model review of specs and implementations). The validation loop could be formalized as a skill-review checklist or integrated into the SPECIFY → PLAN → TASK workflow when creating or modifying skills. The logic validation step (step 2) is particularly valuable — having Claude simulate a skill's execution before shipping it would catch ambiguous instructions early.

**Tess applicability:** Moderate. Tess's behavior definitions are simpler, but the edge-case testing step (step 3) would catch gaps in message routing or memory persistence logic.

---

## Principles Already Covered / Less Relevant

### YAML Frontmatter Trigger Routing

The guide emphasizes optimizing `name` and `description` fields for agent-side skill discovery and routing. This is specific to platforms where an agent dynamically selects skills from a registry based on metadata matching. Crumb's dispatch model is explicit — workflow invocation is deliberate, not inferred from metadata. **No action needed.**

### Rigid Directory Structure (`scripts/`, `references/`, `assets/`)

The prescribed folder layout is a convention for portable skill packages. Crumb has its own directory conventions (`_system/`, `_system/scripts/`, project-level `design/` and `implementation/` folders). The *principle* of separating executable code from reference material from templates is sound and already practiced. **No structural change needed** — Crumb's conventions serve the same purpose.

### "No README, No CHANGELOG"

The guide advises against documentation files in skill packages because they consume agent context without operational value. In Crumb, docs serve a dual purpose: they're both human-readable references and agent context. The separate-version-history.md pattern, CLAUDE.md, and file-conventions.md are all documentation that the system depends on. **This advice doesn't apply to Crumb's architecture.**

---

## Actionable Takeaways

1. **Formalize the 200-line audit trigger:** When any skill, workflow, or convention doc crosses ~200 lines, evaluate it for JiT extraction. Add this as a guideline in skill-authoring-conventions.md if it doesn't already exist.
2. **Voice audit:** Scan existing skill definitions for inconsistent voice. Standardize on third-person imperative for all procedural instructions.
3. **Adopt the validation loop:** Integrate the four-phase skill validation methodology into the peer review process for new or modified skills. At minimum, run logic validation (simulated execution) before shipping.
4. **Script promotion rule:** If an inline operation appears in more than two skill/workflow executions, extract it to `_system/scripts/`. Track candidates during compound evaluations.

---

## Source Assessment

The guide is authored by Minko Gechev (Google/Angular team lead). It's concise, well-structured, and clearly written from practical experience with agent skill authoring. The repo is very new (1 commit, 25 stars as of 2026-02-28) and references the [agentskills.io spec](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) and [SkillsBench](https://arxiv.org/abs/2602.12670) for formal evaluation. The validation methodology section is the most original and valuable contribution — the structural advice is solid but well-trodden ground.
