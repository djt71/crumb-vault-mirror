---
type: changeset-pack
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: keep-set-manifest.md
tags:
  - changeset
  - b5
topics:
  - moc-crumb-operations
---

# B5 Skills/Agents Changeset Pack (VO-023)

**Batch:** B5 — executes at VO-032. **Preconditions:** B4 complete (VO-031),
AS M6 sign-off, **AS-028 concurrence on the two sunset-tied skills** (below).
**Drafted:** 2026-06-10 against manifest baseline 2026-06-10 (HEAD b58a3e4e).
**Batch-open staleness check (A1):** re-validate dispositions + inventory
drift diff; evidence-status changes return to operator (A2).

## Approval record

| Field | Value |
|---|---|
| Pack status | **APPROVED with exception** |
| Approved by | operator (in-conversation question gate) |
| Date | 2026-06-10 |
| Conditions/exceptions | **critic→peer-review and writing-coach→peer-review merges REJECTED — both skills stay standalone (keep).** #F6 (diagram-capture→deck-intel) and #F7 proposed shapes approved. Pack amended same day to reflect the exception (this version is the approved one). |

Flags at draft time: #F6 (diagram-capture → merge-into:deck-intel — resolves
the manifest's keep-or-merge fork; approved), #F7 (feed-pipeline
keep-with-strip and vault-query keep-with-rewrite — approved as proposals;
final shape pends AS-028 concurrence at batch open).

**Operator-decision note:** the 2026-03 deferred-merge list
(session-log.md:157) carried four candidates; two execute (checkpoint→audit,
learning-plan→systems-analyst) and two are now declined by operator decision
(critic, writing-coach) — the deferred-merge list is fully dispositioned and
closed.

## Merges (3) — disposition list + per-item remediation

End state: 20 skills → **17** (operator declined the critic and writing-coach
merges at approval). Each merge = fold unique procedure into target, delete
source skill directory, remediate consumers in the same commit.

