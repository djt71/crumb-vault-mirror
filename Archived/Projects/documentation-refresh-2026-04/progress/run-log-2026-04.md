---
type: run-log
project: documentation-refresh-2026-04
domain: software
created: 2026-04-11
updated: 2026-04-11
---

# Run Log — documentation-refresh-2026-04

## 2026-04-11 — Project created

**Trigger:** User flagged documentation staleness; archived documentation-overhaul project used as template.

**Scope confirmed with user:**
- All three tracks (architecture, operator, llm-orientation)
- Driver: staleness refresh (not specific known gaps)
- Workflow: SPECIFY → PLAN → ACT (knowledge-work)

**Related project:** Archived/Projects/documentation-overhaul (2026-03-14) — provides authoritative structure, file locations, and conventions. This project refreshes content within that structure; does not redesign it.

**Phase:** SPECIFY — staleness survey complete, spec and summary drafted.

### Context Inventory (SPECIFY)

- `Archived/Projects/documentation-overhaul/project-state.yaml` — template phase/gate ref (1 doc)
- `Archived/Projects/documentation-overhaul/design/specification-summary.md` — structure/file-location template (1 doc)
- `Archived/Projects/documentation-overhaul/design/action-plan-summary.md` — milestone template (1 doc)
- `_system/docs/architecture/00-architecture-overview.md` — current state sample (1 doc)
- `_system/docs/architecture/02-building-blocks.md` — primary drift source (1 doc, partial read)
- `_system/docs/architecture/04-deployment.md` — process model drift source (1 doc, partial read)
- `_system/docs/architecture/01-context-and-scope.md` — actor/model drift source (1 doc, partial read)
- `_system/docs/llm-orientation/orientation-map.md` — orientation drift source (1 doc)

Total: 8 docs. Extended tier (justification: staleness survey requires actual-state comparison against multiple authoritative docs). Plus filesystem state queries (skill/agent/overlay/script counts) and git log of commits since 2026-03-14.

### Staleness Signal Summary

Primary drift: skill count (22→20), subagent count (3→4), Tess Voice/Mechanic model routing, email-triage service shutdown, `lifestyle` canonical domain addition, Tess-v2 Amendment Z interactive dispatch, Quartz vault mobile access, compound engineering enhancements. Captured in spec Facts section with commit/date attribution.

### Outputs

- `design/specification.md` (12-task plan)
- `design/specification-summary.md`

### Peer Review

MINOR classification — skipped. Content refresh within validated structure.

### Next

User review of spec → approval → transition to PLAN (action-architect).

### Phase Transition: SPECIFY → PLAN

