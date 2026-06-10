---
type: design-summary
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: optimization-design.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - design
  - summary
---

# vault-optimization — Optimization Design Summary

Design for executing VO-001–009 in six parts: **D1** evidence + manifest schema
(type-specific evidence commands, 6-column manifest with rubric/evidence/owner,
Appendix A ownership matrix schema with per-surface gates; manifest scope =
primitive surface + `_system/` docs + project records, KB content excluded);
**D2** nine-surface consumer-graph search protocol (wikilinks, plain paths,
hooks, plists, backup filters, Obsidian config, dashboard, memory, glob
conventions) with recorded commands; **D3** storage policy structure on the
three-outcome distinction — `Archived/` deletion with canonical-exception
extraction, orphan/heavyweight sweeps, dead-log producer-alive check,
history-rewrite default-out; **D4** batch design — B0 backup restore-drill gate,
then B1 Archived → B2 attachments/logs → B3 docs → B4 scripts/protocols/overlays
→ B5 skills/agents → B6 ceremony, each batch = remediate→delete→vault-check
green→atomic commit, primitives deliberately last; **D5** per-axis notes
(trigger-condition descriptions on kept skills, delete-unless-canonical doc
rule, ceremony steps classified load-bearing/zombie/mergeable); **D6** soak =
six representative Tier-1 workflows, metrics defined at TASK (A10).

**Gap flagged for TASK:** end-state deliverable #2 (core-functionality operating
note) has no producing task — proposed split VO-002 draft / VO-009 finalize.

**PLAN gate decisions (operator, 2026-06-10 — all resolved as designed):**
KB content excluded from manifest; git remote is the authoritative B0 restore
source (Drive/mirror secondary); batch order confirmed (Archived/ first,
primitives B4/B5, ceremony B6); operating-note split confirmed (VO-002 draft /
VO-009 finalize).
