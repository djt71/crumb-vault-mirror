---
type: specification
project: skills-library
domain: software
status: active
skill_origin: systems-analyst
created: 2026-07-06
updated: 2026-07-06
topics:
  - moc-crumb-architecture
tags:
  - specification
  - kb/software-dev
---

# skills-library — Specification

## Problem Statement

Crumb's encoded judgment — 15 skills' worth of procedure, rubrics, and conventions — exists only in `.claude/skills/` on the Mac Studio, invisible to the other Class 3 work surface (Cowork/claude.ai). The platform provides no cross-surface skill sync, so without a deliberate library architecture, skills will either stay Crumb-locked or fork into hand-maintained copies that drift. This project defines a tiered skills library with the vault as sole originator and projection-based packaging for the claude.ai surfaces.

## Facts vs Assumptions

**Facts** (verified 2026-07-06 against platform.claude.com / code.claude.com / support.claude.com):
- SKILL.md format (YAML frontmatter `name`/`description` + markdown body + bundled files) is identical across Claude Code, claude.ai, Cowork, and the API.
- **No cross-surface sync exists.** claude.ai: per-user zip upload via Settings > Features. Cowork: Skills tab or `/v1/skills` API. Claude Code: `.claude/skills/` filesystem.
- Execution asymmetry: Claude Code and Cowork have local filesystem + bash; claude.ai skills run in a sandboxed code-execution VM (no local fs, no local bash, network varies).
- Limits: 20 skills/session (Managed Agents API); name ≤64 chars; description ≤1024 chars. File-size and bundle-count limits are undocumented.
- Empirical (SkillsBench, medium confidence): 2–3 focused skills +18.6pp vs 4+ skills +5.9pp vs comprehensive −2.9pp; skills only compound in domains with weak pretraining coverage; self-generated skills fail (−1.3pp).
- Crumb has 15 skills; most assume local bash, git, obsidian-cli, vault paths, or hooks.
- Prior art: memory-stratification pattern (high confidence) — vault/markdown+git is the canonical layer; every other store is a cache or projection.

**Assumptions** (marked for validation):
- A1: Skills change rarely enough that manual re-upload on material change is acceptable ceremony. *(Validate during soak — if uploads become frequent, revisit.)*
- A2: Portable skills add value on claude.ai despite strong model baselines — because they encode Danny-specific procedure and vault conventions, not generic capability. *(Validate per skill at classification time using the SkillsBench lens: reject candidates whose content the model already does well untrained.)*
- A3: claude.ai skill triggering behaves like Claude Code's (description scan → invoke). *(Validate at first upload — SKL-005.)*
- A4: A single SKILL.md source can serve both surfaces for portable-tier skills, with surface differences handled by authoring conventions rather than forked variants. *(Validate in design; if false, the packaging step transforms rather than copies.)*

**Unknowns:**
- U1: zip structure requirements and size limits for claude.ai upload (undocumented — discover empirically at SKL-005).
- U2: Whether Cowork shares the Claude Code memory directory (existing agentic-sunset AS-023 observation item — not a dependency, but informs the etiquette skill later).
- U3: How many portable skills is optimal on claude.ai given the SkillsBench focus finding (start small: 3–5).

## System Map

**Components:**
- `.claude/skills/` — canonical skill sources (existing, 15 skills)
- Tier classification — per-skill frontmatter marker (exact key decided in PLAN; e.g., `surfaces: [crumb]` / `[crumb, claude-ai]` / `[claude-ai]`)
- Packaging script (`_system/scripts/`) — builds per-skill zips into a `dist/` area (git-ignored), with a manifest recording skill → version/hash → last-packaged date
- Upload runbook — operator procedure: when to package, where to upload on each surface, how to verify
- `_system/docs/work-surfaces.md` — Memory Ownership section gains the skills-projection row
- `_system/docs/claude-ai-context.md` — projection tells claude.ai sessions which skills exist and their tier discipline

