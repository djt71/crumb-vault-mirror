---
type: reference
domain: software
status: active
created: 2026-02-21
updated: 2026-06-12
tags:
  - system
---

# Claude.ai Context Checkpoint

Orientation artifact for a fresh session reading this repo (claude.ai chat, a
new Claude Code session, or any agent cloning `github.com/djt71/crumb-vault`).
Read this first — it is sufficient for most questions.

Last updated: 2026-06-12. **The agentic infrastructure decommission is nearly
complete** — project `agentic-sunset`: the self-built always-on agent stack
(Tess/OpenClaw/Hermes) drifted from original intent, produced zero revenue, and
~90% of its function is now native in Claude.AI / Claude Code.

- **Dark since 2026-06-10/11:** all agentic launchd labels + Ollama booted out
  (incl. the system-level `ai.openclaw.gateway` LaunchDaemon survivor found at
  the first quiet check). Plists archived (git-tracked) in
  `_system/archive/launchagents-retired/`. Telegram silence is intentional.
  healthchecks.io check `tess-mac-studio-health` paused.
- **AS-016 quiet gate GREEN 2026-06-12**, then M3/M5/M6 executed same day:
  backup jobs relabeled to `com.crumb.*` (3 AM scheduled-fire confirmation
  2026-06-13); vault-health rebuilt log-only (no Telegram, no `_openclaw/`
  deps); README-ARCHIVED breadcrumbs in all 7 runtime dirs; daily-attention
  replacement **declined** (on-demand attention-manager only — see
  `Projects/agentic-sunset/design/upstream-migration.md`); CLAUDE.md
  bridge-dispatch section removed; **vault `_openclaw/`, `_tess/`,
  `_staging/TV2-*` archived to `Archived/`** (pipeline.db external, spared);
  feed-pipeline skill retired; churn logs gitignored.
- **Remaining:** AS-021 reboot test + AS-022 dormant-plist sweep (operator-
  assisted), AS-030 closeouts, AS-031 7-day soak, AS-032 compound/archival.
- **Model policy:** Crumb runs both Opus 4.8 and Fable 5 (top-tier frontier
  models only — tier is the non-negotiable, not the model line).

Previous update 2026-06-01 (full regeneration). The 38 days since the prior
update (2026-04-24) were dominated by an **infrastructure decommission wave**
and a **tess-v2 role narrowing**, not new feature work:

- **Decommission wave (teardown-discipline).** Many services were torn down as
  "output nobody acts on" or "producer outlived its consumers": FIF capture
  (2026-05-28), the opportunity-scout daily pipeline (2026-05-28, operator-directed),
  `overnight-research` + `connections-brainstorm` (2026-06-01), the
  `service-status` sensor + `health-check` failover + `v2-awareness-check`
  heartbeat (2026-06-01), and the Mission Control **dashboard was stopped**
  (project kept active, not archived). Root pattern codified in
  `_system/docs/solutions/infrastructure-teardown-discipline.md`: ephemeral infra
  must declare a teardown owner; decommissioning a producer sweeps its
  consumers/watchers/registry/docs in the same pass; **liveness signals ≠
  correctness signals** (a frozen `overnight-research` emitted a byte-identical
  brief for 26 days while every health check read green). Six hot-churn logs
  (incl. `vault-check-output.log`, written by the pre-commit hook itself) were
  gitignored — they had kept the tree permanently dirty.
- **tess-v2 Amendment AC (draft, 2026-04-21).** Retracts AD-013
  (Tess-as-orchestrator) on live-evidence grounds; scopes Tess to **autonomous
  execution of scheduled launchd services only**. Operator-facing
  planning/dispatch moves upstream (claude.ai / Cowork / Remote Control);
  Crumb-Claude Code remains Level-3 execution. Amendment Z marked superseded
  (schemas retained). Tess runtime is **in flux** — 2+ weeks of Kimi K2.5 →
  GPT-5.4 experimentation; GPT-5.4 soak observation is an open follow-up.
- **New project:** `obsidian-applenotes-import` (PLAN). **Archived this period:**
  `agent-to-agent-communication`, plus `vault-mobile-access`.
- **Vault audit (2026-06-01):** fixed 4 silently-broken skill `required_context`
  links (path renames / solutions-tree flattening) + convention drift; dashboard
  health back to green.

