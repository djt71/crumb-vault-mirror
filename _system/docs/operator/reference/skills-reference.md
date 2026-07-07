---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-07-07
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Skills Reference

Complete index of Crumb's 11 skills. Each skill is defined in a `SKILL.md` file under `.claude/skills/<name>/` and is auto-activated when Claude's description matching detects the relevant trigger.

**Architecture source:** [[02-building-blocks]] §Skills Layer

---

## Skills Index

| Skill | Purpose | Trigger Pattern | Model Tier | Inputs | Outputs |
|-------|---------|----------------|------------|--------|---------|
| action-architect | Decompose specs into milestones and tasks | "break this down", "create tasks", "what's the plan" | reasoning | Approved spec, designs | action-plan.md, tasks.md |
| audit | Vault health, staleness, drift checks; state checkpoints | "audit vault", "check for drift", "checkpoint", phase transitions | reasoning | Vault structure, summaries, logs | Audit report, corrective actions, checkpoint log entries |
| deck-intel | Extract intelligence from PPTX/PDF; interpret visuals (diagrams→Mermaid, tables→markdown) | "process this deck", "extract intel", "capture this diagram" | reasoning | PPTX/PDF/image binary | Knowledge-note in Sources/, visual-capture notes |
| inbox-processor | Classify and route _inbox/ files | "process inbox", "check inbox" | reasoning | Files in _inbox/ | Markdown + frontmatter, companion notes |
| mermaid | Inline diagrams in markdown | "diagram this", "visualize this", "chart" | execution | Description, diagram type | Mermaid code blocks in .md |
| peer-review | Cross-model artifact review | "peer review", "get review", "send for review" | reasoning | Artifact, review config | Review note, synthesis |
| review-panel | Cross-model code review panel (escalation tier above built-in /code-review) | "review panel", high-stakes pre-merge, milestone boundaries | reasoning | Code diff, project context | Review note with findings |
| startup | Session initialization checks | Session start (automatic) | execution | Vault state | Startup summary |
| systems-analyst | Problem analysis to specification; learning-plan variant | "analyze this", "write a spec", "learning plan", "training plan" | reasoning | Problem statement, context | specification.md + summary, learning plans |
| vault-query | Structured vault lookups | "query the vault", "what do we know about" | execution | Query + scope | vault-query-*.md |
| writing-coach | Clarity, structure, tone editing | "improve this", "review my writing" | reasoning | Text + audience context | Revised text |

---

## Model Routing

Skills declare a `model_tier` that determines execution context:

| Tier | Model | Count | Skills |
|------|-------|-------|--------|
| **execution** | Sonnet | 3 | mermaid, startup, vault-query (inline execution permitted for trivial lookups) |
| **reasoning** | Opus (session default) | 8 | action-architect, audit, deck-intel, inbox-processor, peer-review, review-panel, systems-analyst, writing-coach |

Execution-tier skills are delegated to Sonnet subagents. See CLAUDE.md §Model Routing for phased rollout status and override rules.

---

## Workflow Phase Alignment

| Phase | Primary Skills | Notes |
|-------|---------------|-------|
| **SPECIFY** | systems-analyst | Produces specification.md |
| **PLAN** | action-architect, systems-analyst (learning-plan variant) | Produces action-plan.md, tasks.md |
| **ACT / IMPLEMENT** | review-panel, peer-review, writing-coach | Review gates at milestone boundaries |
| **Cross-phase** | audit (incl. checkpoints), startup | Ambient — available at any point |
| **Standalone** | deck-intel, inbox-processor | Not tied to project phases |

---

## Overlay Integration

These skills check `_system/docs/overlays/overlay-index.md` for matching overlays before executing:

| Skill | Overlay Check | Common Overlays |
|-------|--------------|-----------------|
| systems-analyst | Step 2 — match task against index | Domain-specific (Career Coach, Network Skills); learning-plan variant co-fires Career Coach, Life Coach |
| action-architect | Step 2 — match task against index | Domain-specific |
| writing-coach | Step 2 — match audience | Design Advisor (external audience) |

Overlays add lens questions — they don't replace the skill procedure.

---

## Composable Skills

Some skills are designed to be called by other skills:

| Skill | Called By | Purpose |
|-------|----------|---------|
| vault-query | any skill needing structured retrieval | Scoped vault lookups (former primary caller researcher retired 2026-07-07) |

---

## Dispatch Capabilities

Skills that declare structured dispatch capabilities in frontmatter (historical — the bridge/cron dispatch layer was decommissioned; capability metadata retained for cost calibration):

| Skill | Capability ID | Token Budget | Cost Estimate |
|-------|--------------|-------------|---------------|
| researcher (retired 2026-07-07) | research.external.standard | 150k | ~$2.25 |

---

## Required Context

Skills with mandatory context documents (loaded before execution):

| Skill | Required Documents |
|-------|--------------------|
| review-panel | code-review-patterns.md, claude-print-automation-patterns.md |
| peer-review | reasoning-token-budget.md; body-level: peer-review-config.md, review-safety-denylist.md |
| writing-coach | ai-telltale-anti-patterns.md (external audience only) |
| audit | archive-conventions.md |

---

## Skill File Locations

All skills live under `.claude/skills/<name>/SKILL.md`:

```
.claude/skills/
├── action-architect/SKILL.md
├── audit/SKILL.md
├── deck-intel/SKILL.md
├── inbox-processor/SKILL.md
├── mermaid/SKILL.md
├── peer-review/SKILL.md
├── review-panel/SKILL.md
├── startup/SKILL.md
├── systems-analyst/SKILL.md
├── vault-query/SKILL.md
└── writing-coach/SKILL.md
```

**Reconciliation:** 11 SKILL.md files under `.claude/skills/` as of 2026-07-07. Retired 2026-07-07 per skills-library review §C decisions: researcher, critic, sync (folded into session-end protocol §7), deliberation (design preserved in `_system/docs/solutions/deliberation-panel-pattern.md`); code-review renamed review-panel. Prior: 15 (attention-manager retired to Cowork 2026-07-05, see `cowork-attention-handoff.md`; 16 per VO B5, 2026-07-04).

---

## Built-In Overlap Policy (adopted 2026-07-07)

Claude Code ships built-in skills whose territory can overlap Crumb's (currently: `/code-review` + `ultra`, `/review`, `/security-review`, deep-research, dataviz). Standing policy:

1. **Built-in handles the everyday case.** Don't maintain Crumb machinery that duplicates a zero-maintenance built-in.
2. **Crumb skills hold only differentiated value** — things a built-in structurally can't do: cross-model panels, vault wiring, gate enforcement, vault-grounded context.
3. **Name collisions are eliminated** (code-review → review-panel precedent), and descriptions must disambiguate from the adjacent built-in.
4. **New collisions are caught at audit time** — the operator/architecture drift check (audit weekly check 13) compares the skill roster against the harness's built-in list.

Current tiering under the policy: built-in `/code-review` (or `ultra`) for routine passes → **review-panel** for high-stakes merges; built-in deep-research for research (researcher retired); built-in dataviz for chart design guidance (mermaid holds Obsidian-specific rendering + Excalidraw).