**Dependencies:** none hard. Related: agentic-sunset AS-023 (Cowork memory observation, U2); vault-optimization M5 soak (this project's session activity counts as working sessions; no VO-removed primitives may be restored as workaround).

**External repo:** none — vault-only (scripts live in `_system/scripts/`, skills in `.claude/skills/`).

**Constraints:**
- Ceremony budget: no sync daemon, no promotion machinery, no API push (operator decision 2026-07-06). Manual upload, operator-triggered.
- Write boundary: claude.ai/Cowork skill copies are projections — regenerated, never hand-edited on the far side; a far-side edit is a stale-cache defect, not a competing claim.
- Primitive Creation Protocol: any *new* skill (claude.ai-only tier) requires operator approval before authoring.
- Portable skills must not reference local paths, bash, git, obsidian-cli, or hooks in their procedure.

**Levers (high-impact intervention points):**
- Tier classification is the quality gate — the SkillsBench focus finding means *excluding* skills is as valuable as including them.
- Portable authoring conventions (single source, trigger-phrased descriptions, no environment references) prevent the drift failure mode at the root instead of policing it downstream.

**Second-order effects:**
- Drift risk between vault master and uploaded copy → mitigated by manifest (hash comparison shows staleness) and by low change frequency (A1).
- Skills used on claude.ai generate outputs that must land correctly → portable skills must end with surface-appropriate delivery ("hand the artifact to the user / deposit via `_inbox/`"), never vault writes.
- Adding a claude.ai-only tier later creates the first vault-canonical artifacts whose *runtime* is exclusively off-Mac — the vault copy is still the master (memory-stratification pattern holds).

## Domain Classification & Workflow Depth

- **Domain:** software (type: system, vault-only)
- **Workflow:** full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** produces executable artifacts (packaging script, adapted skills) with conventions that downstream skills depend on; misclassification or drift has compounding cost. PLAN phase resolves the single-source mechanism (A4) before implementation.

## Success Criteria

1. Every current skill has an explicit tier classification with one-line rationale.
2. 3–5 portable-core skills pass the authoring conventions (no environment references, trigger-phrased description, surface-appropriate output delivery) from a single vault source.
3. Packaging script produces uploadable zips + manifest; runbook documents the operator procedure.
4. At least one portable skill verified live on claude.ai: uploads cleanly, triggers on its description, executes its procedure in the sandbox.
5. work-surfaces.md and claude-ai-context.md reflect the skills-projection policy.
6. No new automation surface: zero daemons, zero credentials, zero scheduled jobs added.

## Task Decomposition

| ID | Task | Tags | Risk | Depends on |
|---|---|---|---|---|
| SKL-001 | Tier-classify all 15 skills (+ rationale each; apply SkillsBench exclusion lens) | #decision | low | — |
| SKL-002 | Write portable authoring conventions (allowed references, description phrasing, output delivery, gotchas section) | #writing | low | SKL-001 |
| SKL-003 | Adapt the portable-core skills (3–5 per SKL-001) to the conventions, single-source | #code #writing | medium | SKL-002 |
| SKL-004 | Packaging script + manifest (zip per portable skill into git-ignored dist/) | #code | low | SKL-001 |
| SKL-005 | First upload + live verification on claude.ai and Cowork (validates A3, U1); write upload runbook | #behavior-change #research | medium | SKL-003, SKL-004 |
| SKL-006 | Doc updates: work-surfaces.md Memory Ownership row + claude-ai-context.md projection regeneration | #writing | medium | SKL-005 |
| SKL-007 | *(Deferred milestone)* claude.ai-only tier: propose "Cowork vault etiquette" skill first (Primitive Creation Protocol — operator approval gate), then capture/deliverable candidates | #decision #writing | medium | SKL-006 |

**Acceptance criteria** are written per-task at TASK phase (action-architect); the table above carries scope and dependency only.

## Risks

- **Drift** (portable copy diverges from vault master): mitigated by single-source rule + manifest hashes. Medium likelihood, low impact given change frequency.
- **Undertriggering on claude.ai** (skill uploaded but never fires): mitigated by trigger-phrased descriptions (trq212) and SKL-005 live verification. Medium likelihood, medium impact.
- **Scope creep toward sync automation**: explicitly foreclosed by success criterion 6; any future automation is a new operator decision.
- **Skill sprawl on claude.ai** (porting too much): foreclosed by the 3–5 cap and SkillsBench exclusion lens in SKL-001.