For older session history, read `_system/logs/session-log.md` (non-project work)
and per-project `progress/run-log.md` (project work) — do not reconstruct it from
this file.

## Context Budget — READ THIS FIRST

This repo is large (~3,200 files). **Do not read them all.** Reading everything
would consume most of your context window and degrade response quality.

**Rules:**
1. This file gives you full orientation — sufficient for most questions
2. Only read additional files when the user's task specifically requires them
3. Read the **smallest file that answers the question** (summaries before full docs, run-logs before specs)
4. Never `ls -R` or bulk-read directories — use the file index below to pick targeted files
5. Budget: aim for ≤5 source files read per session beyond this one

The heaviest files (avoid unless specifically needed):
- `_system/docs/crumb-design-spec-v2-4.md` — full system spec, 260k+ chars; read specific sections only
- `_system/docs/separate-version-history.md` — changelog
- `_system/reviews/` — peer-review transcripts, 25–65k chars each

## System Overview

Crumb is a personal multi-agent OS built on Claude Code, using an Obsidian vault
as external memory and single source of truth. Canonical spec:
`_system/docs/crumb-design-spec-v2-4.md`.

- **Vault location:** Mac Studio (`tess@`), accessed via SSH from work Mac
- **Obsidian:** runs on the Studio. Both instances can run simultaneously — `workspace.json` is gitignored
- **Claude Code sessions:** run on the Studio
- **Tess (OpenClaw agent):** decommissioned 2026-06-10; former bridge dir lives at `Archived/_openclaw/`
- **Validation gate:** `_system/scripts/vault-check.sh` (pre-commit hook)
- **Counts (verified 2026-06-12):** 19 skills · 8 overlays · 9 canonical domains
- **Domains:** software, career, learning, health, financial, relationships, creative, spiritual, lifestyle

## Strategic Directive: Liberation

**Governing document:** `_system/directives/liberation-directive.md` (v3, 2026-06-11 — constitution: three-pillar mission, six gates, two tracks; philosophy wins on conflict)

Mission: build enough independent revenue that corporate work becomes a choice,
not a dependency. Revenue-generating work gets priority claim on sessions; all
other work continues in parallel (three tiers: active / standing-latent / noise).

**Work surfaces:** live roster + write-boundary classes are in the work-surfaces
doc (7 surfaces incl. the Glean airlock, verified 2026-06-11). Tess/OpenClaw
decommissioned 2026-06-10; Perplexity subscription cancelled 2026-06-11;
`_inbox/` is the universal intake (`_openclaw/inbox/` defunct and archived).

Primary revenue bet: **Firekeeper Books** (Prompt 1).

## Active Projects

State below is pulled from each project's `project-state.yaml` (authoritative).
Directory location is authoritative for archived-vs-active; project docs carry no status field.

### tess-v2 — software / system / four-phase  *(closing: → DONE at agentic-sunset AS-030)*
- **Phase:** IMPLEMENT · **active_task:** TV2-057d · **updated:** 2026-06-01
- **Status:** Tess v2 sole-operator on a reduced launchd service set (was ~15 at cutover; trimmed hard by the decommission wave). Amendment AC (draft) narrows Tess to scheduled-services-only execution and retracts the orchestrator role; Amendment Z superseded. 23 Category-A engineering patterns extracted to `_system/docs/tess-v2-durable-patterns.md` (survive project narrowing). Runtime: Kimi K2.5 → GPT-5.4 experimentation underway.
- **Next:** ratify AC via operator approval, then upstream-work-bridge analysis OR resume TV2-057d promotion wiring (operator discretion). Open follow-ups: GPT-5.4 soak, persona-spec durable home, K2-family retest pinning, AD-008 supersession doc.
- **Key files:** `Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md`, `Projects/tess-v2/progress/run-log.md`; repo `/Users/danny/crumb-apps/tess-v2/`

### customer-intelligence — career / knowledge / three-phase
- **Phase:** ACT · **updated:** 2026-04-27
- **Status:** Full pipeline validated E2E on ACG: Extract (Glean agents + DNS recon) → Curate → Generate (account summary + meeting prep).
- **Next:** consult `Sources/insights/staging-curation-pattern-transfer.md` (human-attention vs. agent-unsupervised) before scaling to remaining accounts (Steelcase, BorgWarner next).
- **Key files:** `Projects/customer-intelligence/progress/run-log.md`, `Domains/career/accounts/`

