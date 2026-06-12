---
project: vault-optimization
domain: software
type: design
skill_origin: null
created: 2026-06-12
updated: 2026-06-12
source: design/ceremony-classification.md
tags:
  - design
  - changeset-pack
---

# Changeset Pack B6 — Ceremony Reduction (VO-026)

**Status: FROZEN — APPROVED 2026-06-12 (operator, in-conversation question
gate): B6-1..B6-4 approved as drafted; B6-5 approved at FULL six-counter
sweep scope.** Nothing in this pack is applied; apply is stop-and-ask per
edit at VO-008 B6 (design D5 / B6 row). Gate status: AS-025 complete
2026-06-12 — the apply gate is operator approval only. Batch commit format on apply:
`vault-optimization: VO-008 B6 — <summary>`; vault-check green required;
abort = revert batch.

**Input:** [[ceremony-classification]] (VO-025, 2026-06-10). Target docs:
`_system/docs/context-checkpoint-protocol.md`,
`_system/docs/protocols/session-end-protocol.md`, CLAUDE.md (second pass),
`.claude/skills/inbox-processor/SKILL.md` (B5-coordinated single edit),
`_system/scripts/session-startup.sh` (adjacent finding).

## Ground-truth deltas since classification (2026-06-12 drafting check)

Three AS events landed between VO-025 (06-10) and this pack; each strengthens
or simplifies a classification call — none weakens one:

1. **AS-026 archived `_openclaw/` wholesale.** Session-end step 8's target
   (`_openclaw/inbox/.processed/`) no longer exists — the cut rationale
   upgrades from "automation absorbs" to "target directory gone." The
   vault-gc.sh comment fix flagged at classification is now **moot** (the
   entire `.processed` purge block in vault-gc.sh is a guarded no-op; AS-026
   deliberately left dead lines in place — no B6 edit proposed).
2. **AS-028 retired feed-pipeline outright** (operator inbox-consolidation
   decision 2026-06-11 superseded B5 #F7's keep-with-strip). The classification's
   counter-fix option "re-point to `_openclaw/inbox/*.md` count" is dead —
   **remove** is the only coherent disposition (B6-5).
3. **AS-025 applied.** The CLAUDE.md second-pass diff (B6-4) is drafted
   against the current post-surgery text. The VO-026 AC's
   "tagged pending-AS-025-release" tag is satisfied trivially: the release
   condition already holds, so the tag reduces to **frozen-pending-operator-apply**.

---

## B6-1 — context-checkpoint-protocol.md: phase-gate procedure 11 → 6

**Rationale (classification §1):** four merges, one zero-content cut, no
semantics lost. Mid-session ceremony (§2) becomes the single step 3 below plus
the unchanged Minimum Safe Checkpoint — no separate edit needed.

**Replacement §Procedure (full text):**

```markdown
## Procedure

### 1. Verify Phase Outputs & Summaries

Confirm all phase deliverables are written to disk, and generate or verify
`*-summary.md` for each. Summaries are the primary context vehicle for
downstream phases — if they're missing or stale, later phases operate on
incomplete information.

### 2. Compound Reflection & Goal Progress (phase transitions only)

Evaluate the completed phase in one reflection pass:

- **Goal progress:** which acceptance criteria are met, partially met, or
  unmet? Are unmet criteria blockers for the next phase, or carry-forward?
  Note any criteria modified during the phase, with rationale.
- **Compound:** does the phase meet the compound step trigger criteria
  (non-obvious decisions, rework, reusable artifacts, system gaps)? If yes,
  execute the full compound step (reflect → route → execute) while the
  phase's working context is still loaded. If no, note the skip.

Both results are recorded in the transition log entry (step 4). This step is
the structural guarantee that compound engineering runs at every phase
boundary.

### 3. Context Check & Act

Run `/context` and act per band:

- **< 70%:** proceed
- **70-85%:** run `/compact`
- **> 85%:** run `/clear` and reconstruct from vault files

(Mid-session, this step — plus the Minimum Safe Checkpoint at the 75-85%
band — is the whole ceremony; the trigger lists and degradation guide below
are reference, not steps.)

### 4. Log Phase Transition

Write to `run-log.md`:

    ### Phase Transition: [CURRENT] → [NEXT]
    - Date: YYYY-MM-DD HH:MM
    - [CURRENT] phase outputs: [list key files created]
    - Goal progress: [acceptance criteria status — met/partial/unmet with brief notes]
    - Compound: [insight summary and routing destination, OR "No compoundable insights from [PHASE] phase"]
    - Context usage before checkpoint: [X]%
    - Action taken: [none | compact | clear+reconstruct]
    - Key artifacts for [NEXT] phase: [list summary files to load]

Update `project-state.yaml`:

    phase: [NEXT]
    last_gate: [CURRENT]-to-[NEXT]
    active_task: null          # Reset — next phase assigns tasks
    next_action: "[one sentence: what to do first in the next phase]"
    updated: YYYY-MM-DD HH:MM
    last_committed: YYYY-MM-DD HH:MM  # Updated at every git commit

Add the transition line to `progress-log.md` (keeps the high-level timeline
current for orientation and resume).

### 5. Commit to Git

`git add` all changed vault files and `git commit`. This moves the durability
boundary from "end of session" to "end of meaningful work unit." If the
session crashes after this point, all phase work and state are recoverable
from git.

### 6. Load Next Phase Context

Read relevant summary files for the upcoming phase:
- For PLAN: load `specification-summary.md`
- For TASK: load design summaries (`*-design-summary.md` for each approved design doc)
- For IMPLEMENT: load `tasks.md` and relevant design specs
```

**Stale-text fixes (same edit):**
- §Proactive Triggers: `Spawning subagents (Frontend Designer, Backend Designer)`
  → `Spawning subagents (dispatch agents, research pipelines)` — the named
  agents don't exist (`.claude/agents/` = code-review-dispatch,
  deliberation-dispatch, peer-review-dispatch, test-runner).
