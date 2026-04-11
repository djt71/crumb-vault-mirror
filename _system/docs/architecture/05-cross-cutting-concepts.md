---
type: reference
domain: software
status: active
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/architecture
topics:
  - moc-crumb-architecture
---

# 05 — Cross-Cutting Concepts

This section documents the observable conventions and enforced patterns that apply across the entire system. These are not design principles (those live in the design spec §0.2) — they are the concrete rules, formats, and enforcement mechanisms that govern how vault artifacts are created, validated, and maintained.

**Source attribution:** Synthesized from [[file-conventions]], [[crumb-design-spec-v2-4]] §2.2, §4.2–§4.5, §5.5–§5.6, §7.2–§7.8, and `vault-check.sh`.

---

## Frontmatter Schema

Every substantive document in the vault carries YAML frontmatter. Two schemas apply based on location:

**Project docs** (under `Projects/` or `Archived/Projects/`):
- Required: `project`, `domain`, `type`, `created`, `updated`
- No `status` field — lifecycle is directory-based (`Projects/` = active, `Archived/Projects/` = archived)

**Non-project docs** (everything else):
- Required: `project` (nullable), `domain`, `type`, `status`, `created`, `updated`
- `status`: `active` | `archived` | `draft`

**Optional fields (both):** `skill_origin`, `tags`, `topics`, and domain-specific fields.

**Summary docs** add `source_updated` — records the parent's `updated` value when generated. The staleness scan compares this at every session start.

vault-check §1 validates required fields. Path-conditional: project docs don't require `status`; non-project docs do.

---

## File Naming

- **kebab-case**, always: `frontend-design.md`, `api-spec.md`
- Summaries: `*-summary.md` alongside the parent in the same directory
- Run logs: `run-log.md` (current), `run-log-{label}.md` (archived)
- Binary files follow structured patterns — see [[file-conventions]] §Binary Filename Conventions

**Binary companion notes:** Every binary has a colocated `[filename]-companion.md` with `type: attachment-companion`. The companion is the agent-facing interface — agents can't see binary content. vault-check §12–§15 enforce the binary ↔ companion relationship bidirectionally.

---

## Tag Taxonomy

### `#kb/` Knowledge Base Tags

Three-level hierarchy, hard cap at `#kb/topic/subtopic`:

**18 canonical Level 2 tags:** `religion` · `philosophy` · `gardening` · `history` · `inspiration` · `poetry` · `writing` · `business` · `networking` · `security` · `software-dev` · `customer-engagement` · `training-delivery` · `fiction` · `biography` · `politics` · `psychology` · `lifestyle`

**Level 3 subtags** are open — created through compound engineering when a Level 2 accumulates enough notes for finer filtering (e.g., `kb/networking/dns`, `kb/business/pricing`). When a candidate Level 2 is clearly subordinate to an existing one, use Level 3 instead. Cross-domain topics use dual tagging.

**Enforcement:**
- vault-check §9 validates Level 2 against the canonical list and enforces depth ≤ 3
- vault-check §19 requires a `topics` field on every `#kb/`-tagged note (links to parent MOC)
- Four sync points for the canonical list: `file-conventions.md`, `CLAUDE.md`, design spec §5.5, `vault-check.sh` line 695

### System Documentation Tags

Not validated by vault-check but canonical by convention:
- `system/architecture` — Arc42 docs in `_system/docs/architecture/`
- `system/operator` — Diátaxis docs in `_system/docs/operator/`
- `system/llm-orientation` — LLM orientation tracking in `_system/docs/llm-orientation/`

---

## Type Taxonomy

31 document types govern the `type` frontmatter field. Key types:

| Type | Used For |
|------|----------|
| `specification` | Problem definitions, requirements |
| `design` | Technical design documents |
| `reference` | System config docs, conventions, protocols |
| `knowledge-note` | Synthesized knowledge from external sources |
| `signal-note` | Lightweight feed-pipeline captures |
| `source-index` | Per-source landing pages |
| `moc-orientation` / `moc-operational` | Maps of Content |
| `attachment-companion` | Binary file companion notes |
| `attention-item` | Operator attention items |