### firekeeper-books — creative / personal / two-phase  *(primary revenue bet)*
- **Phase:** ACT · **updated:** 2026-04-07 *(project-state stale — due a status refresh)*
- **Status:** Fiction-first illustrated PD ebook publishing. Title #1: Frankenstein (1818). Title #2: The Odyssey (timed to Nolan film, 2026-07-17). $7.99, wide-first.
- **Next (per last update):** AI-art learning plan — Phase 1 (Tool Fluency) → Phase 2 (Style Development). Trackables in `ai-art-inventory.md`, surfaced via attention-manager.
- **Key files:** `Projects/firekeeper-books/ai-art-learning-plan.md`, `ai-art-inventory.md`, `progress/run-log.md`

### obsidian-applenotes-import — software / system / four-phase  *(new)*
- **Phase:** PLAN · **updated:** 2026-04-27
- **Status:** PLAN artifacts complete — 29 atomic tasks across 9 phases (M0 spikes + M1–M8), MAJOR scope, no cross-project deps.
- **Next:** operator decides peer-review-the-plan vs. PLAN→TASK transition; then run M0 spikes (OAI-024..027).
- **Key files:** `Projects/obsidian-applenotes-import/design/action-plan.md`, `tasks.md`; repo `/Users/danny/code/obsidian-applenotes-import`

### mission-control — software / system / four-phase
- **Phase:** TASK (Phase 3) · **updated:** 2026-03-30
- **Status:** Phase 2 done (M5/M6/M7). M3.1 (Intel Feed Density Redesign) done. **The dashboard service was stopped 2026-06-01** (operator no longer wants it); project kept active, not archived.
- **Next:** M3.1 → M8 (Intel Production); M9/M10 independent. Reassess scope given dashboard pause.
- **Key files:** `Projects/mission-control/design/tasks.md`, `progress/run-log.md`; repo `/Users/danny/openclaw/crumb-dashboard`

### opportunity-scout — software / system / four-phase
- **Phase:** TASK · **updated:** 2026-05-28
- **Status:** **Daily pipeline decommissioned 2026-05-28** (operator-directed, confirmed via commit `2756dbc1` — intentional, not an outage). Triage had been upgraded to Sonnet + 4-gate scoring with three-tier priority framing before shutdown.
- **Next:** project not yet archived; phase field predates the decom — needs an operator decision (archive vs. retain).
- **Key files:** `Projects/opportunity-scout/progress/run-log.md`; repo `~/openclaw/opportunity-scout`

### semuta — software / system / four-phase
- **Phase:** PLAN · **updated:** 2026-03-18
- **Status:** External-review synthesis agent. Spec peer-reviewed, action plan complete.
- **Next:** PLAN→TASK transition, begin SEM-001 scaffolding.
- **Key files:** `Projects/semuta/design/specification.md`; repo `~/openclaw/semuta`

### feed-intel-framework — software / system / four-phase
- **Phase:** DONE · **updated:** 2026-05-28
- **Status:** Phase 1 complete (M1–M5, 5 adapters: X/RSS/YouTube/HN/arXiv). **Capture decommissioned 2026-05-28** (services list now empty). Reddit adapter code done, API credentials pending. M6/M7 were deferred as Phase 2.
- **Key files:** `Projects/feed-intel-framework/progress/run-log.md`; repo `/Users/danny/openclaw/feed-intel-framework`

### think-different — learning / KB exception
- **Phase:** ARCHIVED, but kept in `Projects/` (not `Archived/`) because it holds 45 biographical profiles in the active knowledge graph. `updated:` 2026-02-18.

## Live Services (verified via `launchctl`, 2026-06-12 post-M3)

One clean `com.crumb.*` generation — 10 labels, zero `com.tess.*`/`ai.*`:
- **Plumbing:** com.crumb.{vault-backup 3am, backup-status 15m, drive-sync 5am, vault-gc 4am, vault-health 2am, system-stats, qmd-index 5:30am}
- **Publishing/dashboard stack:** com.crumb.{cloudflared, vault-web, vault-rebuild}; `com.crumb.dashboard` plist exists but the service was deliberately stopped 2026-06-01 — restart is an operator decision (kept for possible repurpose)