- Old step-10 examples `frontend-design-summary.md` / `backend-design-summary.md`
  → neutral `*-design-summary.md` (carried into new step 6 above).

**Checklist diff — no-semantics-lost proof (AC instrument):**

| Old step | Output / semantic | New home | Surviving field |
|---|---|---|---|
| 1 Verify summaries | summaries exist + fresh | **1** | same check, same enforcement (vault-check §2, startup `stale_summaries`) |
| 2 Goal progress | AC status assessment | **2** (evaluated) + **4** (recorded) | `Goal progress:` log field — unchanged |
| 3 Compound reflection | compound evaluate/route | **2** | `Compound:` log field — unchanged; constitutional anchor retained as named step |
| 4 Check `/context` | usage number | **3** | `Context usage before checkpoint:` log field |
| 5 Evaluate capacity | band action | **3** | `Action taken:` log field; bands unchanged |
| 6 Log transition | run-log entry + project-state | **4** | full template verbatim |
| 7 Commit | durability boundary | **5** | unchanged |
| 8 Update progress-log | timeline line | **4** | explicit progress-log line in step 4 |
| 9 Verify outputs on disk | deliverables exist | **1** | merged into outputs+summaries check |
| 10 Load next context | context inventory | **6** | unchanged (examples neutralized) |
| 11 "Proceed" | — (zero content) | cut | nothing to preserve |

Sections unchanged: Proactive/Reactive Triggers (minus stale names), Context
Positioning Guidance, Context Pressure Degradation Guide (incl. MSC).

---

## B6-2 — session-end-protocol.md: 10 → 7

**Rationale (classification §3):** one hard zombie cut (step 2 — the
AC-flagged `session_reports.db` write; producer alive, consumer
decommissioned 2026-06-10; **retire, not re-point** — run-log already carries
a richer session record), one redundant step cut (8 — target dir archived at
AS-026), one textual-zombie deletion (6b residue), one merge (9+10), and the
6a/6b numbering drift fixed.

**Replacement §Procedure (full text):**

