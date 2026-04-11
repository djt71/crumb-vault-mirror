---
type: reference
domain: software
status: active
created: 2026-02-21
updated: 2026-04-11
tags:
  - system
---

# Claude.ai Context Checkpoint

Orientation artifact for new claude.ai chat sessions. This file lives
inside the mirror repo — after cloning, read this first for context.

Last updated: 2026-04-11 (documentation-refresh-2026-04 project DONE in single session — content refresh of all three doc tracks from the archived documentation-overhaul template. Architecture, operator, and LLM orientation map updated to 2026-04-11 state. Primary drift corrected: skills 22→20 (−excalidraw/lucidchart/meme-creator/obsidian-cli; +critic/deliberation), subagents 3→4 (+deliberation-dispatch), Tess Voice Haiku→Kimi K2.5 via OpenRouter (Qwen 3.6 failover), Tess Mechanic qwen3-coder→Nemotron via com.tess.llama-server, email-triage shut down 2026-04-10 (TV2-036/037 cancelled), two-namespace service architecture (`ai.openclaw.*` legacy + `com.tess.v2.*` new) documented, `lifestyle` added as 9th canonical domain. Cross-reference consistency verified: skill count 20 and subagent count 4 agree across architecture 02, skills-reference, orientation map, and filesystem. Design-spec drift at `crumb-design-spec-v2-4.md` lines 243 and 1504 (dead skill references) flagged as follow-on.)

Previous session (2026-04-09 → 2026-04-10): TV2-043 gate eval failed and remediated with 3 stacked defects (PATH, stdout-capture, no feedback-poller plist). Re-soak window 2026-04-09 → 2026-04-12. Compound finding: soak validation by contract pass/fail alone is insufficient — needs explicit external-truth comparison. Email triage migrated from Haiku→local Nemotron then shut down entirely 2026-04-10.

## Context Budget — READ THIS FIRST

This repo contains ~112 files (~365k tokens). **Do not read them all.**
Reading everything would consume most of your context window and degrade
response quality for the rest of the session.

**Rules:**
1. This file gives you full orientation — it is sufficient for most questions
2. Only read additional files when the user's task specifically requires them
3. Read the **smallest file that answers the question** (summaries before full docs, run-logs before specs)
4. Never `ls -R` or bulk-read directories — use the file index below to pick targeted files
5. Budget: aim for ≤5 files read per session beyond this one

The heaviest files (avoid unless specifically needed):
- `_system/docs/crumb-design-spec-v2-4.md` — 260k+ chars, full system spec
- `_system/docs/separate-version-history.md` — 88k chars, changelog
- `_system/reviews/` — 25-65k chars each, peer review transcripts

## System Overview

Crumb is a personal multi-agent OS built on Claude Code, using an Obsidian
vault as external memory and single source of truth. The canonical spec is
`_system/docs/crumb-design-spec-v2-4.md` (v2.4, AKM + researcher + overlay expansion).

- **Vault location:** Mac Studio (`tess@`), accessed via SSH from work Mac
- **Obsidian:** runs on Studio, not work Mac. Close before `git mv` operations. Both instances can run simultaneously — `workspace.json` is gitignored.
- **Claude Code sessions:** run on the Studio
- **Tess (OpenClaw agent):** communicates via `_openclaw/`
- **Validation gate:** `_system/scripts/vault-check.sh` (pre-commit hook)
- **Domains:** software, career, learning, health, financial, relationships, creative, spiritual, lifestyle

## Strategic Directive: Liberation

**Governing document:** `_system/directives/liberation-directive.md` (v1.1, 2026-03-19)

Mission: build enough independent revenue that corporate work becomes a choice, not a dependency. Six parallel prompts (execution/discovery/maintenance), four agent surfaces. Revenue-generating prompts get priority claim on sessions; all other work continues in parallel. Referenced in CLAUDE.md Workflow Routing.

**Four-surface model:**
- **Crumb** (Claude Code, Opus 4.6) — deep work, specs, strategy
- **Tess** (OpenClaw; Voice: Kimi K2.5 via OpenRouter with Qwen 3.6 failover; Mechanic: local Nemotron via `com.tess.llama-server`) — always-on execution, monitoring
- **Perplexity Computer** — research, daily operational awareness, interactive synthesis
- **Chrome** (Claude browser extension) — authenticated website actions

**Key prompts:**
1. Firekeeper Books — ship Title #1 on KDP (primary, 30-day target)
2-4. Discovery prompts via Perplexity Computer (capability scan, $1K simulation, skills arbitrage)
5. Audience strategy — build in public
6. Opportunity Scout retune

**Infrastructure:** Vault syncs to Google Drive hourly + post-commit for Perplexity Computer access. Custom skill uploaded. Morning briefing scheduled task. Gmail + Calendar connectors active.

