---
type: run-log
project: skills-library
domain: software
status: active
created: 2026-07-06
updated: 2026-07-06
topics:
  - moc-crumb-operations
tags:
  - run-log
---

# skills-library — Run Log

## 2026-07-06 — Project creation

**Trigger:** Operator wants a skills library available across the two Class 3 work surfaces: Claude Code (Crumb) and claude.ai (Cowork). Feasibility assessment done pre-project (this session); operator approved project creation.

**Operator decisions (project creation gate):**
1. Name/domain: `skills-library`, domain software, type system, vault-only (no external repo — repo gate skipped per CLAUDE.md §3b)
2. Two-surface picture confirmed as the accurate mental model: Crumb + Cowork/claude.ai are the work surfaces; `work-surfaces.md`'s seven-entry roster covers surfaces *plus* channels/viewing/substrate — doc revision is in scope for this project or flagged to quarterly review.

**Pre-project findings (verified 2026-07-06 via claude-code-guide agent against platform.claude.com / code.claude.com / support.claude.com docs):**
- SKILL.md format (YAML frontmatter + markdown + bundled files) is identical across Claude Code, claude.ai, Cowork, API — fully portable.
- **No cross-surface sync exists.** claude.ai: per-user zip upload via Settings. Cowork: Skills tab or `/v1/skills` API (workspace-wide). Claude Code: `.claude/skills/` filesystem.
- Execution asymmetry: Claude Code + Cowork have local filesystem/bash; claude.ai runs skills in a sandboxed code-execution VM (no local fs, no local bash, network varies).
- Limits: 20 skills/session (Managed Agents API); name ≤64 chars, description ≤1024 chars; file-size/bundle-count limits undocumented.

**Working thesis (input to SPECIFY, not yet spec'd):**
- Three tiers: **Crumb-only** (vault machinery — sync, audit, inbox-processor, code-review, etc.), **portable core** (pure procedure/judgment — writing-coach, mermaid, deck-intel method, researcher stages, critic rubric), **claude.ai-only** (non-markdown deliverable production, connector-native workflows, away-from-desk `_inbox/` capture formatting, write-boundary discipline substitute).
- Architecture principle: vault originates; claude.ai/Cowork copies are regenerated projections (same class as `claude-ai-context.md`). No sync daemon, no promotion machinery — a packaging script + operator-triggered upload (ceremony budget).
- Highest-value claude.ai-only candidate: a "Cowork vault etiquette" skill carrying write-boundary classes inline (claude.ai has no CLAUDE.md/hooks/vault-check).

**Next:** Enter SPECIFY (systems-analyst) in a fresh phase of work — define tiers, membership criteria, packaging mechanism, doc-update scope.
