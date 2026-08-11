---
project: tess-v2
type: design-input
domain: software
status: active
created: 2026-04-06
updated: 2026-04-06
source: github.com/paperclipai/paperclip state check, operator-directed
related:
  - design/services-vs-roles-analysis.md
  - design/tasks.md TV2-045
tags:
  - architecture
  - scaling
  - external-evaluation
---

# Paperclip Relevance Check — 2026-04-06

Short state-check memo on Paperclip (`github.com/paperclipai/paperclip`) to determine whether TV2-045 (Paperclip integration spike) remains well-framed, given developments since the 2026-04-01 `services-vs-roles-analysis.md`.

## Summary Recommendation

**Keep TV2-045 deferred. Do not run the spike now.**

Nothing in the past five days invalidates the original conclusion: "No current design changes needed. The state machine already supports hierarchical dispatch." None of the three scaling triggers from that analysis are firing.

**But two observations are worth recording for when the spike is eventually triggered:**

1. The adapter architecture (new finding) suggests a **much cheaper spike path** than TV2-045's current acceptance criteria describe. Don't update TV2-045 yet — note this here for the next revisit.
2. The project is **moving fast enough** that any spike done speculatively will be stale within weeks. A "when triggered, not before" posture is the right default.

## Current State (as of 2026-04-06)

| Signal | Value | Source |
|---|---|---|
| Age | ~1 month (launched 2026-03-04) | DEV community writeup |
| Stars | 48,739 | `gh repo view` 2026-04-06 |
| Star trajectory | 30k at 3 weeks → 42k early April → 48.7k today | WebSearch + gh |
| Latest release | `v2026.403.0` (2026-04-04) | gh releases |
| Release cadence | Weekly calver since 2026-03-18 (was semver v0.3.x before) | gh releases |
| Primary language | TypeScript (Node.js + React + Drizzle + PGlite) | `AGENTS.md` repo map |
| Active development | Multiple commits/day; PR #2797 open 2026-04-06 | gh commits |
| License | MIT | repo |
| Maintainer | Pseudonymous @dotta (single-dev project) | external writeups |

### Architecture Clarity (Since 2026-04-01)

The repo's `AGENTS.md` now states an explicit product position:

> "Paperclip is a control plane for AI-agent companies. The current implementation target is V1 and is defined in `doc/SPEC-implementation.md`."

Core engineering rules in `AGENTS.md` §5 enumerate the **control-plane invariants**:
- Single-assignee task model
- Atomic issue checkout semantics
- Approval gates for governed actions
- Budget hard-stop auto-pause behavior
- Activity logging for mutating actions
- Company-scoped entities (multi-tenant isolation)

These map cleanly to tess-v2 concepts:

| Paperclip invariant | tess-v2 equivalent |
|---|---|
| Single-assignee task | Contract immutability (state-machine §8) |
| Atomic issue checkout | Staging directory reservation (AD-008) |
| Approval gates | Gate 3 risk policy + `PENDING_APPROVAL` state |
| Budget hard-stop | Bursty cost model + `$75/month` ceiling |
| Activity logging | Contract execution ledger (§18) |
| Company-scoped | No tess-v2 equivalent (see below) |

### Adapter Architecture — New Finding

`packages/adapters/` contains adapters for **Claude Code, Codex, Cursor, Bash, and HTTP**. The README tagline is *"If it can receive a heartbeat, it's hired."*

**This is the shift that could reframe TV2-045.** The original acceptance criteria say:

> "Stand up 3-role toy hierarchy (Tess GM → 2 service roles). Test whether tess-v2 contract runner can sit beneath Paperclip's task dispatch."

That's a heavy spike — stand up a hierarchy, define roles, wire routing. But if Paperclip's integration surface is an **HTTP adapter**, the actual compatibility question becomes:

> "Can tess-v2's contract runner be wrapped as a Paperclip HTTP adapter such that (1) Paperclip's task checkout dispatches contracts, (2) the runner's Ralph loop and staging/promotion complete without Paperclip bypassing AD-008, (3) run results are reported back via Paperclip's activity log?"

That's potentially a much thinner spike — write one adapter, run one contract end-to-end, observe where the abstractions collide. Could be a half-day instead of a full day.

### Dependency/Wake Semantics — New Finding

Commits from 2026-04-04 through 2026-04-06 add:
- "Add blocker relations and dependency wakeups" (2026-04-04)
- "Add blocker/dependency documentation to Paperclip skill" (2026-04-05)
- "make a plan for first-class blockers wake on subtasks done" (2026-04-06)