```markdown
## Procedure

### 1. Log with Compound Evaluation

- **Project sessions:** log to run-log.md
- **Non-project sessions:** log to `_system/logs/session-log.md` using the format below
  (skip if session was only a greeting or single-question lookup)

### 2. Project State Refresh (project sessions only)

Read `project-state.yaml` and verify `next_action` is consistent with the session's
outcomes — tasks completed, code committed, gates passed/failed, blockers resolved
or introduced. If stale, update:

- `next_action` — must reflect the actual current state, not what it said at session start
- `active_task` — clear if completed, set if a new task is in progress
- `updated` — current date

This is the most common drift vector: code gets committed but `next_action` still says
"pending commit." The next session inherits stale orientation and wastes time reconciling.

### 3. Failure Log (autonomous, conditional)

If the session went clearly poorly — repeated errors, dead ends, significant
rework, or user frustration — write a failure-log entry to
`_system/docs/failure-log.md` with diagnosis. This is Crumb's autonomous
assessment, not a user-prompted rating.

### 4. Code Review Sweep (conditional)

If this is a project session with `repo_path` and code tasks were completed:

1. Check run-log for code review entries matching each completed task ID
2. If any are missing:
   - Run Tier 1 review now (preferred), OR
   - Log explicit skip with reason: `Code Review — Skipped ({TASK_ID}): {reason}`
3. vault-check §23 validates this at commit time as a WARNING — this step is the behavioral prompt to act before the structural check fires

### 5. Build Verification (conditional)

If this is a project session with `repo_path` and `build_command` in `project-state.yaml`,
and source files were modified during the session (`.ts`, `.tsx`, `.js`, `.jsx`, or other
compiled source in the repo):

1. `cd` to `repo_path` and run `build_command`. Verify exit 0.
   - On failure: fix the build error before proceeding. Do not commit broken source.
2. If `services` is declared, restart each launchd service:
   ```bash
   launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/<label>.plist
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<label>.plist
   ```
   Log restarts to run-log.
3. If build was not needed (no source files changed), skip silently.

**Self-healing:** If `repo_path` exists and has a build step (`tsconfig.json` or `build`
script in `package.json`) but `build_command` is missing from `project-state.yaml`, add it
now and log the addition. Same for `services` — if launchd plists reference the repo path
but aren't listed in project-state, add them. This catches projects created before these
fields existed, or sessions where project creation step 3b/3c was missed.

This step ensures compiled artifacts (`dist/`) match committed source. Tests run via
`ts-node` hit source directly and will not catch a stale `dist/`.

### 6. QMD Index Update (conditional)

If `qmd` is available (`command -v qmd`), run `qmd update` to re-index changed
files. Failure is non-blocking — log a warning and continue. (Consumer:
`knowledge-retrieve.sh` via the skill-preflight hook.)

### 7. Commit & Push

Check `git diff --stat HEAD` for uncommitted changes:

- **Log-only delta** (all changed files match `**/run-log*.md`, `**/session-log.md`,
  `**/progress-log.md`, `**/claude-ai-context.md`,
  `**/project-state.yaml`, `**/tasks.md`):
  Lightweight commit: `chore: session-end log — [description]`
- **Substantial delta** (any files outside the log/progress set):
  Flag to user: "Uncommitted work detected beyond session logs — [list files]."
  Commit with descriptive message covering all changes.
- **No changes:** Skip commit and push. Log note: "No uncommitted changes — skipping commit."

Then `git push` (skip if no commit was made).
```

**Cut/changed mapping:**

| Old step | Disposition | Where it went |
|---|---|---|
| 1 Log | keep | new 1 (verbatim) |
| 2 Session report (Amendment Z) | **cut — hard zombie** | nowhere; retired. `session_reports.db` has zero live readers (dashboard src grep clean; dispatch bridge dark; `tess` CLI write succeeds into the void). Run-log is the surviving session record. Sessions since 2026-06-10 already skip-with-reason |
| 3 Project state refresh | keep | new 2 (verbatim) |
| 4 Failure log | keep | new 3 (verbatim) |
| 5 Code review sweep | keep | new 4 (verbatim) |
| 6 Build verification | keep | new 5 (verbatim) |
| 7 / "6a" QMD | keep | new 6 (numbering drift fixed; consumer named inline) |
| 7 / "6b" AKM residue | **delete — textual zombie** | nowhere; the paragraph described its own removal |
| 8 `.processed` sweep | **cut** | nowhere; target dir archived at AS-026 (originally: vault-gc 1-day TTL absorbed it) |
| 9 Conditional commit | keep | new 7 (merge target) |
| 10 Git push | merge | new 7 final line; skip-push-if-no-commit preserved |

§Non-Project Session-Log Format and §References: unchanged (References drops
"Amendment Z" if mentioned — it is not; no edit).

---

## B6-3 — inbox-processor SKILL.md: fold step 8 into step 7 (B5-coordinated edit)