Full taxonomy with all 31 types: [[file-conventions]] §Type Taxonomy.

New types emerge through compound engineering, not speculative predefinition.

---

## Vault-Check (Mechanical Enforcement)

`_system/scripts/vault-check.sh` — ~27 deterministic validations (rule numbers are not dense — some checks were removed, others added; consult the script header for the authoritative list). The system's only enforcement mechanism that cannot hallucinate, forget, or skip steps.

**Enforcement tiers:**
- **Error (exit 2):** Blocks git commit. Required field violations, schema breaks, invariant violations.
- **Warning (exit 1):** Non-blocking. Advisory — review when convenient.
- **Clean (exit 0):** All checks pass.

**Key checks by category:**

| Category | Checks | What They Enforce |
|----------|--------|-------------------|
| Schema | §1, §3, §20, §25, §26, §27 | Frontmatter required fields, summary schema, source-index/signal-note/attention-item schemas |
| Staleness | §2, §11, §24 | Summary freshness, project-state last_committed, run-log size |
| Structural integrity | §4, §5, §6, §7 | Run-log session blocks, compound step continuity, session-log compound completeness, project scaffold |
| Task governance | §8, §10, §22, §23 | Task completion evidence, active_task consistency, DONE project guard, code review gate |
| Knowledge base | §9, §17, §18, §19, §21 | kb/ tag validation, MOC schema, topics resolution, topics requirement, synthesis density |
| Binary management | §12, §13, §14, §15 | Attachment orphans (both directions), binary location constraint, description completeness |
| Lifecycle | §16 | Archive location consistency |

**`--pre-commit` mode:** Scopes all checks to staged files only (~0.3s vs ~90s full scan). Pre-commit hook uses `--pre-commit`; audits use `--full`.

---

## Context Budget

Skills operate under a document budget to prevent context saturation:

| Tier | Doc Count | When |
|------|-----------|------|
| Standard | ≤5 | Default for all skill invocations |
| Extended | 6–8 | With justification (complex cross-cutting work) |
| Design ceiling | 10 | Hard maximum — never exceeded |

`required_context` entries in SKILL.md count against the budget. If they would push over, they take priority over discretionary loads.

**Context management (autonomous):**
- `< 70%`: Proceed normally
- `70–85%`: `/compact` to compress
- `> 85%`: `/clear` + vault reconstruction

Overlays and `personal-context.md` don't count against the budget.

---

## Summary Document Pattern

Every substantive doc may have a `*-summary.md` alongside it. Summaries are the primary context vehicle between workflow phases — downstream skills read summaries, not full docs.

**Structure:** Core Content (2–4 paragraphs), Key Decisions (bulleted), Interfaces/Dependencies, Next Actions.

**Staleness detection:** `source_updated` in summary frontmatter vs `updated` in parent. Mismatch → stale. Session-start scan checks this automatically. vault-check §2 enforces exhaustively.

**Rule:** Summaries are read-only references. Update the parent first, then regenerate the summary in the same operation.

---

## MOC System

Maps of Content are navigational indexes for knowledge domains. Two types:

| Type | Purpose | Example |
|------|---------|---------|
| `moc-orientation` | Synthesis + navigation for a topic area | `moc-philosophy`, `moc-business` |
| `moc-operational` | Procedural steps + checklists | `moc-crumb-operations` |

**15 built MOCs** across Learning and Career domains.

**Placement pass (deterministic):** When a note gets `#kb/` tags, the `topics` field maps it to parent MOCs via `kb-to-topic.yaml`. A one-liner is added to the MOC's Core section between `<!-- CORE:START -->` and `<!-- CORE:END -->` anchors.

**Synthesis pass (LLM, gated):** Runs when MOC debt score exceeds 30 points. Rewrites the Synthesis section, reassesses groupings, updates Tensions. Triggered by debt score = `(delta_count × 3 + staleness + overload) × review_basis_multiplier`.

