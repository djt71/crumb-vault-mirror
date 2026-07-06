---
type: specification-summary
project: skills-library
domain: software
status: active
skill_origin: systems-analyst
created: 2026-07-06
updated: 2026-07-06
summary_of: specification.md
source_updated: 2026-07-06
topics:
  - moc-crumb-architecture
tags:
  - specification
  - summary
---

# skills-library — Specification Summary

**Problem:** Crumb's 15 skills are locked to `.claude/skills/` on the Mac Studio; the other work surface (Cowork/claude.ai) has none of that encoded judgment, and the platform offers no cross-surface sync. Without a library architecture, skills stay Crumb-locked or fork and drift.

**Solution shape:** Tiered library — **Crumb-only** (vault machinery), **portable core** (3–5 pure-procedure skills), **claude.ai-only** (deferred: Cowork etiquette, capture, deliverables). Vault is sole originator; claude.ai/Cowork copies are regenerated projections (memory-stratification pattern). Packaging script + manifest + manual upload runbook — no sync automation, no API push, no credentials (ceremony budget, operator decision 2026-07-06).

**Key facts:** SKILL.md format is portable across all surfaces; no sync exists (claude.ai = zip upload, Cowork = Skills tab); claude.ai skills run sandboxed (no local fs/bash). SkillsBench: 2–3 focused skills beat comprehensive sets — exclusion is as valuable as inclusion.

**Key assumptions to validate:** A1 manual-upload ceremony is sustainable; A3 claude.ai triggering behaves like Claude Code's (test at first upload); A4 single SKILL.md source serves both surfaces (resolve in PLAN).

**Success criteria (abridged):** all skills tier-classified; 3–5 portable skills conform to authoring conventions from single source; script + runbook exist; ≥1 skill verified live on claude.ai; work-surfaces.md + claude-ai-context.md updated; zero new automation surface.

**Tasks:** SKL-001 tier classification → SKL-002 portable conventions → SKL-003 adapt portable core → SKL-004 packaging script → SKL-005 first upload + live verification → SKL-006 doc updates → SKL-007 (deferred) claude.ai-only tier via Primitive Creation Protocol.

**Risks:** drift (mitigated: single source + manifest hashes), undertriggering on claude.ai (mitigated: trigger-phrased descriptions + live verification), sync-automation scope creep (foreclosed by success criterion 6).
