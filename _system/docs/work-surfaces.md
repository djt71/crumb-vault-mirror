---
type: reference
domain: null
status: active
skill_origin: null
created: 2026-06-11
updated: 2026-06-11
supersedes:
  - "_system/docs/liberation-surfaces-snapshot.md (April 2026 four-surface model)"
related:
  - "_system/directives/liberation-directive.md"
  - "_system/docs/adr-crumb-v3-knowledge-store-identity.md"
  - "_system/docs/adr-vault-write-boundary.md"
tags:
  - directive
  - architecture
---

# Work Surfaces

The live roster of AI work surfaces and the policies that govern them. Successor to
[[liberation-surfaces-snapshot]] (frozen April 2026). Grounded in
[[liberation-directive]] Principle 6 — *"Agents execute, Danny decides. Execution is
rented from the platform, never rebuilt as self-hosted infrastructure"* — and the Crumb
v3 identity ([[adr-crumb-v3-knowledge-store-identity]]: the vault is a knowledge store
and reasoning substrate, not an automation platform).

This document carries no dates, deadlines, or budgets. Operational details (pilots,
migrations, verification results) live in project artifacts and are linked, not
duplicated.

---

## Roster

| Surface | Sovereignty | Job |
|---|---|---|
| **Claude Code on the Mac Studio ("Crumb")** | Danny | Deep work: vault-grounded reasoning, projects, skills, reviews, compound engineering. The only surface carrying full CLAUDE.md discipline and the workflow spine (phases, gates, run-logs, commits). |
| **Obsidian** | Danny | The human surface: reading, browsing the knowledge graph, re-grounding. Where viewing needs are met before any new viewing surface is considered. |
| **Cowork** | Danny | Interactive life-OS execution: connectors, non-markdown deliverables (docs, sheets, slides, PDF), production work inside project folders. Scheduling candidate (see Scheduling Ownership). |
| **Scheduled cloud agents (Routines)** | Danny | Machine-independent cadence work against a repo clone, writing via PR. Scheduling candidate (see Scheduling Ownership). First designated migration: agentic-sunset AS-023. |
| **claude.ai on demand (web/mobile)** | Danny | Away-from-desk and casual work; feed-intel processing on demand; anything not needing vault depth. |
| **Push notifications + Gmail** | Danny | Outside-in delivery channel for scheduled output. Stateless consumables are delivered here and never enter the vault. Forecloses rebuilding a messaging bridge. |
| **Glean (Infoblox)** | **Employer** | Mandated AI surface for day-job work. A foreign canonical store — interchange with all other surfaces is manual and operator-mediated only (see Glean Airlock). Track 1 instrument: used with mercenary clarity; using it well reduces the job's energy tax. |

**Held:** the dashboard (vault-web + cloudflared) — kept but stopped. Decision deferred
to the quarterly mission check: restart as the one intentional local viewing surface, or
cut. Open-ended limbo is not an option.

**Out, explicitly:**
- **Perplexity (Comet + Computer)** — unused; dropped. Subscription cancelled
  (operator, 2026-06-11) — banked dollars are liberation progress.
- **Channels (Telegram/Discord/iMessage into a live session)** — excluded on principle:
  requires a persistent always-on local session, which is standing infrastructure in
  platform clothing. Named here to prevent re-litigating.
- **Remote Control** — deferred until away-from-desk *vault* work demonstrates friction
  that claude.ai on demand doesn't cover. Friction pulls it in; speculation doesn't.
- **Claude in Chrome** — available ad hoc when a task needs an authenticated browser;
  not a standing surface.

---

## Scheduling Ownership (open)

Cowork scheduled tasks (local, live filesystem, sub-hour, machine-tied) and Routines
(cloud, repo clone, PR-mediated writes) are both scheduling-capable with opposite
trade-offs. The write-boundary policy tilts daily consumables toward Cowork-scheduled
(direct write to a designated drop zone beats daily PR ceremony), but the call is made
by the AS-023 pilot, not this document — whichever substrate handles the daily
attention plan with less ceremony and a defensible write path wins. Product claims from
the April verification pass are stale; re-verify before designing (see Verification
List).

---

## Vault Write Boundary (summary)

Full policy: [[adr-vault-write-boundary]]. Writes are classified by content, not by
surface:

- **Class 0 — stateless consumables:** outside-in delivery (push/Gmail); never enter
  the vault.
- **Class 1 — operational consumables with state continuity:** direct write permitted
  into enumerated drop-zone paths only (registry in the ADR; initial: `_system/daily/`).
- **Class 2 — knowledge candidates:** deposit into `_inbox/`; enter the knowledge graph
  only through operator-triggered processing (inbox-processor).