**Debt signals:** delta count (new notes since last review), staleness (days since review, only when deltas exist), section overload (>15 Core entries).

---

## Compound Engineering

Every phase transition includes a compound reflection step (enforced by Context Checkpoint Protocol). The evaluation asks: did this phase involve non-obvious decisions, rework, reusable artifacts, or system gaps?

**Routing for insights:**
- Conventions → update existing docs (`file-conventions.md`, `CLAUDE.md`)
- Patterns → `_system/docs/solutions/` (organized by subdirectory: frontend, backend, problem, decision, process, writing)
- Primitive gaps → Primitive Proposal Flow (new skills, overlays, agents)

**Read-back:** Skills with `required_context` in their SKILL.md auto-load relevant solutions docs, closing the compound loop. `systems-analyst` and `action-architect` also glob `_system/docs/solutions/` for prior art.

**2026-04-04 enhancements:**
- **Track schema:** Compound insights now carry a `track` field distinguishing operational patterns from strategic reframings, routing them to different follow-up flows.
- **Conditional review routing:** High-confidence compound patterns can bypass full peer review; low-confidence or cross-domain patterns are flagged for operator review before solution-doc creation.
- **Cluster analysis:** Recurring compound insights across sessions are grouped for pattern promotion (solution → skill → primitive).

Non-project sessions get compound evaluation at session end, logged to `_system/logs/session-log.md`.

---

## Risk-Tiered Approval

Three tiers govern all vault operations:

| Tier | Behavior | Examples |
|------|----------|---------|
| **Low** | Auto-approve | Reading files, drafting, testing, searching, logging |
| **Medium** | Proceed + flag | Creating new files, modifying non-critical docs |
| **High** | Stop and ask | Architecture changes, schemas, external comms, production, irreversible |

Implemented behaviorally in CLAUDE.md, not mechanically. The classification is Claude's judgment call informed by the routing rules.

---

## Git Patterns

**Conventional commits:** `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`. One logical change per commit.

**Binary exclusion:** `.gitignore` excludes binary extensions (pdf, docx, pptx, xlsx, png, jpg, etc.). Companion notes (markdown) are tracked — they carry the binary's provenance. Git LFS stub in `.gitattributes` for future migration.

**Session-end commit (conditional):**
- Log-only delta → lightweight `chore: session-end log` commit
- Substantial delta → flag to user + descriptive commit
- No changes → skip commit entirely

**Pre-commit hook:** Runs `vault-check.sh --pre-commit`. Errors block the commit.

---

## Code Review Tiers

Two-tier model for code projects (projects with `repo_path`):

| Tier | Tool | When | Scope |
|------|------|------|-------|
| **Tier 1** | Sonnet inline | Every code task completion | Chunked diff review within main session |
| **Tier 2** | Review panel — Claude Opus (API) + Codex (CLI) | Milestone boundaries, large diffs | Full-context external review via code-review-dispatch agent |

vault-check §23 enforces that completed code tasks have a code review entry (or explicit skip) in the run-log. Warning level — advisory, not blocking.

---

## Task State Machine

Tasks in `tasks.md` follow a strict state machine:

```
pending → ready → claimed → in_progress → complete
                                ↓
                              ready (deferred)
```

**Transition invariants:**
- `ready` requires all `depends_on` tasks complete
- `complete` requires all acceptance criteria checked (`[x]`)
- One `claimed`/`in_progress` task per session (serial execution)
- No dependency cycles

**Acceptance criteria rules:** State not action ("endpoint returns 401" not "test the endpoint"). Binary testable (YES/NO). One short sentence (<15 words).

---

## Wikilink Convention

Obsidian uses shortest-path resolution (default):

- **Bare wikilinks** (`[[filename]]`) for globally-unique basenames — preferred default
- **Path-prefixed** (`[[Projects/foo/design/specification]]`) only when basename is ambiguous

When routing a document to a new location, add a wikilink from the document that would naturally lead someone to the new content. One edit, permanent discoverability.
