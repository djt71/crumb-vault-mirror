---
type: design
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: design/optimization-design.md
tags:
  - design
  - ceremony-classification
topics:
  - moc-crumb-operations
---

# Ceremony Step Classification (VO-025)

Per design D5 (VO-007 axis): every step of the four kept workflow ceremonies —
phase gates, context-checkpoint, session-end, intake — classified
**load-bearing** (enforced by hook/vault-check or consumed downstream, named
consumer required) · **zombie** (producer without live consumer) ·
**mergeable** (content survives, folded into an adjacent step). Zombies are
cut, mergeables merged, load-bearing kept — "optimize, don't just shrink."
This doc is the classification + A10 metrics; the actual protocol rewrite
diffs are VO-026 (B6 pack, AS-025-gated, apply stop-and-ask).

**Source docs:** `_system/docs/context-checkpoint-protocol.md` (134 lines,
phase gates + context-checkpoint), `_system/docs/protocols/session-end-protocol.md`
(159 lines), `.claude/skills/inbox-processor/SKILL.md` §Procedure (intake).
**Evidence commands:** consumer greps over CLAUDE.md / vault-check.sh /
session-startup.sh / skills / `~/openclaw/mission-control/src/`; `ls
.claude/agents/`; `ls -la _openclaw/inbox/`; vault-gc.sh read; manifest
cross-check (vault-gc.sh keep row).