| Source → target | Remediation (same B5 commit) |
|---|---|
| checkpoint → audit | orientation-map.md:41 · skills-reference.md:28,54,68,140,147 · AGENTS.md:48 · skill-preflight.sh:44 fast-path list · **CLAUDE.md:106 Phase-1 delegation list → B6-owned (AS-025 first); transient staleness B5→B6 accepted, noted in run-log** |
| diagram-capture → deck-intel (#F6) | orientation-map.md:46 · skills-reference.md:33,55,95,145 · deck-intel/SKILL.md:88 composable-mode call internalized · inbox-processor description mention → point to deck-intel · skill-preflight.sh:44 fast-path list |
| learning-plan → systems-analyst | orientation-map.md:49 · skills-reference.md:36,55,66,82,148 · skill-preflight-map.yaml:85 (key re-point or drop) · _attachments/learning/wyner-fluent-forever-companion.md:36 re-point consuming-skill name |

**Declined merges (operator, 2026-06-10) — both rows revert to keep:**

| Item | Consequence |
|---|---|
| critic | keep standalone. No orientation-map/skills-reference edits. Its `brief_schema:` lines (critic:14,67) get the strip treatment with the briefs/ deletion (below) instead of dying with a merge |
| writing-coach | keep standalone. No remediation edits (skill-preflight-map.yaml:91, AGENTS.md:46, ai-telltale-anti-patterns re-point all dropped from this pack) |

**#F6 rationale (diagram-capture):** VO-019 composition check found deck-intel
is the only live composer (SKILL.md:88 call); inbox-processor names it in
description only; standalone use dormant ~3mo. SkillsBench bias: merges beat
borderline keeps. Visual interpretation becomes a deck-intel mode; triggers
fold into its description (below).

## Conditional rows (#F7 — AS-028 concurrence at batch open)

| Item | Proposed disposition |
|---|---|
| feed-pipeline | **keep-with-strip**: remove FIF-SQLite stages + dashboard-queued promotion processing (runtime dead); keep inbox-item classification, Tier-2 action extraction, Tier-1a signal promotion, Tier-1b review queues (intake dir deliberately stays open — operator decision on record). Calibration step: strip the `feed-pipeline-calibration.jsonl` append (SKILL.md:450) **or** keep step + file together — decide with AS-028; the jsonl's deletion rides this decision (B3 pack deferred item). run-feed-pipeline.md edited to match |
| vault-query | **keep-with-rewrite**: strip Tess-dispatch/brief surface (dispatch half dark since sunset); keep obsidian-cli query patterns + operator/skill-facing retrieval. Fixes CLAUDE.md stale "obsidian-cli skill" citation indirectly (actual CLAUDE.md edit = B6) |

## Other skill-procedure edits (same B5 commit)

| Item | Edit |
|---|---|
| deliberation/SKILL.md:241-242 | **E3 stale-path defect**: points to `Projects/multi-agent-deliberation/data/deliberations/` (does not exist). Re-point to `_system/data/deliberations/` (E3 extraction home). **Cross-batch:** the data move happens at B1; same-batch discipline puts the re-point in B1's remediation — verify done at B5 batch open; if B1 deferred it, apply here |
| audit/SKILL.md steps 10/102/115/124/137 | **D4**: Archived/KB purge-review steps removed; replaced with stale-KB **delete review** (delete with git provenance, matching the vault-gardening.md rewrite in the B3 pack — A11 scoping) |
| attention-manager/SKILL.md:140 | **D4**: "Skip Archived/Projects/" line dropped (directory gone post-B1) |
| researcher:13, critic:14,67, vault-query:14, feed-pipeline:14,26,38 | `brief_schema:` frontmatter strips — **same commit as `_system/schemas/briefs/` deletion (4 files), reassigned into this batch** (A2 #3 single-changeset coordination; critic added after its merge was declined) |

## Agents (4)

| Item | Disposition |
|---|---|
| code-review-dispatch, deliberation-dispatch, peer-review-dispatch | keep (follow kept parents) |
| test-runner | **keep** — pending row resolved: mission-control (repo_path project) active in TASK phase; re-check at VO-035 close-out |

## Trigger-condition description rewrites (every kept skill — VO-005 AC, 17/17)

Drafted per Anthropic guidance: capability clause + explicit trigger
conditions; merged capabilities folded in. Applied to SKILL.md frontmatter at
B5; skill-routing fast-pass at commit validates routing (VO-009/D6 spot-checks
run against these).

1. **action-architect** — Decompose an approved spec or design into
   milestones, action plans, and atomic tasks with acceptance criteria.
   Trigger: a spec/design was just approved and implementation planning is
   next, or user says "break this down", "create tasks", "what's the plan",
   "next steps".
2. **attention-manager** — Produce the daily attention plan or monthly review
   from goal-tracker, SE inventory, active projects, and personal context
   (Life Coach + Career Coach lenses). Trigger: "plan my day", "daily
   attention", "what should I focus on", "monthly review".
3. **audit** (absorbs checkpoint) — Audit vault/project state (drift, stale
   summaries, redundant patterns, failure-log trends, hygiene) and run state
   checkpoints (log progress, compact context, verify vault files). Trigger:
   startup staleness scan warrants a full pass; user says "audit", "vault
   health", "checkpoint"; phase transition or session end needs a checkpoint.
4. **code-review** — Two-reviewer panel (Claude Opus via API + Codex via CLI)
   review of code changes for correctness, security, readability, quality.
   Trigger: IMPLEMENT milestone boundaries and pre-merge in repo_path projects
   (vault-check §23 enforces), or "review this code", "code review", "check
   my implementation".
5. **deck-intel** (absorbs diagram-capture) — Extract structured intelligence
   from PPTX/PDF (sales enablement, vendor, competitive, analyst material)
   and interpret visual content in PPTX/PDF/images: classify
   (diagram/table/chart/screenshot), recreate diagrams as Mermaid, tables as
   markdown, others as structured descriptions. Trigger: "process this deck",
   "extract intel from", "campaign intel", "capture this diagram", "what's in
   this image/diagram", or a dropped PPTX/PDF/image needing structured
   extraction. Composable from inbox-processor for visual enrichment.
6. **deliberation** — Run a multi-agent deliberation on a vault artifact:
   dispatch to external LLM evaluators with role overlays, generate the
   outcome, write the record with rating capture. Trigger: "deliberate on",
   "panel review", "multi-agent review", "evaluate with the panel", or a
   quality gate requiring panel assessment.
7. **feed-pipeline** (post-strip, pends #F7) — Process feed intel items from
   `_openclaw/inbox/`: classify by tier, extract actions (Tier 2), evaluate
   permanence and promote to signal notes (Tier 1a), queue borderline items
   for review (Tier 1b). Trigger: "process feed items", "feed pipeline",
   "clear feed backlog", "process feed intel", or unprocessed items in the
   intake inbox.
8. **inbox-processor** — Process files dropped into `_inbox/`: classify, add
   frontmatter, summarize, route to vault locations; companion notes for
   binaries; NotebookLM-export detection; orphan-binary sweeps. Trigger:
   "process inbox", "check inbox", "I dropped files in", "orphan sweep", or
   unprocessed files in `_inbox/`.
9. **mermaid** — Create Mermaid diagrams (inline markdown or .mmd; default
   for all diagram/chart requests) and Excalidraw JSON when freeform spatial
   layout, wireframes, or hand-drawn aesthetic is wanted. Trigger: any
   request to diagram, chart, visualize, sketch, or draw; "mermaid",
   "excalidraw", or a named diagram type (flowchart, sequence, ERD, Gantt,
   mind map, timeline, kanban, architecture).
10. **peer-review** — Send a Crumb artifact to one or more external LLMs for
    structured review; write a consolidated review note to the vault.
    Trigger: "peer review", "get review", "cross-model review", "send for
    review", or HIGH-impact artifacts (specs, skills, architecture, plans) at
    phase gates.
11. **researcher** — Execute the stage-separated research pipeline (Scoping →
    Planning → Research Loop → Citation Verification → Synthesis → Writing)
    producing evidence-grounded deliverables with mechanical citation
    integrity. Trigger: "research", "investigate", "deep research on", "find
    evidence for", "what does the evidence say about", or KB production
    needing cited deliverables.
12. **startup** — Display the formatted session-startup summary from the
    SessionStart hook output. Trigger: `/startup` invocation only (the hook
    runs automatically; this skill is the display contract).
13. **sync** — Sync vault state with external systems: git commit, push,
    cloud backup. Trigger: session-end sequence steps 4–5, major milestones,
    or "sync", "commit", "push the vault".
14. **systems-analyst** (absorbs learning-plan) — Analyze problems, goals, or
    vague tasks into structured specifications; includes phased
    learning/training plan design (skill-type classification, practice
    schedules, progress checkpoints) as a specification variant. Trigger: new
    project intake, "write a spec", "analyze this problem", "help me think
    through", "what should I build", or "learning plan", "training plan",
    "study plan", "build a curriculum", "how do I get good at".
15. **vault-query** (post-rewrite, pends #F7) — Query the vault for
    structured facts, recent activity, and relevant notes on an account,
    topic, or domain; obsidian-cli indexed search when available, native
    tools fallback; structured output consumable by other skills. Trigger:
    "query the vault", "what do we know about", "vault lookup", "find in
    vault", or another skill needing structured vault retrieval.
16. **critic** (kept standalone — operator decision) — Adversarial review of
    a vault artifact: unsupported claims, logical gaps, missing perspectives,
    independent citation verification, severity-rated findings. Trigger:
    "critique this", "find problems", "adversarial review", "check
    citations", or a quality gate requiring adversarial analysis.
17. **writing-coach** (kept standalone — operator decision) — Improve
    clarity, structure, tone, argument, and brevity of written content
    (emails, docs, essays, proposals). Trigger: "improve this", "review my
    writing", "make this clearer", "edit for tone".

## Gotchas (only where a failure is on record — VO-023 AC)

| Skill | Gotcha (added as SKILL.md section at B5) | Linked record |
|---|---|---|
| researcher | Writer stages fabricate internal `[[wikilinks]]` even while citing external sources correctly (asymmetric grounding). Before emitting, resolve every `[[...]]` target against the vault: strip, replace with a real anchor, or downgrade to prose. | failure-log.md 2026-04-21 (False Pattern — 4 fabricated vault paths in a research brief; external claims in the same brief all verified) |
| peer-review | Grok-family reviewers carry a fabrication calibration watch — weigh Grok findings against the tally before accepting; do not treat volume of findings as signal. | VO run-log 2026-06-10 (watch review 2: 9 findings — 1 misread, 1 noise) + peer-review-config.md calibration tally; model-grok-fabrications memory |

No other kept skill has a linked failure-log/run-log failure → no other
gotchas added (AC: each gotcha links a recorded failure).

## Consumer remediation summary (B5 commit checklist)

orientation-map.md (3 merge rows) · skills-reference.md (3 merge rows) ·
AGENTS.md:48 · skill-preflight.sh:44 · skill-preflight-map.yaml:85 ·
deck-intel/SKILL.md:88 · wyner-fluent-forever-companion.md:36 ·
brief_schema strips ×4 skills (researcher, critic, vault-query,
feed-pipeline) + schemas/briefs/ ×4 files deleted · deliberation path
re-point (verify B1) · audit + attention-manager D4 edits ·
operator/reference cluster refresh follows post-B5 (VO-009 adjacency).
CLAUDE.md:106 → B6. *(writing-coach/critic merge remediations removed —
merges declined at approval.)*

## AC check (VO-023, B5 half)

- B5 pack separately named, carries disposition list + remediation map +
  approval record ✓ (approved 2026-06-10 with recorded exception)
- Every delete/merge row for skills/agents covered ✓ (3 merges remediated;
  2 declined merges reverted to keep; 2 conditional rows with proposed
  shapes; 4 agents dispositioned)
- Every kept skill has a drafted trigger-condition description ✓ (17/17)
- Each gotcha links a recorded failure ✓ (2 gotchas, both linked)