## Active Projects

### customer-intelligence
- **Domain:** career | **Class:** knowledge | **Workflow:** three-phase
- **Phase:** ACT
- **Status:** Full pipeline validated E2E on ACG: Extract (3 Glean agents + DNS recon) → Curate (authority hierarchy, dedup, noise filtering, DNS integration, refresh preservation) → Generate (account summary + meeting prep). All pipeline components validated. Account artifacts at `Domains/career/accounts/[slug]/`.
- **Next action:** Scale pipeline to remaining accounts (Steelcase, BorgWarner first, then new accounts).
- **Key files:** `Projects/customer-intelligence/`, `Domains/career/accounts/`

### feed-intel-framework
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** DONE
- **Status:** Phase 1 complete (M1–M5, 43 tasks). FIF-043 soak PASS: 7 consecutive clean days, $7.19/mo projected, 0 errors across 56 runs. 5 adapters live (X, RSS, YouTube, HN, arXiv). Reddit adapter code done, API credentials pending. M6/M7 deferred as Phase 2.
- **Key files:** `Projects/feed-intel-framework/progress/run-log.md`

### tess-operations
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** DONE
- **Status:** All tasks complete (53 done + 4 dropped + 3 late additions done). Superseded by tess-v2 for future Tess work.
- **Key files:** `Projects/tess-operations/progress/run-log.md`

### autonomous-operations
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** DONE
- **Status:** Phase 1 complete. M4 soak PASS: 100% replay, 100% post-AO-003 dedup, 29.6% acted-on rate. Context coverage 65% accepted (pathless items by design). Phase 2 (labeling, advanced scoring) would be a new project.
- **Key files:** `Projects/autonomous-operations/progress/run-log.md`

### opportunity-scout
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** TASK (M0+M1 complete, M2 behavioral validation in progress)
- **Status:** Daily pipeline live. Triage upgraded to Sonnet + 4-gate scoring. 30-day M2 soak started 2026-03-16.
- **Key files:** `Projects/opportunity-scout/design/tasks.md`, `Projects/opportunity-scout/progress/run-log.md`

### mission-control
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** TASK (Phase 2 complete, Phase 3 in progress — M3.1 done)
- **Status:** Phase 2 done (M5/M6/M7). M3.1 (Intelligence Feed Density Redesign) complete — Surface-inspired dense list layout replacing cards (5x density improvement), multi-axis filter bar (Tier/Source/Topic/Format/Origin with faceted counts), tier badges, format normalization, triage_tags for topics, Saved/Discovery origin filter. Spec Amendment S applied to §6.3.
- **Next action:** Phase 3 continues: M8 (Intel Production), M9 (Agent Activity), M10 (Customer/Career). M3.1 Phase 2 deferred items: read/unread state, time-bucketed counts, view mode toggle.
- **Key files:** `Projects/mission-control/design/tasks.md`, `Projects/mission-control/progress/run-log.md`

### firekeeper-books (Firekeeper Books)
- **Domain:** creative | **Class:** personal | **Workflow:** two-phase (CLARIFY → ACT)
- **Phase:** ACT
- **Status:** Fiction-first illustrated PD ebook publishing. Title #1: Frankenstein (1818 text). Title #2: The Odyssey (timed to Nolan film, Jul 17 2026). $7.99 pricing, wide-first distribution. Series name/domain/trademark cleared. Liberation Directive Prompt 1 (primary revenue bet).
- **Next action:** AI art learning plan Phase 1 (Tool Fluency) in compressed sprint Apr 7-8 after being unexecuted for 5 days — forgotten until the plan-tracking system caught it. Phase 2 (Style Development) starts Apr 8 on original schedule. Trackable items in [[ai-art-inventory]], surfaced via attention-manager. ComfyUI deferred to Phase 5 unless Midjourney constraints force re-evaluation.
- **Key files:** `Projects/firekeeper-books/ai-art-learning-plan.md` (meaning layer), `Projects/firekeeper-books/ai-art-inventory.md` (behavior layer), `Projects/firekeeper-books/design/`, `Projects/firekeeper-books/progress/run-log.md`

### semuta
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** PLAN (spec peer-reviewed, action plan complete)
- **Status:** External review synthesis agent. Spec + action plan complete, ready for TASK/IMPLEMENT.
- **Next action:** Phase transition to TASK, begin SEM-001 scaffolding.
- **Key files:** `Projects/semuta/design/specification.md`

### multi-agent-deliberation
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** TASK (Phase 3+4 complete, INTEGRATE recommended)
- **Status:** All 4 phases complete. H4 batch (8 cold artifacts), synthesis, meta-eval done. Gate recommendation: INTEGRATE — deliberation skill is production-ready. Total experiment cost: ~$2.
- **Key files:** `Projects/multi-agent-deliberation/data/`, `.claude/skills/deliberation/SKILL.md`, `progress/run-log.md`