Everything agentic is retired — plists in `_system/archive/launchagents-retired/`, runtimes archived-in-place on disk with README-ARCHIVED breadcrumbs. Do not expect Telegram traffic, hc-ping pings, or `_openclaw/` churn. Known TCC quirk: launchd can't list the iCloud backup dir — backup-status uses a marker-file fallback; retention prune runs from the session-startup hook.

## Recent Key Decisions

- **Infrastructure teardown discipline (2026-06-01):** a rename or decommission of any producer/path must sweep its consumers in the same pass — runtime watchers, the service *registry* (`tess-v2/project-state.yaml` `services:`), and descriptive docs all count. Liveness ≠ correctness. Don't version-control artifacts your own toolchain rewrites. See `infrastructure-teardown-discipline.md` (marked `linkage: discovery-only`).
- **Liberation directive → v2.1 (2026-04-21):** portfolio/surfaces extracted to `liberation-surfaces-snapshot.md`; directive now aspirations/gates/metrics only.
- **Quick-capture retired (2026-04-24):** Telegram decommissioned as input surface; capture design is Apple Notes + weekly sweep → main vault. See `capture-tiers.md` (round-trip friction principle: evaluate capture tools on total write+revisit+edit cost).
- **Write tool = frontmatter loss vector** — prefer Edit for existing files.
- **Code review (2026-02-26):** single 2-reviewer panel — Claude Opus (API, architectural) + Codex (CLI, tool-grounded).
- **Peer-review skill:** parallel dispatch to external LLMs (GPT / Gemini / DeepSeek / Grok families).
- **Session-log domains:** exactly the 8 work domains, no "cross-cutting"/"other".
- **Historical log entries are immutable** (grep exclusions in vault-check).

## Open Items

- **agentic-sunset endgame:** AS-018 3 AM fire check (2026-06-13), AS-021/022 (operator: reboot + sudo sweep), AS-030 closeouts (tess-v2 → DONE, tess-danny-migration → DONE, XD sweep), AS-031 soak, AS-032 compound routing.
- **opportunity-scout & feed-intel-framework:** pipelines decommissioned but projects not archived — archival proposals come at AS-032.
- **firekeeper-books project-state stale** (2026-04-07) — primary revenue bet is due a status refresh.
- **Stale skill body-text residuals:** audit §15 (Tess harness audit), learning-plan §7 (Tess check-ins), researcher (bridge-dispatch invocation rows) reference dead infra — descriptions are clean (AS-028); route body cleanup via vault-optimization or next audit.

## Architecture Notes

- **Workflow routing:** software = four-phase (SPECIFY → PLAN → TASK → IMPLEMENT); knowledge work = three-phase (SPECIFY → PLAN → ACT); personal = two-phase (CLARIFY → ACT).
- **Spec is source of truth** for system design — don't improvise from memory.
- **Context budget:** ≤5 source docs per skill invocation (standard), 6–8 extended, 10 ceiling.
- **Overlays (8):** business-advisor, career-coach, design-advisor, financial-advisor, glean-prompt-engineer, life-coach (+ personal-philosophy companion), network-skills (+ source-catalog companion), web-design-preference. Loaded from `_system/docs/overlays/` per the overlay index.
- **Compound engineering** runs at every phase transition (structurally enforced). Solution docs use a track-based schema (`track: bug | pattern | convention`). Docs that have no natural skill `required_context` host may opt out with `linkage: discovery-only`.

## File Index — Read Selectively

Start with run-logs (small, recent state) before specs (large, full design). Read only what the task needs.

**System (large — read sparingly):**
- `CLAUDE.md` — project instructions, workflow rules
- `_system/docs/crumb-design-spec-v2-4.md` — full spec (read specific sections only)
- `.claude/skills/<name>/SKILL.md` — read only the skill relevant to the task

**Per-project:** `Projects/<name>/progress/run-log.md` (recent state) → `Projects/<name>/design/` (plans/specs).

**Reference:** `_system/docs/operator/reference/` (skills-, overlays-, infrastructure-reference) · `_system/docs/solutions/` (compound patterns) · `_system/logs/session-log.md` (non-project history).