**Counting rule:** a "mandatory step" is a numbered step in the protocol's
procedure section that an operator/session must execute on every invocation of
the ceremony (conditional steps count — the condition check is the work;
guidance sections don't count as steps).

## 1. Phase gates (context-checkpoint-protocol.md §Procedure, run at phase transitions)

11 numbered steps.

| # | Step | Class | Consumer / enforcer | Disposition |
|---|---|---|---|---|
| 1 | Verify phase summaries | load-bearing | downstream phases read `*-summary.md` (CLAUDE.md context rules); vault-check §2 summary-freshness; startup-hook `stale_summaries` | keep — **merge target for 9** |
| 2 | Goal progress check | mergeable | output exists only inside step 6's log entry | fold into 6 (evaluation preserved as log-entry field — already is one) |
| 3 | Compound reflection | load-bearing | constitutional (CLAUDE.md "compound reflection at every phase transition"); routes to `_system/docs/solutions/` | keep as named step (enforcement anchor) |
| 4 | Check context usage (`/context`) | mergeable | input to step 5 only | fold into 5 ("check context, act per band") |
| 5 | Evaluate capacity (bands) | load-bearing | degradation guide consumed operationally — context bands cited in every run-log session block this project | keep — **merge target for 4** |
| 6 | Log phase transition (run-log + project-state.yaml) | load-bearing | vault-based resume reads run-log tail + `next_action` (demonstrated at every fresh session, M2/M3); vault-check §28/§29 validate run-log content | keep — **merge target for 2, 8** |
| 7 | Commit to git | load-bearing | durability boundary; pre-commit hook fires vault-check; git remote = authoritative restore source (PLAN gate / B0) | keep |
| 8 | Update progress-log | mergeable | artifact existence enforced (vault-check project-structure check, error if missing) and consumed by archival procedure (CLAUDE.md §Project Archival) — but the *separate step* has no reader beyond step 6's audience; resume uses run-log, not progress-log | fold into 6 (one logging step writes run-log entry + project-state + progress-log line; artifact survives) |
| 9 | Verify phase outputs on disk | mergeable | duplicate of 1's intent (deliverables/summaries written) | fold into 1 (single "deliverables + summaries on disk" check) |
| 10 | Load next phase context | load-bearing | context-inventory requirement; vault-check §29 Context Inventory Completeness | keep |
| 11 | "Proceed to next phase" | mergeable (zero-content) | none — no operative content | cut (no semantics to preserve) |

**After:** 6 mandatory steps — [1+9] verify outputs+summaries · [3] compound
(with [2] goal-progress evaluated in the same reflection pass) · [4+5] context
check+act · [6+2+8] transition log (run-log + project-state + progress-log) ·
[7] commit · [10] load next context. **No phase-gate semantics lost** — every
folded step's output field survives in the merged step; VO-026's checklist
diff must show this field-by-field.

**Stale-text fixes (B6, not step changes):** §Proactive Triggers names
"Frontend Designer, Backend Designer" subagents — neither exists
(`.claude/agents/` = code-review-dispatch, deliberation-dispatch,
peer-review-dispatch, test-runner); step 10 examples name
`frontend-design-summary.md` / `backend-design-summary.md` — generic template
residue, rewrite to neutral examples.

## 2. Context-checkpoint (same doc, mid-session invocation)

Mid-session, the ceremony is steps 4–5 plus the Minimum Safe Checkpoint
(75–85% band) — the trigger lists, positioning guidance, and degradation table
are reference guidance, not steps.

| Step | Class | Consumer / enforcer | Disposition |
|---|---|---|---|
| Check `/context` | mergeable | input to band evaluation | fold (same merge as phase-gate 4+5) |
| Evaluate band + act (compact/clear/MSC) | load-bearing | CLAUDE.md context rules delegate here; MSC ordering (state→log→commit before compact) is the crash-recovery guarantee; band citations in run-logs every session | keep |

**After:** 1 mandatory step (check + act). Degradation guide, positioning
guidance: keep unchanged (consumed; load-bearing reference). Same stale
subagent-name fix as above applies to the trigger list.

## 3. Session-end (protocols/session-end-protocol.md)

10 numbered steps.

| # | Step | Class | Consumer / enforcer | Disposition |
|---|---|---|---|---|
| 1 | Log with compound evaluation | load-bearing | resume reads run-log; vault-check §6 session-log compound completeness | keep |
| 2 | **Session report → `~/.tess/state/session_reports.db`** (+ `tess dispatch claim`) | **zombie** | producer alive (tess CLI writes succeed, row 18 on 2026-06-10) — **no live consumer**: Tess/agentic layer decommissioned 2026-06-10 (agentic-sunset); mission-control dashboard src has zero `session_reports` reads; dispatch queue dead (`dispatch_queue: 0`, bridge dark); only reader on record was VO-012's one-off evidence pass; `tess session-report new-id` sequence read is self-referential | **cut at B6** — recommend retire, not re-point (run-log already carries a richer session record; no consumer identified to re-point at). Stop-and-ask at B6 per VO-026 rule |
| 3 | Project state refresh | load-bearing | resume reads `next_action` (documented drift vector; demonstrated) | keep |
| 4 | Failure log (conditional) | load-bearing | audit skill consumes failure-log trends; B5 gotchas cite failure-log entries (researcher 2026-04-21) | keep |
| 5 | Code review sweep (conditional) | load-bearing | vault-check §23 Code Review Gate (commit-time WARNING) | keep |
| 6 | Build verification (conditional) | load-bearing | `dist/` freshness for repo_path projects; launchd `services` restart; self-healing field backfill | keep |
| 7 | QMD update (labelled "6a") | load-bearing | qmd index consumed by knowledge-retrieve.sh (skill-preflight hook, kept) — note vault-search.sh, the other qmd consumer, is delete-listed at B4 | keep; **fix numbering drift** (§7 contains "6a/6b" labels) |
| 7 | AKM consumption tracking (labelled "6b") | zombie (textual) | the step says of itself "Removed" — 18 days of 0% hit-rate noise; residual paragraph is dead text describing a non-step | delete the residue text at B6 |
| 8 | Inbox `.processed` sweep | mergeable (redundant with automation) | the purge has an effect, but `vault-gc.sh` (keep row, manifest L146; `com.crumb.vault-gc` plist loaded) already purges `_openclaw/inbox/.processed` on a 1-day TTL and self-describes session-end as the redundancy ("this catches stragglers" — the comment has the roles backwards now); contents are by definition already-discarded items, so a 1-day automated TTL fully covers the need | cut from protocol; automation absorbs (note in B6 diff: vault-gc comment update) |
| 9 | Conditional commit | load-bearing | durability; pre-commit vault-check; log-only vs substantial-delta rule | keep — **merge target for 10** |
| 10 | Git push | load-bearing | git remote = authoritative restore source (B0) | fold into 9 ("commit & push" one step; skip-push-if-no-commit preserved) |

**After:** 7 mandatory steps (1, 3, 4, 5, 6, 7-qmd, 9+10). Zombies cut: step 2
(the AC-flagged `session_reports.db` write) + 6b residue text.

## 4. Intake (inbox-processor SKILL.md §Procedure)

8 numbered steps. (Feed intake — feed-pipeline over `_openclaw/inbox/` — is
out of this table: its keep-with-strip disposition is B5 pack #F7, pending
AS-028 concurrence; double-classifying it here would fork that decision.)

| # | Step | Class | Consumer / enforcer | Disposition |
|---|---|---|---|---|
| 1 | Check prerequisites (markitdown, exiftool) | load-bearing | fail-fast guard for steps 4–5 extraction; CLAUDE.md §External Tools | keep |
| 2 | Scan and classify (incl. NLM sentinel, interrupted-move recovery) | load-bearing | routing decision for all downstream paths | keep |
| 3 | Batch user prompting | load-bearing | operator metadata decisions (tags, project, domain, `#kb/` canonical-list constraint); batch-context shortcut already present — this is the step the Ceremony Budget Principle worried about, and the batching escape valve already addresses it | keep |
| 4 | Process markdown (standard + NLM path) | load-bearing | produces routed vault notes; kb-to-topic mapping; vault-check schema checks downstream | keep |
| 5 | Process binary (companion notes) | load-bearing | companion notes consumed by orphan detection (step 6) and inline-attachment protocol | keep |
| 6 | Orphan sweep (Path D, on-request/optional) | load-bearing | only detector for attachment-dir orphans; explicitly conditional already | keep |
| 7 | Verify and report | load-bearing | convergence check (inbox empty, moves complete) — the skill's binary grounding | keep — **merge target for 8** |
| 8 | Compound check | mergeable | same compound evaluation CLAUDE.md already mandates; scoped to batch patterns | fold into 7 (one close-out step: verify, report, compound) — B5 coordination: skill file edits are B5 territory, so this merge rides in the B6 pack as a B5-coordinated edit |

**After:** 7 mandatory steps. Intake ceremony is largely healthy — the
heavy-intake concern from the health assessment is mitigated by the existing
batch-prompting shortcut, not by cutting steps.

## Zombie list (AC: must include session_reports.db write)

1. **Session-end step 2 — session report write to `session_reports.db`** (incl.
   `tess dispatch claim` sub-step). Producer alive, consumer decommissioned.
2. **Session-end "6b" AKM consumption-tracking residue** — textual zombie
   (describes its own removal).
3. **Stale subagent trigger refs** ("Frontend Designer, Backend Designer") in
   checkpoint protocol — references to non-existent agents (textual zombie).

All three → 0 at B6 (VO-026 diffs; apply stop-and-ask, post-AS-025).

## A10 metrics

| Ceremony | Mandatory steps before | After (proposed) | Zombies found | Zombies after B6 | Kept steps with named consumer/enforcer |
|---|---|---|---|---|---|
| Phase gates | 11 | 6 | 0 (2 stale-text refs) | 0 | 6/6 |
| Context-checkpoint (mid-session) | 2 | 1 | 0 (shares stale-text ref) | 0 | 1/1 |
| Session-end | 10 | 7 | 1 step + 1 text residue | 0 | 7/7 |
| Intake | 8 | 7 | 0 | 0 | 7/7 |
| **Total** | **31** | **21** | **1 hard + 2 textual** | **0** | **21/21** |

Soak-relevant: VO-009 dry-run #1 (full phase transition) and #5 (session-end
sequence) execute against the *rewritten* protocols — the checklist diff at
VO-026 is the instrument proving no phase-gate semantics were lost.

## Adjacent findings (outside the four ceremonies — routed, not classified)

1. **Startup-hook feed counter reads a dead DB.** `session-startup.sh:213`
   computes `feed_intel_inbox` from FIF SQLite
   (`~/openclaw/feed-intel-framework/state/pipeline.db`, 24h-triaged window) —
   FIF decommissioned 2026-05-28, so the counter is permanently 0 while
   `_openclaw/inbox/` holds a **34-file backlog** (feed-intel items dated
   2026-05-26→28, pre-decommission). Route: counter fix (re-point to
   `_openclaw/inbox/*.md` count, or remove with the strip) → **B6 pack
   candidate, coordinate with AS-028 / B5 #F7**.
2. **Inbox backlog itself** (34 items) → operator decision: process via
   feed-pipeline or discard; flagged for the next session-summary.
3. **vault-gc.sh comment** describes session-end as primary and itself as
   safety-net for `.processed` — roles invert when step 8 is cut; one-line
   comment fix rides in B6.
