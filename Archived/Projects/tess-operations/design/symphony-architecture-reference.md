---
project: tess-operations
domain: software
type: reference
skill_origin: null
created: 2026-03-08
updated: 2026-03-08
tags:
  - architecture
  - design-input
---

# Symphony Architecture Reference

OpenAI's Symphony framework validates the architectural patterns tess-operations is building. Full analysis in [[openai-symphony-orchestration-framework]].

## Relevance to This Project

**Three-way equivalence:**
- Mechanic 9-check poll loop = Symphony's tick cycle (poll → evaluate → act → reconcile)
- Morning briefing = Symphony's tracker read (poll external state → synthesize → present)
- Bridge dispatch protocol = Symphony's dispatch loop (external system dispatches → agent executes → results flow back)

**Feed-intel (M7)** is the most Symphony-shaped workstream — inbox items map to Linear tickets, Tess triaging maps to candidate selection, Crumb processing via bridge maps to Codex sessions. Refinement: routine capture stays local on mechanic; bridge dispatch for complex items only.

**Quality gap** is the strategic differentiator. Symphony checks CI (binary). Tess-operations builds multi-criteria gate evaluations with governance separation. Formalized as reusable pattern: [[gate-evaluation-pattern]].

**Mechanic evolution** — three properly scoped enhancements identified (not convention changes): stall detection (timeout infrastructure), state reconciliation (specification problem), retry with backoff (scheduler upgrade). Circled for future scoping.

## Related

- [[karpathy-autoresearch-pattern-applicability]] — companion analysis of autoresearch pattern
- [[gate-evaluation-pattern]] — reusable mechanism extracted from this analysis