- **Class 3 — everything else** (specs, projects, system docs, KB, directives):
  operator-present sessions only, on either Crumb or Cowork. Cowork production work
  enters git history through Crumb commit boundaries, where vault-check enforces
  mechanically.

Guardrail in one line: drop zones are enumerated, terminal or operator-pulled, and
mechanically enforced — no staging, no promotion machinery, ever.

---

## Memory Ownership

**Principle: the vault originates; every other Danny-sovereign store caches or
annotates.** Surface memories hold only (a) collaboration working notes — preferences,
feedback, gotchas, model behavior — and (b) projections of vault content, regenerated
not hand-edited. Canonical knowledge originating anywhere but the vault is a defect.

| Store | Role |
|---|---|
| Vault | Canonical, sole originator |
| Claude Code memory dir | Collaboration memory + vault pointers (existing discipline; AS-029 owns cleanup) |
| claude.ai project memory | Disposable cache, fed by projection (`claude-ai-context.md`); zero-loss if wiped |
| Cowork memory | Same class as claude.ai, mechanics pending verification |
| Glean | Foreign canonical store (employer's corpus) — not a cache, never projected into or from automatically |

**Flow rules:** outbound = vault → regenerated projections. Inbound = operator-mediated
capture only (Crumb session or `_inbox/` drop) — no automated harvesting, no memory-sync
machinery. **Conflict hierarchy:** vault > memory dir > surface memory; a surface memory
contradicting the vault is a stale cache, not a competing claim.

---

## Glean Airlock

Glean is employer-sovereign: Infoblox controls runtime, corpus, retention, and
monitoring. The pattern between sovereign stores is an airlock, not a sync — Danny is
the conscious boundary in both directions.

**Outbound (→ Glean):** everything entered is presumed visible to and retained by
Infoblox. Job-relevant content only. Hard line: nothing from the liberation stack —
philosophy, directive, campaign, bet work — ever crosses. Sibling rule to the PIIA hard
gate: **no bet work on employer surfaces, period** (IP provenance protection, not just
privacy).

**Inbound (← Glean):** operator-mediated capture via Crumb session or `_inbox/` drop.
Tag provenance in frontmatter (`source: glean`); inbound content inherits the
confidentiality of the underlying Infoblox corpus and follows existing
customer-confidentiality handling (e.g., mirror denylist). Routed as career-domain
knowledge work (SE inventory, customer-intelligence, deck-intel pipelines).

---

## Intake

`_inbox/` is the **universal receiving bay** for every surface on the roster — Cowork
deliverables, claude.ai captures, Glean airlock inbound, manual and NotebookLM drops.
One door in; **inbox-processor** is the single processing path (classify, frontmatter,
route, companion notes for binaries). Operator on the trigger, always.

**Consolidation decision (operator, 2026-06-11):** `_openclaw/inbox/` is defunct. The
two-inbox era ends — feed-type items, if they still arrive, are a classification inside
inbox-processor, not a parallel pipeline. Execution belongs to agentic-sunset
(AS-026 archival, AS-028 skill cleanup). The standing feedback that intake stays
deliberately open — no strategic-fit filters upstream — carries over untouched.

**Enhancement runway** (when work pulls it, per Principle 7): per-surface provenance
tagging, Cowork non-markdown drops with companion-noting, feed-tier classification as
an inbox category. All operator-triggered, all within the existing skill.

---

## Operating Caveats

- Don't run Crumb and Cowork on the same project simultaneously — same working tree,
  last-write-wins.
- Binary artifacts follow the existing companion-note convention; the sweeping Crumb
  session backfills where Cowork doesn't.
- Scheduled writers commit immediately with a recognizable prefix; the session-startup
  `git pull` absorbs their writes into the next Crumb session.

---

## Verification List — COMPLETE (2026-06-11)

All four items verified against current primary docs. Results:
`Projects/agentic-sunset/design/scheduler-verification-2026-06.md`. Headlines: Cowork
scheduled tasks confirmed (local, live filesystem, catch-up on wake) but Cowork does
**not** read CLAUDE.md or fire lifecycle hooks — scheduled-task prompts must be
self-contained; git pre-commit vault-check **does** fire on Cowork commits (the Class 3
commit-boundary guard holds). Routines stable and unchanged, but cloud runs can't fire
local git hooks — never enable "unrestricted branch pushes" for crumb-vault. Net: the
Cowork-scheduled tilt for AS-023 strengthens; one pilot observation item remains
(whether Cowork shares the Claude Code project memory directory).

---

## Review

Reviewed alongside the quarterly mission check (with [[personal-philosophy]] and
[[liberation-directive]]). Roster changes are operator decisions, logged when made.
