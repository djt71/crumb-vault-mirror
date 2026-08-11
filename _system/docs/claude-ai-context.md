---
type: reference
domain: software
status: active
created: 2026-02-21
updated: 2026-08-10
tags:
  - system
---

# Claude.ai Context Checkpoint

Orientation artifact for a fresh session reading this repo (claude.ai chat, a
new Claude Code session, or any agent cloning `github.com/djt71/crumb-vault`).
Read this first — it is sufficient for most questions.

Last updated: 2026-08-10 (point edit: **agentic-sunset COMPLETE → ARCHIVED** — AS-032 closed: operator-manual checklist executed 08-08→08-10 and verified (openclaw.json ×12 gone, agent calendars ×2 gone, provider revocations ×5 + Discord operator-attested); compound insights routed (`infrastructure-teardown-discipline.md` now four disciplines — new discipline 4 "platform absorption is a teardown trigger" + discipline 2 migration corollary "sweep every scheduler class"); XD ×6 dispositioned (005/007/009 keep-dormant, 019/020 resolved platform-absorption, 021 mooted); **three projects archived to `Archived/Projects/` in one pass: agentic-sunset, tess-v2 (KB exception answered NO — durable patterns live outside the project), tess-danny-migration**; `Projects/index.md` rebuilt from live phases (was stale since 04-21). Active roster is now 7: vault-optimization, akm-refresh, skills-library, customer-intelligence, firekeeper-books, semuta, mission-control (paused)). Prior point edit 2026-08-08 (after a 25-day vault dormancy gap 2026-07-14→08-08 — no sessions, stack ran clean unattended: **AS-032 external-artifact sweep EXECUTED 2026-07-14** (Drive Agent-tree trashed — recovery window closes ~08-13; Keychain x-feed-intel.* scrubbed; 7 revocations approved — operator-manual checklist at providers still open, see AS project-state); **VO M5 soak CLOSED 2026-08-08** by operator decision — PASS on all exercised criteria at WS5/8, Tier-1 #1–#3 unexercised → watch items; pruned config accepted as baseline; VO-036 close-out → VO-037 next; **full vault audit 2026-08-08** (weekly + monthly, follow-ups executed: 16 broken wikilinks fixed, tess-v2 VAL-001/002/003 closed superseded); **skill roster is 11** since 2026-07-07 (skills-library §C); **obsidian-applenotes-import closed + deleted 2026-08-08** (operator decision, no archival — pre-M0, no repo ever created, git-history-only)). Prior point edits 2026-07-13 (AS-031 soak v2 COMPLETE 7/7 green; GUI-login recovery rule field-proven at the 07-13 reboot), 2026-07-06 (mission statement re-aligned to directive v3) and 2026-07-05 (attention-manager retired to Cowork, 15 skills, bet portfolio empty per Gate 4 declarations). Prior full refresh 2026-07-04. **Headline changes since 06-19:** (1) the
agentic-sunset stability soak v1 **FAILED** — a headless reboot on 2026-06-18
left the stack dark 13 days (keep-set resurrection is GUI-login-gated, now a
documented operating assumption: GUI-login after every reboot, then verify
:8843 + backup-status); soak **v2 restarted 2026-07-01 → COMPLETE 7/7 green 2026-07-13**.
(2) vault-optimization **ran M4 end-to-end** (destructive batches B0–B6 all
executed 2026-07-03/04): B0 restore-drill gate passed, **B1 deleted `Archived/`
entirely** (857 tracked files + 133M untracked venvs, ~149M disk recovered;
commits `f3ee74ad`/`f00b43ca`), B2–B4 swept attachments/logs/docs/scripts/
protocols/overlays, **B5 consolidated skills 19→16** (checkpoint→audit,
diagram-capture→deck-intel, learning-plan→systems-analyst) + deleted
`_system/archive/` parked copies, and **B6 cut ceremony 31→21 steps**
(phase gates 11→6, session-end 10→7, Amendment Z session report retired,
six zombie startup counters removed). Canonical exceptions extracted first:
NLM workflow guide + vault-mirror spec → `_system/docs/`, deliberation record
store → `_system/data/deliberations/`, `_openclaw/config` 4-pack →
`Archived/Projects/agentic-sunset/design/external-artifacts/` (AS-032 sweep inputs).
**Anything formerly under `Archived/` is git-history-only now**
(`git show 49143a99:Archived/<path>`).

**The agentic infrastructure decommission is functionally
complete — only the soak + AS-032 closeout remain** (project `agentic-sunset`): the
self-built always-on agent stack (Tess/OpenClaw/Hermes) drifted from original intent,
produced zero revenue, and ~90% of its function is now native in Claude.AI / Claude Code.

- **Dark since 2026-06-10/11:** all agentic launchd labels + Ollama booted out
  (incl. the system-level `ai.openclaw.gateway` LaunchDaemon survivor found at
  the first quiet check). Plists archived (git-tracked) in
  git history (`_system/archive/` deleted 2026-07-04, delete-over-park). Telegram silence is intentional.
  healthchecks.io check `tess-mac-studio-health` paused.
- **AS-016 quiet gate GREEN 2026-06-12**, then M3/M5/M6 executed same day:
  backup jobs relabeled to `com.crumb.*` (3 AM scheduled-fire confirmation
  2026-06-13); vault-health rebuilt log-only (no Telegram, no `_openclaw/`
  deps); README-ARCHIVED breadcrumbs in all 7 runtime dirs; daily-attention
  replacement **declined** (on-demand attention-manager only; that skill was
  itself retired to Cowork 2026-07-05, `cowork-attention-handoff.md` — see
  `Archived/Projects/agentic-sunset/design/upstream-migration.md`); CLAUDE.md
  bridge-dispatch section removed; vault `_openclaw/`, `_tess/`,
  `_staging/TV2-*` archived to `Archived/` (pipeline.db external, spared) —
  **and `Archived/` itself deleted 2026-07-03 (VO-028 B1; git history is the archive)**;
  feed-pipeline skill retired; churn logs gitignored.
- **Reboot-verified 2026-06-14 (AS-021):** a cold boot resurrects exactly the
  10-label `com.crumb.*` keep-set and nothing agentic. **Corrected 2026-07-01:**
  this holds across a reboot *followed by GUI login* — resurrection is
  GUI-login-gated (LaunchAgents, not Daemons); a headless reboot leaves the
  stack dark until someone logs in (operator-accepted limitation).
  AS-022 dormant-plist sweep done 2026-06-12.
- **Closeouts done (AS-030, 2026-06-14):** tess-v2 → DONE, tess-danny-migration →
  DONE (P7 superseded), mission-control → paused; `cross-project-deps.md` swept
  (XD-026 resolved, 17 rows mooted).
- **Remaining:** AS-032 only — AS-031 soak v2 **COMPLETE 2026-07-13** (7/7
  consecutive green 2026-07-01→07-07; Day 7 backfilled from backup markers +
  Drive-side sync mtimes). AS-032 = compound routing + **external-artifact
  sweep** (Google Calendar/Drive/Discord residue + OpenRouter/OpenClaw-token/
  X-OAuth revocation decisions; inputs preserved in `design/external-artifacts/`)
  + archival proposals.
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
- `_system/docs/crumb-design-spec.md` — full system spec, 260k+ chars; read specific sections only
- `_system/docs/separate-version-history.md` — changelog
- `_system/reviews/` — peer-review transcripts, 25–65k chars each

## System Overview

Crumb is a personal multi-agent OS built on Claude Code, using an Obsidian vault
as external memory and single source of truth. Canonical spec:
`_system/docs/crumb-design-spec.md`.

- **Vault location:** Mac Studio (`tess@`), accessed via SSH from work Mac
- **Obsidian:** runs on the Studio. Both instances can run simultaneously — `workspace.json` is gitignored
- **Claude Code sessions:** run on the Studio
- **Tess (OpenClaw agent):** decommissioned 2026-06-10; the archived bridge dir was deleted with `Archived/` 2026-07-03 (git-history-only)
- **Validation gate:** `_system/scripts/vault-check.sh` (pre-commit hook)
- **Counts (verified 2026-08-08 audit):** 11 skills · 8 overlays · 9 canonical domains
- **Domains:** software, career, learning, health, financial, relationships, creative, spiritual, lifestyle

## Strategic Directive: Liberation

**Governing document:** `_system/directives/liberation-directive.md` (v3, 2026-06-11 — constitution: three-pillar mission, six gates, two tracks; philosophy wins on conflict)

Mission: continuous growth across three pillars — spiritual, mental, physical —
lived in the present tense. Money is a condition of life, not a pillar; liberation
(restructuring provision so it stops taxing growth — a gradient, no clock) is the
priority sub-goal, not the mission itself. Revenue-generating work gets priority
claim on sessions; all other work continues in parallel (three tiers: active /
standing-latent / noise).

**Work surfaces:** live roster + write-boundary classes are in the work-surfaces
doc (7 surfaces incl. the Glean airlock, verified 2026-06-11). Tess/OpenClaw
decommissioned 2026-06-10; Perplexity subscription cancelled 2026-06-11;
`_inbox/` is the universal intake (`_openclaw/inbox/` defunct and archived).

Bet portfolio: **empty, deliberately** (2026-07-05 Gate 4 declarations —
firekeeper-books and semuta both labeled hobby; incidental revenue ≠ revenue
thesis). Track 1 (endure + bank) runs by default; campaign stub unanchored.

## Active Projects

State below is pulled from each project's `project-state.yaml` (authoritative).
Directory location is authoritative for archived-vs-active; project docs carry no status field.

### vault-optimization — software / system / four-phase  *(most active)*
- **Phase:** IMPLEMENT (M5 soak CLOSED 2026-08-08) · **updated:** 2026-08-08
- **Status:** M1–M4 complete (M4 executed 2026-07-03/04: B0 restore-drill PASSED, B1 `Archived/` deleted (~149M recovered), B2–B4 attachments/logs/docs/scripts/protocols/overlays swept, B5 skills 19→16, B6 ceremony 31→21 steps + startup-counter sweep). **M5 soak closed 2026-08-08 by operator decision: PASS on all exercised criteria** (zero restores incl. a 25-day unattended stretch, zero workarounds; Tier-1 #4/#5/#6 complete) at WS5/8; #1–#3 unexercised → post-soak watch items, no gate. Pruned B0–B6 config accepted as operating baseline.
- **Next:** VO-036 close-out (validation record, operating note, operator sign-off) → VO-037 CLAUDE.md slim-down + spec §3.1/§3.3 reorg (v2.5).
- **Key files:** `Projects/vault-optimization/tasks.md`, `progress/run-log.md`, `design/changeset-b*.md`, `keep-set-manifest.md`

### agentic-sunset — software / system / four-phase  *(COMPLETE — ARCHIVED 2026-08-10)*
- **Phase:** IMPLEMENT (AS-032 only) · **updated:** 2026-08-08
- **Status:** Project complete, all 23 tasks done (AS-010–AS-032); archived 2026-08-10 as its own final act. Local teardown reboot-verified + soak-verified; external-artifact sweep fully closed 2026-08-10 (checklist executed by operator, verified where tooling allowed). Drive trash recovery window lapses ~2026-08-13 → deletion becomes permanent (goal state — tree was verified empty).
- **Surviving operating rule:** GUI login after every reboot; verify :8843 + backup-status; kickstart to close gaps (`Archived/Projects/agentic-sunset/design/service-inventory.md`).

### tess-v2 — software / system / four-phase  *(ARCHIVED 2026-08-10; closed DONE at agentic-sunset AS-030, 2026-06-14)*
- **Phase:** DONE · **active_task:** — · **updated:** 2026-06-14
- **Status:** Closed. The Tess execution layer it built was fully decommissioned by agentic-sunset (all `com.tess.v2.*` labels scrapped + reboot-verified absent at AS-021); the draft Amendment AC (which scoped Tess to scheduled-services-only) is overtaken by events — those services no longer exist. **Durable knowledge preserved independently:** 23 Category-A engineering patterns in `_system/docs/tess-v2-durable-patterns.md` + 3 `solutions/` extractions; repo retained (disable+archive, not deleted). KB-exception question answered NO at AS-032 (no `#kb/` content in the project dir — durable patterns all live outside it) → moved to `Archived/Projects/` 2026-08-10, alongside tess-danny-migration.
- **Key files:** `Archived/Projects/tess-v2/progress/run-log.md` (closeout 2026-06-14); `_system/docs/tess-v2-durable-patterns.md`; repo `/Users/danny/crumb-apps/tess-v2/`

### customer-intelligence — career / knowledge / three-phase
- **Phase:** ACT · **updated:** 2026-04-27
- **Status:** Full pipeline validated E2E on ACG: Extract (Glean agents + DNS recon) → Curate → Generate (account summary + meeting prep).
- **Next:** consult `Sources/insights/staging-curation-pattern-transfer.md` (human-attention vs. agent-unsupervised) before scaling to remaining accounts (Steelcase, BorgWarner next).
- **Key files:** `Projects/customer-intelligence/progress/run-log.md`, `Domains/career/accounts/`

### firekeeper-books — creative / personal / two-phase  *(hobby per Gate 4, declared 2026-07-05 — not a bet)*
- **Phase:** ACT · **updated:** 2026-04-07 *(project-state stale — due a status refresh)*
- **Status:** Fiction-first illustrated PD ebook publishing. Title #1: Frankenstein (1818). Title #2: The Odyssey (timed to Nolan film, 2026-07-17). $7.99, wide-first.
- **Next (per last update):** AI-art learning plan — Phase 1 (Tool Fluency) → Phase 2 (Style Development). Trackables in `ai-art-inventory.md` (attention-manager retired 2026-07-05; inventory remains a direct-read input).
- **Key files:** `Projects/firekeeper-books/ai-art-learning-plan.md`, `ai-art-inventory.md`, `progress/run-log.md`

### akm-refresh — software / system / four-phase
- **Phase:** PLAN · entered SPECIFY 2026-07-07, since advanced
- **Status:** Fix AKM retrieval per the 2026-07 evaluation — mode inversion at scale (BM25 collapsed), R2–R5 scope; two new-primitive hooks pending design approval. Bench fixture at `_system/data/akm/`.
- **Key files:** `Projects/akm-refresh/design/specification.md`, `progress/run-log.md`

### skills-library — software / system / four-phase
- **Phase:** SPECIFY (§C roster decisions executed 2026-07-07: skills 15→11 — researcher/critic/sync/deliberation retired, code-review → review-panel, built-in overlap policy adopted)
- **Next:** PLAN gate. Portable core = writing-coach, mermaid/Excalidraw, deck-intel method; A4 single-source question open.
- **Key files:** `Projects/skills-library/design/specification.md`, `progress/run-log.md`

*(obsidian-applenotes-import — closed + **deleted** 2026-08-08, operator decision, no archival: died at PLAN pre-M0, no repo ever created; git-history-only at commit `b29301d7^`.)*

### mission-control — software / system / four-phase  *(paused)*
- **Phase:** TASK (Phase 3) · **status:** paused · **updated:** 2026-06-14
- **Status:** **Paused, not closed (agentic-sunset AS-030, 2026-06-14).** The dashboard server (`com.crumb.dashboard`, :3100) has been deliberately stopped since 2026-06-01; the rest of the publishing stack (cloudflared, vault-web :8843, vault-rebuild, qmd-index) stays live and reboot-verified (AS-021). Many planned panels depended on now-decommissioned agentic upstreams — those cross-project deps are mooted in `cross-project-deps.md`. Phase 2 done (M5/M6/M7); M3.1 done.
- **Next:** reactivation is operator-initiated (re-enable dashboard plist + `npm run build`). Surviving-upstream features (Google MCP — XD-019/020/021) remain dormant-but-viable.
- **Key files:** `Projects/mission-control/progress/run-log.md`; repo `/Users/danny/openclaw/crumb-dashboard`

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
- **Phase:** ARCHIVED 2026-07-05 (was DONE — Phase 1 gate-passed 2026-03-26)
- **Status:** Concept moved to Claude Cowork; repos + pipeline.db + creds deleted at archival. See `_system/docs/cowork-feed-handoff.md` (roster, triage rubric, reboot constraints).
- **Key files:** `Archived/Projects/feed-intel-framework/`; handoff doc above

### think-different — learning / KB exception
- **Phase:** ARCHIVED, but kept in `Projects/` (not `Archived/`) because it holds 45 biographical profiles in the active knowledge graph. `updated:` 2026-02-18.

## Live Services (verified via `launchctl`, 2026-06-12 post-M3; reboot-verified 2026-06-14 via AS-021)

One clean `com.crumb.*` generation — 10 labels, zero `com.tess.*`/`ai.*`:
- **Plumbing:** com.crumb.{vault-backup 3am, backup-status 15m, drive-sync 5am, vault-gc 4am, vault-health 2am, system-stats, qmd-index 5:30am}
- **Publishing/dashboard stack:** com.crumb.{cloudflared, vault-web, vault-rebuild}; `com.crumb.dashboard` plist exists but the service was deliberately stopped 2026-06-01 — restart is an operator decision (kept for possible repurpose)

Everything agentic is retired — archived plists live in git history only (`_system/archive/` deleted 2026-07-04); runtime dirs were deleted with `Archived/` at VO B1. Do not expect Telegram traffic, hc-ping pings, or `_openclaw/` churn. Known TCC quirk: launchd can't list the iCloud backup dir — backup-status uses a marker-file fallback; retention prune runs from the session-startup hook.

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

- **agentic-sunset: CLOSED 2026-08-10** — nothing remains; project archived. Standing operating rule survives: GUI-login after every reboot (headless reboot = stack stays dark); verify :8843 + backup-status post-login.
- **Residual cloud-side teardown state (found 2026-06-19):** tess-operations' server-side **Gmail filters** (TOP-017, on dturner71@gmail.com) survived the local teardown and silently force-archived ~3 months of personal mail (incl. the Beacon Zen sangha group) until operator-remediated 2026-06-19. **AS-032 to add an external-artifact sweep** — Google agent calendars, Drive `Agent/*` tree, and the "Tess Ops" Discord server may also persist. The AS inventory covered local host state only; externally-hosted config is invisible to `launchctl`/`crontab`/filesystem sweeps.
- **opportunity-scout & feed-intel-framework:** both ARCHIVED 2026-07-05 (pre-empting the AS-032 proposals) — concepts moved to Claude Cowork via handoff notes (`cowork-scout-handoff.md`, `cowork-feed-handoff.md`); repos deleted.
- **firekeeper-books project-state stale** (2026-04-07) — due a status refresh (hobby per Gate 4 since 2026-07-05).
- **Stale skill body-text residuals: RESOLVED at VO B5 (2026-07-04)** — audit §15 removed, learning-plan §7 died in the systems-analyst merge, researcher gotcha noted in its description.

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
- `_system/docs/crumb-design-spec.md` — full spec (read specific sections only)
- `.claude/skills/<name>/SKILL.md` — read only the skill relevant to the task

**Per-project:** `Projects/<name>/progress/run-log.md` (recent state) → `Projects/<name>/design/` (plans/specs).

**Reference:** `_system/docs/operator/reference/` (skills-, overlays-, infrastructure-reference) · `_system/docs/solutions/` (compound patterns) · `_system/logs/session-log.md` (non-project history).

## Appendix: Session Bootstrap Prompt (folded from claude-ai-session-prompt.md, retired 2026-06-12 per B3 R2)

Paste this as the first message in a new claude.ai conversation (replace
`<YOUR_PAT>` with the current fine-grained PAT):

> Clone this repo and read the context file for orientation:
>
> ```
> git clone https://djt71:<YOUR_PAT>@github.com/djt71/crumb-vault-mirror.git
> cat crumb-vault-mirror/_system/docs/claude-ai-context.md
> ```
>
> This is a read-only mirror of my vault's system artifacts. It contains
> system docs, skill definitions, project specs, plans, and progress logs
> — but no personal content or credentials. It auto-syncs from the main
> vault on every commit.
>
> Note: `raw.githubusercontent.com` and `api.github.com` are blocked in
> that compute environment. Use `git clone` via `github.com` instead.
