---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-04-05
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Skills Reference

Complete index of Crumb's 20 skills. Each skill is defined in a `SKILL.md` file under `.claude/skills/<name>/` and is auto-activated when Claude's description matching detects the relevant trigger.

**Architecture source:** [[02-building-blocks]] §Skills Layer

---

## Skills Index

| Skill | Purpose | Trigger Pattern | Model Tier | Inputs | Outputs |
|-------|---------|----------------|------------|--------|---------|
| action-architect | Decompose specs into milestones and tasks | "break this down", "create tasks", "what's the plan" | reasoning | Approved spec, designs | action-plan.md, tasks.md |
| attention-manager | Daily focus plan or monthly review | "plan my day", "daily attention", "monthly review" | reasoning | Goal-tracker, SE inventory, personal context | Daily artifact, monthly review |
| audit | Vault health, staleness, drift checks | "audit vault", "check for drift", "vault hygiene" | reasoning | Vault structure, summaries, logs | Audit report, corrective actions |
| checkpoint | Log progress, compact context, verify state | "checkpoint", phase transitions | execution | Run-log, context status | Context summary, log entries |
| code-review | Two-reviewer panel for code quality | "review this code", "code review" | reasoning | Code diff, project context | Review note with findings |
| critic | Adversarial review of vault artifacts | "critique this", "find problems", "adversarial review" | reasoning | Artifact for review | Structured critique with severity ratings |
| deck-intel | Extract intelligence from PPTX/PDF | "process this deck", "extract intel" | reasoning | PPTX/PDF binary | Knowledge-note in Sources/ |
| deliberation | Multi-agent panel evaluation of artifacts | "deliberate on", "run deliberation", "panel review" | reasoning | Artifact, evaluator config | Deliberation record with ratings |
| diagram-capture | Extract visuals from PPTX/PDF/images | "capture this diagram", "extract images" | reasoning | Binary file with visuals | Mermaid/tables/descriptions |
| feed-pipeline | Process feed-intel, promote to KB | "process feed items", "feed pipeline" | reasoning | Feed-intel items, FIF SQLite | Signal-notes, review queues |
| inbox-processor | Classify and route _inbox/ files | "process inbox", "check inbox" | reasoning | Files in _inbox/ | Markdown + frontmatter, companion notes |
| learning-plan | Structured skill acquisition plans | "learn", "training plan", "study plan" | reasoning | Skill type, target level | Learning plan with phases |
| mermaid | Inline diagrams in markdown | "diagram this", "visualize this", "chart" | execution | Description, diagram type | Mermaid code blocks in .md |
| peer-review | Cross-model artifact review | "peer review", "get review", "send for review" | reasoning | Artifact, review config | Review note, synthesis |
| researcher | Evidence-grounded research pipeline | "research", "investigate", "find evidence" | reasoning | Research brief | Knowledge-note, fact-ledger |
| startup | Session initialization checks | Session start (automatic) | execution | Vault state | Startup summary |
| sync | Git commit, cloud backup | Session end, milestones | execution | Git state, cloud config | Commits, backups |
| systems-analyst | Problem analysis to specification | "analyze this", "write a spec" | reasoning | Problem statement, context | specification.md + summary |
| vault-query | Structured vault lookups | "query the vault", "what do we know about" | execution | Query + scope | vault-query-*.md |
| writing-coach | Clarity, structure, tone editing | "improve this", "review my writing" | reasoning | Text + audience context | Revised text |

---

## Model Routing

Skills declare a `model_tier` that determines execution context:

| Tier | Model | Count | Skills |
|------|-------|-------|--------|
| **execution** | Sonnet | 5 | checkpoint, mermaid, startup, sync, vault-query |
| **reasoning** | Opus (session default) | 15 | action-architect, attention-manager, audit, code-review, critic, deck-intel, deliberation, diagram-capture, feed-pipeline, inbox-processor, learning-plan, peer-review, researcher, systems-analyst, writing-coach |