### tess-v2
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** IMPLEMENT (transitioned 2026-04-01)
- **Status:** 14 services running on LaunchAgents (`com.tess.v2.*` namespace) managed via `tess-v2/project-state.yaml` `services:` field. 42/50 tasks done, 2 cancelled (TV2-036/037 email triage shut down 2026-04-10 after brief local-Nemotron migration). TV2-034/035/044 gates passed. **TV2-043 re-soak in progress** — C2/C3 clean, C1 had dead-letter from pre-fix claude-p scoring (fixed f056e5b). C1 soak clock reset — needs 3 clean daily runs post-fix, earliest gate pass Apr 13. Cloud stack: Kimi K2.5 primary (89/95) reaffirmed via 2026-04-08 frontier survey, Qwen 3.6 failover. Amendment Z interactive dispatch peer-reviewed (two rounds) and Phase A end-to-end loop completed 2026-04-06. Amendment AA vault semantic search landed (Phase 4a).
- **Next:** TV2-043 C1 gate re-eval earliest Apr 13. Blocked: TV2-038 (needs TV2-043). Open follow-ups: Tess-side feedback-poller plist (IDQ-004, blocks TV2-039 cutover), run-log rotation. Pending: TV2-045 Paperclip spike.
- **Key files:** `Projects/tess-v2/design/`, `Projects/tess-v2/progress/run-log.md`, repo at `/Users/tess/crumb-apps/tess-v2/`

### agent-to-agent-communication
- **Domain:** software | **Class:** system | **Workflow:** four-phase
- **Phase:** IMPLEMENT (Phase 2 — M6 complete, A2A-018 PASS)
- **Status:** A2A-018 gate PASS (scope-reduced). Crumb-side W3 pipeline validated (2 dispatches). Tess-side delivery deferred to tess-operations. M6 complete. Next: A2A-019 (approval integration, M7) or park.
- **Key files:** `Projects/agent-to-agent-communication/tasks.md`, `Projects/agent-to-agent-communication/progress/run-log.md`

## Completed / Archived Projects

All in `Archived/Projects/` unless noted. Think-different stays in `Projects/` (KB exception — 45 biographical profiles).

| Project | Notes |
|---------|-------|
| active-knowledge-memory | QMD knowledge surfacing. Session-start trigger removed (2026-03-20), skill-activation + new-content retained. |
| attention-manager | Daily attention skill. 30-day soak through Apr 8. |
| batch-book-pipeline | 343 notes in Sources/books/. |
| book-scout | OpenClaw book recommendation pipeline. |
| crumb-tess-bridge | Telegram bridge + dispatch protocol. 897 tests. |
| deck-intel | PPTX/PDF extraction skill. |
| documentation-overhaul | Arc42 + Diátaxis + LLM orientation. |
| documentation-refresh-2026-04 | 2026-04-11 content refresh of overhaul output: skill inventories, Tess model routing, two-namespace service architecture. 12 tasks, one session. |
| inbox-processor | File intake + routing skill. |
| knowledge-navigation | QMD collections + MOC system. |
| mcp-workspace-integration | Google Workspace MCP access (94 tools). |
| notebooklm-pipeline | NLM-to-Crumb pipeline. |
| openclaw-colocation | Blocked on Studio hardware. |
| pydantic-ai-adoption | ADR deferred pending MCP findings. |
| researcher-skill | 6-stage research pipeline. E2E validated. |
| tess-model-architecture | Voice (Haiku) + Mechanic (qwen3-coder). |
| vault-mirror | GitHub mirror + Perplexity Computer sync. |
| vault-restructure | Phases 0-3 complete. |
| x-feed-intel | Legacy X pipeline, replaced by FIF. |
| openclaw-colocation | DONE | OpenClaw v2026.2.25 deployed (upgraded from v2026.2.17). Supervisor migrated LaunchAgent→LaunchDaemon (system/ domain). 10/10 verification checks pass. Spec updates (U1-U11) and pre-reboot checklist (TMA §9) pending. |
| inbox-processor | DONE | All deliverables complete |
| think-different | ARCHIVED | All deliverables complete |
| crumb-tess-bridge | DONE | 37 tasks, 897 tests, bridge operational. Dispatch protocol + quick-capture. |
| pydantic-ai-adoption | DONE | Empirical spike + falsifiable checkpoint → NO-GO on pydantic-evals (25 deps for 31 tests). Pivoted to pytest. 31 tests for AO decision paths (idempotency, correlation, signal assembly). |
| x-feed-intel | DONE | Decommissioned 2026-03-08 — replaced by feed-intel-framework. Repo preserved for reference. |

