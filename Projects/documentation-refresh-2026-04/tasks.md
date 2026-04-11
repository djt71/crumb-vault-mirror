---
type: tasks
project: documentation-refresh-2026-04
domain: software
status: active
created: 2026-04-11
updated: 2026-04-11
skill_origin: action-architect
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Refresh 2026-04 — Tasks

12 atomic tasks. All knowledge-work (`#writing` or `#research`). State progression: `pending` → `in_progress` → `complete`.

## Task Table

| id | description | state | depends_on | risk_level | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| DOC-001 | Validate spec unknowns: capture live `launchctl list`, read tess-v2 `project-state.yaml`, confirm bridge-watcher service shape. Write findings into run-log as staleness-closeout entry. | complete | — | low | software | Run-log contains `launchctl list` output OR note of which services verified; tess-v2 current phase recorded; bridge-watcher state recorded; each spec unknown either resolved or explicitly accepted as stated. |
| DOC-002 | Refresh `_system/docs/architecture/01-context-and-scope.md`: Tess Voice model = Kimi K2.5 + Qwen 3.6 failover; Tess Mechanic model = Nemotron; add `lifestyle` as 9th canonical domain; verify actor definitions unchanged otherwise. | complete | DOC-001 | low | software | File contains `Kimi K2.5` and `Nemotron`; no `Haiku 4.5` or `qwen3-coder` references; domain list contains `lifestyle`; `updated: 2026-04-11` in frontmatter; Mermaid context diagram renders without errors. |
| DOC-003 | Refresh `_system/docs/architecture/02-building-blocks.md` inventories: skill table = 20 skills matching `ls .claude/skills/`; subagent table = 4 rows including `deliberation-dispatch`; overlay count verified; script count verified; block-beta mermaid diagram counts updated. | complete | DOC-002 | medium | software | Skill table row count = `ls .claude/skills/ \| wc -l`; subagent table row count = `ls .claude/agents/ \| wc -l`; no references to removed skills (excalidraw, lucidchart, meme-creator, obsidian-cli); `critic` and `deliberation` present; `deliberation-dispatch` present; `updated:` bumped. |
| DOC-004 | Refresh `_system/docs/architecture/04-deployment.md` process model: remove `email-triage` from both gui domains; update ollama model from qwen3-coder to current (Nemotron or verified-from-launchctl); verify every other LaunchAgent against live `launchctl list` from DOC-001; add Quartz v4 static site if running as a service. | complete | DOC-003 | medium | software | Process model mermaid contains no `email-triage` node; ollama model name matches live state; every service node in diagram verified against DOC-001 `launchctl list`; `updated:` bumped. |
| DOC-005 | Refresh `_system/docs/architecture/03-runtime-views.md` sequence diagrams: verify Tess dispatch diagram matches tess-v2 Amendment Z interactive dispatch architecture; verify feed pipeline diagram against Mission Control M3.1 redesign; update other flows only if drift identified. | complete | DOC-004 | medium | software | Tess dispatch sequence diagram either (a) consistent with tess-v2 `project-state.yaml` current architecture, or (b) annotated as "soak-pending, may change" if still unstable; `updated:` bumped. |
| DOC-006 | Refresh `_system/docs/architecture/05-cross-cutting-concepts.md`: add compound engineering enhancements (track schema, conditional review routing, cluster analysis from 2026-04-04); verify vault-check rule count against current `vault-check.sh`; scan for other stale conventions. | complete | DOC-005 | low | software | Compound engineering section mentions track schema + conditional review routing; vault-check rule count matches `grep -c '^=== ' _system/scripts/vault-check.sh` or similar; `updated:` bumped. |
| DOC-007 | Refresh `_system/docs/architecture/00-architecture-overview.md` terminology index and section summaries: verify all defined terms still in use; update skill count (20) and any other counts mentioned; regenerate section descriptions from refreshed 01-05. | complete | DOC-006 | low | software | Skill count in overview text = 20; terminology index has no dead terms; section descriptions reference current content of 01-05; `updated:` bumped. |
| DOC-008 | Refresh operator reference docs (8 files) surgically: skills-reference, overlays-reference, vault-structure-reference, sqlite-schema-reference, infrastructure-reference, tag-taxonomy-reference, git-commands, tmux-commands. Focus: skills-reference count; vault-structure adds lifestyle domain + Quartz if applicable; verify skills-reference (Apr 5) and tag-taxonomy-reference (Apr 7) do not contradict refreshed DOC-003. | complete | DOC-007 | low | software | `skills-reference.md` lists 20 skills matching DOC-003; `vault-structure-reference.md` mentions `lifestyle` domain; no operator reference contradicts architecture 00-05; `updated:` bumped on every touched file. |
| DOC-009 | Refresh operator how-to docs (9 files) surgically: crumb-deployment-runbook (email triage removal), rotate-credentials (OAuth redaction practice), run-feed-pipeline, triage-feed-content, update-a-skill, tailscale-setup, vault-gardening, add-knowledge-to-vault, updates-to-an-archived-project. | complete | DOC-007 | medium | software | `crumb-deployment-runbook.md` contains no email-triage setup steps; `rotate-credentials.md` mentions OAuth secret redaction or pre-commit redaction; other runbooks reflect current service list; `updated:` bumped on every touched file. |
| DOC-010 | Refresh operator tutorials (3 files) and explanation docs (4 files): first-crumb-session, first-tess-interaction, mission-control-orientation, how-crumb-thinks, why-two-agents, the-vault-as-memory, feed-pipeline-philosophy. Verify tutorials still walk through end-to-end; scan explanations for superseded model references. | complete | DOC-007 | low | software | All 3 tutorials are executable as written on 2026-04-11; no explanation doc cites Haiku 4.5 or qwen3-coder; `updated:` bumped on every touched file. |
| DOC-011 | Refresh `_system/docs/llm-orientation/orientation-map.md`: drop rows for removed skills (excalidraw, lucidchart, meme-creator, obsidian-cli); add rows for critic + deliberation; add deliberation-dispatch subagent row; recount token totals for each category and the total; update gap analysis (some gaps may now be filled). | complete | DOC-007 | low | software | Skill table row count = 20; every row's file exists; subagent table has 4 rows including deliberation-dispatch; category totals arithmetic-correct against per-row values; total row count is internally consistent; `updated:` bumped. |
| DOC-012 | Close-out cross-reference consistency check: verify skill count, subagent count, overlay count, and model routing claims match across `02-building-blocks.md`, `skills-reference.md`, and `orientation-map.md`. Flag any discovered design-spec drift as follow-on project (do not fix). Update progress-log with ACT completion. | complete | DOC-008, DOC-009, DOC-010, DOC-011 | low | software | Skill count identical in all 3 named docs; subagent count identical; no doc contradicts another on Tess Voice/Mechanic model; progress-log has ACT-complete entry with summary; any design-spec drift flagged in run-log. |

## Dependency Summary

- DOC-001 is the entry point (M1)
- DOC-002 → DOC-003 → DOC-004 → DOC-005 → DOC-006 → DOC-007 is the strict M2 chain
- DOC-008, DOC-009, DOC-010 (M3 batch) and DOC-011 (M4) run in parallel after DOC-007
- DOC-012 (M5 close-out) blocks on all M3 + M4 tasks

## Risk Distribution

- **Medium:** DOC-003, DOC-004, DOC-005, DOC-009 (4 tasks)
- **Low:** DOC-001, DOC-002, DOC-006, DOC-007, DOC-008, DOC-010, DOC-011, DOC-012 (8 tasks)
- **High:** none

## File Change Footprint (scoping check)

All tasks touch ≤5 files except DOC-008 (8 files), DOC-009 (9 files), DOC-010 (7 files). Exceptions accepted because these are surgical-edit batches within a single Diátaxis quadrant — each file gets minimal edits (verify against current state, bump `updated:` if touched), not substantive rewrites. If any individual file in the batch proves to need substantial work, it splits into its own task.