Execution-tier skills are delegated to Sonnet subagents. See CLAUDE.md §Model Routing for phased rollout status and override rules.

---

## Workflow Phase Alignment

| Phase | Primary Skills | Notes |
|-------|---------------|-------|
| **SPECIFY** | systems-analyst | Produces specification.md |
| **PLAN** | action-architect, learning-plan | Produces action-plan.md, tasks.md |
| **ACT / IMPLEMENT** | code-review, peer-review, writing-coach | Review gates at milestone boundaries |
| **Cross-phase** | audit, checkpoint, startup, sync | Ambient — available at any point |
| **Standalone** | attention-manager, deck-intel, deliberation, feed-pipeline, inbox-processor, researcher | Not tied to project phases |

---

## Overlay Integration

These skills check `_system/docs/overlays/overlay-index.md` for matching overlays before executing:

| Skill | Overlay Check | Common Overlays |
|-------|--------------|-----------------|
| systems-analyst | Step 2 — match task against index | Domain-specific (Career Coach, Security Advisor) |
| action-architect | Step 2 — match task against index | Domain-specific |
| writing-coach | Step 2 — match audience | Design Advisor (external audience) |
| learning-plan | Step 2 — match skill domain | Career Coach, Life Coach |
| attention-manager | **Always** loads Life Coach + Career Coach | Non-optional |

Overlays add lens questions — they don't replace the skill procedure.

---

## Composable Skills

Some skills are designed to be called by other skills:

| Skill | Called By | Purpose |
|-------|----------|---------|
| diagram-capture | deck-intel, inbox-processor | Extract and interpret visual content from binaries |
| vault-query | researcher | Pre-research vault scoping |

---

## Dispatch Capabilities

Skills that expose structured dispatch for automation (bridge, cron):

| Skill | Capability ID | Token Budget | Cost Estimate |
|-------|--------------|-------------|---------------|
| researcher | research.external.standard | 150k | ~$2.25 |
| feed-pipeline | feed.triage.standard | 80k | ~$1.20 |
| feed-pipeline | feed.promotion.signal | 60k | ~$0.90 |
| feed-pipeline | feed.promotion.dashboard | 40k | ~$0.60 |
| attention-manager | attention.daily | 40k | ~$0.60 |
| attention-manager | attention.monthly | 60k | ~$0.90 |
| vault-query | vault.query.facts | 30k | ~$0.25 |

---

## Required Context

Skills with mandatory context documents (loaded before execution):

| Skill | Required Documents |
|-------|--------------------|
| attention-manager | goal-tracker, SE inventory, personal-context, 2 overlays, philosophy |
| code-review | code-review-patterns.md, claude-print-automation-patterns.md |
| peer-review | peer-review-config.md, peer-review-denylist.md |
| writing-coach | ai-telltale-anti-patterns.md (external audience only) |
| feed-pipeline | file-conventions.md, kb-to-topic.yaml |
| audit | archive-conventions.md |

---

## Skill File Locations

All skills live under `.claude/skills/<name>/SKILL.md`:

```
.claude/skills/
├── action-architect/SKILL.md
├── attention-manager/SKILL.md
├── audit/SKILL.md
├── checkpoint/SKILL.md
├── code-review/SKILL.md
├── critic/SKILL.md
├── deck-intel/SKILL.md
├── deliberation/SKILL.md
├── diagram-capture/SKILL.md
├── feed-pipeline/SKILL.md
├── inbox-processor/SKILL.md
├── learning-plan/SKILL.md
├── mermaid/SKILL.md
├── peer-review/SKILL.md
├── researcher/SKILL.md
├── startup/SKILL.md
├── sync/SKILL.md
├── systems-analyst/SKILL.md
├── vault-query/SKILL.md
└── writing-coach/SKILL.md
```

**Reconciliation:** 20 SKILL.md files verified under `.claude/skills/`.