Paperclip is building **event-driven dependency graphs with wake-on-completion**. This is architecturally close to what Amendment Z's planning service will need in Phase B (explicit state-transition semantics, dependency chains between queue items). Worth watching as a reference implementation, even if the spike stays deferred.

## What's Unchanged

The three scaling triggers from `services-vs-roles-analysis.md` §4 are still the right gate:

1. Domain depth exceeds summarization
2. Concurrent workstreams need independent judgment
3. Context window becomes the bottleneck

**None are firing as of 2026-04-06.** Firekeeper Books (the named first candidate) is not at production scale. Coordination overhead has not exceeded strategic decision bandwidth. The dispatch envelope budgets (16K local / 32K cloud, TV2-023) are not the active bottleneck.

## Risks / Skepticism Signals

Worth recording honestly so any future spike goes in with eyes open:

- **Bus factor: 1.** Pseudonymous single maintainer. 48k stars don't change that.
- **No API stability promise.** Calver + weekly releases + active schema churn = any adapter written today may need rework in a month. The "blocker/dependency" work landing right now is core-schema territory.
- **Hype-to-substance ratio is uncertain at one month.** 30k → 48k stars in 2 weeks includes a lot of speculative interest. The engineering rules in `AGENTS.md` look sober; the "zero-human company" marketing framing is aspirational.
- **Agent instruction-adherence is still open.** PR title 2026-04-06: *"why did this issue succeed without following my instructions"*. This is a known hard problem across all agent frameworks — noting it here as "Paperclip has not solved what nobody else has solved either," not as a specific defect.
- **"Zero-human company" framing doesn't match tess-v2.** Crumb's model is Danny-in-the-loop strategic director, not absent owner. Paperclip's product positioning is compatible with that (the "governance / you're the board" framing) but the marketing drift is worth noting.

## Updated Recommendation (Scoped)

1. **TV2-045 stays `todo` in Pre-Phase 4b.** Do not modify the task in `tasks.md`. This memo is advisory input for when the spike is eventually triggered.
2. **Revival criteria (from `services-vs-roles-analysis.md`) remain unchanged:** wait for one of the three scaling triggers to fire OR for Firekeeper Books to reach production scale.
3. **When the spike is triggered, consider a lighter acceptance criteria** built around the adapter architecture: write a single HTTP adapter, run one contract end-to-end, observe abstraction boundaries. Half-day instead of full spike.
4. **Schedule the next state-check memo.** Set a ~90-day recurrence (next: ~2026-07-06) to decide whether Paperclip has matured enough to re-evaluate, or pivot to a different candidate, or stop tracking it. Lightweight — same format as this memo, ~30 minutes.
5. **Track the dependency/wake semantics work** as a passive reference for Amendment Z Phase B planning. Not a dependency — just prior art.

## What This Memo Deliberately Does Not Do

- **Does not modify TV2-045.** Operator directive: "do the research and create the memo as a separate item. Don't rescope."
- **Does not run the spike.** This is a desk check, not the integration evaluation TV2-045 describes.
- **Does not pre-commit to the adapter approach.** The HTTP-adapter reframing is a hypothesis, not a decision. The current acceptance criteria in TV2-045 are preserved as-is.
- **Does not add new tasks.** This memo is an artifact, not a task entry. If it produces follow-up work, that becomes operator/Tess planning input, not auto-created tasks.

## Related

- `design/services-vs-roles-analysis.md` — original 2026-04-01 framing, three scaling triggers, Firekeeper Books as first candidate
- `design/external-systems-evaluation-2026-04-04.md` — 10-system sweep that catalyzed Amendment Z
- `design/tasks.md` TV2-045 — Pre-Phase 4b scaling spike, preserved unchanged
- `design/spec-amendment-Z-interactive-dispatch.md` — dispatch queue + session reports; Phase B planning service is the component that would benefit from watching Paperclip's dependency-wake work

## Sources

- [paperclipai/paperclip (GitHub)](https://github.com/paperclipai/paperclip) — repo metadata, commits, releases, `AGENTS.md`, README
- [paperclip.ing](https://paperclip.ing/) — product site
- [How We Built a Company Powered by 14 AI Agents Using Paperclip (DEV)](https://dev.to/jangwook_kim_e31e7291ad98/how-we-built-a-company-powered-by-14-ai-agents-using-paperclip-4bg6) — launch context
- [Paperclip AI Explained (Towards AI)](https://pub.towardsai.net/paperclip-the-open-source-operating-system-for-zero-human-companies-2c16f3f22182) — external writeup