### knowledge-navigation (ARCHIVED 2026-03-07)
- **Domain:** learning | **Class:** knowledge | **Workflow:** three-phase
- **Phase:** ARCHIVED (Phases 1-3 complete, Phase 4 declined — automation is convention-level)
- **Status:** MOC system operational. 15 MOCs, 18 canonical #kb/ tags, vault-check checks 17-21+25. All deliverables in production.
- **Key files:** `Archived/Projects/knowledge-navigation/progress/run-log.md`, `Domains/Learning/moc-*.md`

### Compound Insight Pipeline (retired 2026-03-26)
- Automated Haiku cross-referencing cron retired due to escalating fabrication rate (last 3 batches: 100% skip). 9 useful insight notes produced out of 25 dispatches over 15 days. Replaced with T1 feed signal surfacing in morning briefing — Crumb handles cross-referencing during interactive sessions with full vault access.

### New: Research Brief Review Protocol (2026-03-19)
- **Protocol:** `_system/docs/protocols/research-brief-review-protocol.md`
- **Flow:** Tess produces research briefs → Crumb triages (PROMOTE/ARCHIVE/DISCARD) → promoted signals get signal notes + advisory run-log entries + `pending_signals` in project-state.yaml
- **Key design:** `pending_signals` is a mechanical attention flag in project-state.yaml — ensures signals aren't ignored during session reconstruction. Transient: cleared after evaluation at project resume. Recommendations are advisory — Crumb decides whether to implement at resume time.

## Recent Key Decisions

- `_system/` prefix sorts to top in Obsidian — UX is "system dirs as header band"
- Symlinks rejected for project-affiliated docs — using wikilink reference notes instead
- Peer-review skill: parallel dispatch, 4 reviewers (GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning)
- Code review overhaul (2026-02-26): replaced 2-tier system with single 2-reviewer panel — Claude Opus (API, architectural depth) + Codex GPT-5.3-Codex (CLI, tool-grounded verification in read-only sandbox)
- Session-log domains: exactly 8 real domains, no "cross-cutting" or "other"
- `.obsidian/` and `_inbox/` gitignored (machine-specific / transient staging)
- Historical log entries are immutable — grep exclusions in vault-check
- Write tool identified as frontmatter loss vector — prefer Edit for existing files

## Open Items

- **Vault mirror project:** DONE — mirror operational at `github.com/djt71/crumb-vault-mirror`, post-commit hook auto-syncs, PAT clone verified.
- **Phase 4 (logs → _system/logs/):** deferred from vault-restructure, revisit after 1 week with Phase 0-3 results
- **Obsidian CLI:** works via full path only, `links broken` command available, one false positive (bill-bernbach) — parked
- **Work Mac settings.local.json:** cleaned up space-separated permission patterns, monitoring for approval fatigue recurrence

## Architecture Notes

- **Workflow routing:** Software projects use four-phase (SPECIFY → PLAN → TASK → IMPLEMENT); knowledge work uses three-phase (SPECIFY → PLAN → ACT); personal uses two-phase (CLARIFY → ACT)
- **Spec is source of truth** for system design — don't improvise from memory
- **Context budget:** ≤5 source docs per skill invocation (standard), 6-8 extended, 10 ceiling
- **Overlays** add lens questions to skills — loaded from `_system/docs/overlays/`. 8 active: Business Advisor, Career Coach, Design Advisor, Financial Advisor, Glean Prompt Engineer, Life Coach (+ personal-philosophy companion doc), Network Skills (+ source catalog companion doc), Web Design Preference
- **Compound engineering** runs at every phase transition — structurally enforced. Solution docs use track-based schema (`track: bug | pattern | convention`) with structured body sections per track. Code review skill has conditional diff-signal routing (Step 4b) and finding cluster analysis (Step 7b, gated at 3+ findings).

## File Index — Read Selectively

All files below are in this repo. **Read only what the current task needs.**
Start with run-logs (small, recent state) before specs (large, full design).

**System (read sparingly — these are large):**
- `CLAUDE.md` — project instructions, workflow rules (~12k chars)
- `_system/docs/crumb-design-spec-v2-0.md` — full system spec (~260k chars, read only specific sections)
- `.claude/skills/` — skill definitions (read only the skill relevant to the task)

**Active project — customer-intelligence:**
- `Projects/customer-intelligence/progress/run-log.md` — recent state (start here)
- `Projects/customer-intelligence/design/` — plans and specs

**Active project — researcher-skill:**
- `Projects/researcher-skill/progress/run-log.md` — recent state (start here)

**Archived project — notebooklm-pipeline:**
- `Archived/Projects/notebooklm-pipeline/progress/run-log.md` — project history
- Durable deliverables: `_system/docs/templates/notebooklm/`, `Sources/`, `.claude/skills/inbox-processor/SKILL.md`