**Rationale (classification §4):** the compound check duplicates CLAUDE.md's
standing compound mandate; folding it into the close-out keeps the evaluation
without a separate mandatory step. Skill files are B5 territory — this single
edit rides in B6 with B5 coordination noted (B5 pack approved 2026-06-10; this
edit doesn't touch any B5 item).

**Diff (lines 531–546):** replace `### 7. Verify and Report` + `### 8. Compound Check` with:

```markdown
### 7. Verify, Report & Compound Check

After processing all files:
- Confirm `_inbox/` is empty (or contains only explicitly deferred files)
- List what was processed: filename → destination, companion note created (if binary), renames applied
- Note any files skipped, deferred, or flagged for user decision
- Report orphan sweep results if run
- If this batch reveals a pattern worth capturing — recurring file types or
  sources, emerging domain-specific intake conventions, tagging patterns that
  should become defaults — route per compound step protocol
```

(Subsequent `### Re-routing` section unchanged; no other step renumbering needed.)

---

## B6-4 — CLAUDE.md second pass (ceremony scope only)

**Diff (§Session-End Sequence):**

```diff
-Steps: (1) log with compound evaluation, (2) failure-log if session went poorly (autonomous — no user prompt), (3) code review sweep — verify review entries for completed code tasks, (4) conditional commit, (5) git push.
+Steps: (1) log with compound evaluation, (2) failure-log if session went poorly (autonomous — no user prompt), (3) code review sweep — verify review entries for completed code tasks, (4) conditional commit & push.
```

No other CLAUDE.md ceremony text changes: the Phase Transition Gate section is
a pointer (procedure lives in the protocol doc — correct architecture), and
the step list above is CLAUDE.md's only enumerated ceremony. **Frozen tag:**
frozen-pending-operator-apply (AS-025 release condition already met).

---

## B6-5 — session-startup.sh dead-counter sweep (adjacent finding — SCOPE EXPANSION, flag for operator)

The classification flagged one zombie counter (`feed_intel_inbox`). Drafting
verification found **six** counter blocks in the same script reading
decommissioned or archived sources — same zombie class (producer alive, source
permanently empty/absent), all emitting permanently-zero keys into every
session's startup context:

| Output key | Source read | Dead because | Lines (current) |
|---|---|---|---|
| `compound_insights_pending/stale` | `_openclaw/feeds/research` | archived AS-026 | ~90 |
| `dispatch_queue` (+stale/orphans) | `~/.tess/state/dispatch/` queue.yaml + claims.yaml | Tess layer dark 2026-06-10 | ~170–192 |
| `research_pending_review` | `_openclaw/research/output` | archived AS-026 | ~193–200 |
| `brainstorm_pending_review` | `_openclaw/inbox/brainstorm-*` | archived AS-026 | ~205–217 |
| `feed_intel_inbox` (+tiers) | FIF `pipeline.db` (24h window) | FIF decommissioned 2026-05-28; db frozen | ~219–242 |
| `lock_deny_candidates` | `~/.tess/state/z4-candidates` | Tess layer dark | ~244–259 |

**Proposed edit:** remove all six blocks plus their formatted-summary lines
(~415, ~418) and the corresponding keys from the startup-context echo
section. Consumers checked: the keys are consumed only by Claude reading hook
output (no script/vault-check reads them); removal shrinks every session's
startup context with zero functional loss. `pipeline.db` itself stays frozen
read-only for the dashboard (fif-operations memory) — only the *hook read*
is removed.

**Conservative alternative** (if operator prefers minimum scope): remove only
the classification-flagged `feed_intel_inbox` block; leave the other five for
an AS-030/audit pass. Default proposal is the full sweep — same class, same
evidence standard, one edit.

---

## A10 metrics — pack-level after-state

| Ceremony | Before | After B6 | Zombies after |
|---|---|---|---|
| Phase gates | 11 | 6 | 0 |
| Context-checkpoint (mid-session) | 2 | 1 | 0 |
| Session-end | 10 | 7 | 0 |
| Intake | 8 | 7 | 0 |
| **Total** | **31** | **21** | **0** |

Plus (beyond A10): 6 zombie startup counters → 0 (B6-5, scope expansion
pending operator).

## AC mapping (VO-026)

| AC | Where satisfied |
|---|---|
| Diff per protocol doc with ceremony rationale | B6-1, B6-2 (+ B6-3 skill edit, B6-4 CLAUDE.md, B6-5 script) |
| Checklist diff proves no phase-gate semantics lost | B6-1 checklist diff table (11 rows, field-by-field) |
| CLAUDE.md diff frozen and tagged (not applied) | B6-4 — frozen-pending-operator-apply; nothing in this pack applied |

## Apply procedure (on operator approval — VO-008 B6)

1. Per-edit stop-and-ask: operator approves each of B6-1..B6-5 (or the batch
   explicitly).
2. Apply edits; bump `updated` frontmatter on both protocol docs.
3. `vault-check.sh` full → green (frontmatter checks exercise the edited docs).
4. Atomic commit: `vault-optimization: VO-008 B6 — ceremony reduction (31→21 steps, zombies→0, startup-counter sweep)`.
5. Soak instrument: VO-009 dry-runs #1 (full phase transition) and #5
   (session-end) execute against the rewritten protocols.