- **Date:** 2026-04-11
- **SPECIFY outputs:** `design/specification.md`, `design/specification-summary.md`
- **Goal progress:** SPECIFY acceptance met — spec drafted, user approved. Project-level acceptance criteria (6) are forward-looking; validated as measurable.
- **Compound:** No compoundable insights. The SPECIFY approach (read archived-project spec first, identify what's structure vs. content, scope to content refresh) is an application of existing Ceremony Budget Principle — not a new pattern worth capturing.
- **Context usage:** ~25% (estimated — well under 50% threshold)
- **Action taken:** none (no compact/clear needed)
- **Key artifacts for PLAN:** `specification-summary.md` is the primary input for action-architect.

## 2026-04-11 — PLAN phase

**Inputs loaded:** `specification-summary.md` (in-memory from SPECIFY phase). Skipped signal scan (content refresh) and overlay check (no strategic trade-offs).

**Outputs:**
- `design/action-plan.md` — 5 milestones, dependency graph, phase breakdown
- `design/action-plan-summary.md`
- `design/tasks.md` — 12 atomic tasks with binary acceptance criteria

**Peer review:** LOW — skipped.

**Scoping exception logged:** DOC-008 (8 files), DOC-009 (9 files), DOC-010 (7 files) exceed the ≤5-file heuristic. Accepted as surgical-edit batches within single Diátaxis quadrants; any file needing substantive rewrite splits out mid-ACT.

**Phase status:** PLAN approved by operator.

### Phase Transition: PLAN → ACT

- **Date:** 2026-04-11
- **PLAN outputs:** `design/action-plan.md`, `design/action-plan-summary.md`, `design/tasks.md`
- **Goal progress:** PLAN acceptance met — plan drafted with 12 tasks, 5 milestones, dependency graph, acceptance criteria per task.
- **Compound:** No compoundable insights from PLAN. Task decomposition followed spec directly with minor formalization.
- **Context usage:** ~35% (estimated)
- **Action taken:** none
- **Key artifacts for ACT:** `tasks.md` is the primary execution reference; `specification.md` for deeper context.

## 2026-04-11 — DOC-001: Live state capture (M1 closeout)

**Live launchctl state (filtered to relevant services):**

Four service namespaces coexist — this is a significant finding that must be reflected in `04-deployment.md`:

1. **`ai.openclaw.*` (legacy Tess operations, pre-TV2):**
   - `ai.openclaw.bridge.watcher` — running (pid 745), Python KeepAlive, `/Users/tess/Library/LaunchAgents/ai.openclaw.bridge.watcher.plist`
   - `ai.openclaw.fif.feedback` — running (pid 742)
   - `ai.openclaw.fif.capture`, `ai.openclaw.fif.attention` — loaded, awaiting interval
   - `ai.openclaw.health-ping`, `awareness-check`, `daily-attention`, `overnight-research`, `vault-health` — loaded, awaiting interval
   - `ai.openclaw.email-triage` — loaded (should be verified as intentionally retained vs. zombie)

2. **`com.tess.v2.*` (new TV2 operations, current authoritative set — 14 services per `tess-v2/project-state.yaml`):**
   - `com.tess.v2.health-ping`, `awareness-check`, `backup-status`, `vault-health`, `vault-gc`
   - `com.tess.v2.fif-capture`, `fif-attention`, `fif-feedback-health`
   - `com.tess.v2.connections-brainstorm`, `daily-attention`, `overnight-research`
   - `com.tess.v2.scout-pipeline`, `scout-weekly-heartbeat`, `scout-feedback-health`
   - Plus in-launchctl but not in tess-v2 services list: `scout-feedback-poller` (pid 34516, status 1 — see IDQ-004 "create Tess-side poller plist"), `email-triage` (pid 92215 — cancelled per TV2-036/037 but still loaded; likely needs explicit unload)

3. **`com.crumb.*` (Crumb-side operations):**
   - `com.crumb.cloudflared` — running (pid 756)
   - `com.crumb.dashboard` — running (pid 735, Mission Control)
   - `com.crumb.vault-web` — running (pid 761, Quartz mobile site)
   - `com.crumb.vault-gc`, `qmd-index`, `system-stats`, `service-status`, `telemetry-rollup`, `vault-rebuild` (exit 1)

4. **`com.tess.*` (Tess-side supporting services):**
   - `com.tess.llama-server` — running (pid 757) — Nemotron inference server
   - `com.tess.nemotron-load` — model load helper
   - `com.tess.vault-backup`, `health-check`, `backup-status`, `soak-monitor`

**tess-v2 project phase:** IMPLEMENT. 42/50 tasks done, 2 cancelled (TV2-036/037 email triage shut down 2026-04-10). TV2-043 re-soak in progress: C2/C3 clean, C1 had dead-letter from pre-fix scoring (fixed f056e5b). C1 soak clock reset, earliest gate pass Apr 13.

**Bridge-watcher service shape:** Unchanged since original architecture doc. Python-based, KeepAlive, path `/Users/tess/Library/LaunchAgents/ai.openclaw.bridge.watcher.plist`. The `ai.openclaw.*` namespace here is legacy — functions have been duplicated into `com.tess.v2.*` for most services, but bridge-watcher remains on the ai.openclaw namespace.

**Unknowns resolved:**
- ✅ Live `launchctl list` captured — `04-deployment.md` process model needs substantial rework (two-namespace architecture)
- ✅ tess-v2 phase (IMPLEMENT) and soak state (TV2-043 C1 clock reset) confirmed
- ✅ Bridge-watcher unchanged
- ⚠️ Tess-v2 Amendment Z interactive dispatch: tess-v2 is in IMPLEMENT (42/50), Phase 4a vault semantic search landed — safe to document at high level; annotate sequence-diagram details as "soak-pending" where unstable

**New finding (not in spec):** Two-namespace service architecture (ai.openclaw.* legacy + com.tess.v2.* new) is a material change that spec did not anticipate. DOC-004 scope expands to document both namespaces and the migration state. Still within "refresh" envelope — no new section needed, just more comprehensive process-model diagram.

**DOC-001 state:** complete. Proceeding to DOC-002.

## 2026-04-11 — M2 Architecture Refresh complete (DOC-002..DOC-007)

All 6 architecture docs refreshed. Key content changes:

- **01-context-and-scope.md**: Tess Voice → Kimi K2.5 (OpenRouter) + Qwen 3.6 failover. Tess Mechanic → Nemotron. Added OpenRouter as external system. Frontmatter bumped. `lifestyle` domain was already in place from an Apr 6 content edit — only frontmatter needed bumping.
- **02-building-blocks.md**: Skill table rebuilt — 20 skills (−excalidraw, −lucidchart, −meme-creator, −obsidian-cli; +critic, +deliberation). Subagent table rebuilt — 4 rows (+deliberation-dispatch). Block-beta counts updated (20 skills, 4 agents, 6 protocols, ~20 scripts). Code Mapping counts corrected. Mermaid description updated to Mermaid + Excalidraw (alt format, not separate skill).
- **04-deployment.md**: Process model diagram rebuilt to show two-namespace architecture (`ai.openclaw.*` legacy + `com.tess.v2.*` new). Email-triage removed from diagram. Ollama model corrected to Nemotron via `com.tess.llama-server`. Service inventory split into Infrastructure / Tess-v2 / Apple+cross-user tables. Credentials table: removed Lucidchart/TMDB, added OpenRouter + Cloudflare tunnel. Network topology updated with openrouter node.
- **03-runtime-views.md**: Tess Voice participant relabeled to Kimi K2.5. Triage engine in feed pipeline updated. Failure handling reflects OpenRouter failover chain. Bridge-watcher label updated to `ai.openclaw.bridge.watcher`. Added Amendment Z / tess-v2 Phase IMPLEMENT note on dispatch evolution — sequence diagram covers stable paths, interactive refinements noted as soak-pending.
- **05-cross-cutting-concepts.md**: Vault-check count updated to ~27. Code review tier 2 panel corrected to Claude Opus (API) + Codex (CLI). Compound engineering section gained 2026-04-04 enhancements (track schema, conditional review routing, cluster analysis).
- **00-architecture-overview.md**: Terminology index corrected (20 skills, ~27 vault-check rules). Section descriptions regenerated to reflect 01–05 content.

**Scope surprise:** DOC-004 discovered the two-namespace service architecture (ai.openclaw.* + com.tess.v2.*) — a material structural change the spec didn't anticipate. Still handled within refresh envelope by rebuilding the process-model diagram and service inventory table, not by adding a new section.

**M2 state:** complete. Proceeding to M3 (operator docs).

## 2026-04-11 — M3 Operator + M4 Orientation Map + M5 Close-Out

**M3 approach:** grep-driven staleness edits across all 24 operator files. Touched only files with actual stale references; left clean files alone (no frontmatter churn).

**M3 edits:**
- `rotate-credentials.md`: Removed Lucidchart + TMDB credential rows and rotation sections. Added OpenRouter row + rotation procedure. Added Cloudflare tunnel token row. Updated Telegram bot token consumers (removed email-triage, added scout services).
- `first-tess-interaction.md`: Tess Voice model row → Kimi K2.5 (OpenRouter, Qwen 3.6 failover). Tess Mechanic → Nemotron. Line 106 updated accordingly. Frontmatter bumped.
- `why-two-agents.md`: Cost section updated (Kimi K2.5 / Nemotron instead of Haiku / qwen3-coder). Frontmatter bumped.
- `vault-structure-reference.md`: Added Lifestyle domain row. Skill count 22→20. Subagent count 3→4. Script count 27→~20. Removed dead Ops/ subdirectory entry. Frontmatter bumped.
- `infrastructure-reference.md`: Service inventory rebuilt with Infrastructure / Tess-v2 / Apple tables and Legacy namespace note. Outbound endpoints: added OpenRouter and Cloudflare, removed Lucidchart. Credentials: removed Lucidchart and TMDB, added OpenRouter and Cloudflare. Bridge-watcher label corrected to `ai.openclaw.bridge.watcher`.
- `crumb-deployment-runbook.md`: API keys setup removed Lucidchart + TMDB, added OpenRouter + Cloudflare tunnel. Backup/restore sections updated. Cleanup section updated. Reference tables updated. `setup-crumb.sh` phase list updated. Frontmatter bumped.
- Reference docs (overlays-reference, skills-reference, tag-taxonomy-reference, sqlite-schema, git-commands, tmux-commands): verified no stale model/skill refs; left frontmatter alone where unchanged (skills-reference Apr 5 and tag-taxonomy Apr 7 were already correct).
- Tutorials + explanation docs (first-crumb-session, mission-control-orientation, how-crumb-thinks, the-vault-as-memory, feed-pipeline-philosophy): verified no stale refs via grep; no edits required. Obsidian "Excalidraw plugin" mentions in the-vault-as-memory.md refer to the Obsidian plugin, not the removed skill — retained.

**M4 edits (orientation map):**
- Skill table rebuilt: 20 rows. Removed excalidraw, lucidchart, meme-creator, obsidian-cli. Added critic, deliberation. Updated token estimates (rounded) and skill layer total to ~47,550.
- Subagent table: 4 rows. Added deliberation-dispatch row.
- Token Budget Summary: all counts updated (skills 22→20, subagents 3→4, total inventory 53→48, total tokens recalculated to ~86,327).

**M5 cross-reference consistency check:**
- **Skill count:** architecture 02 = 20 | skills-reference = 20 | orientation map = 20 | filesystem = 20 ✓
- **Subagent count:** architecture 02 = 4 | orientation map = 4 | filesystem = 4 ✓
- **Overlay count:** 8 across all docs (unchanged from overhaul project, verified)
- **Model routing:** All Tess Voice refs now cite Kimi K2.5 (OpenRouter / Qwen 3.6 failover). All Tess Mechanic refs now cite Nemotron. Zero residual Haiku 4.5 or qwen3-coder references in architecture, operator, or orientation map.

**Design-spec drift flagged (out of scope — follow-on):**
- `_system/docs/crumb-design-spec-v2-4.md` line 243: still references `meme-creator/SKILL.md` in directory tree
- Line 1504: still lists `obsidian-cli, meme-creator` as Phase 1 deployed skills
- Recommendation: follow-on project `design-spec-refresh` when design spec rev cycle next occurs. Not urgent — design spec is "intent authority", and these references are in structural/historical sections rather than governing logic.

**ACT state:** all 12 tasks complete. Project deliverables ready for archival-on-review.

