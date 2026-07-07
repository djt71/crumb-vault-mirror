---
type: run-log
project: skills-library
domain: software
status: active
created: 2026-07-06
updated: 2026-07-06
topics:
  - moc-crumb-operations
tags:
  - run-log
---

# skills-library — Run Log

## 2026-07-06 — Project creation

**Trigger:** Operator wants a skills library available across the two Class 3 work surfaces: Claude Code (Crumb) and claude.ai (Cowork). Feasibility assessment done pre-project (this session); operator approved project creation.

**Operator decisions (project creation gate):**
1. Name/domain: `skills-library`, domain software, type system, vault-only (no external repo — repo gate skipped per CLAUDE.md §3b)
2. Two-surface picture confirmed as the accurate mental model: Crumb + Cowork/claude.ai are the work surfaces; `work-surfaces.md`'s seven-entry roster covers surfaces *plus* channels/viewing/substrate — doc revision is in scope for this project or flagged to quarterly review.

**Pre-project findings (verified 2026-07-06 via claude-code-guide agent against platform.claude.com / code.claude.com / support.claude.com docs):**
- SKILL.md format (YAML frontmatter + markdown + bundled files) is identical across Claude Code, claude.ai, Cowork, API — fully portable.
- **No cross-surface sync exists.** claude.ai: per-user zip upload via Settings. Cowork: Skills tab or `/v1/skills` API (workspace-wide). Claude Code: `.claude/skills/` filesystem.
- Execution asymmetry: Claude Code + Cowork have local filesystem/bash; claude.ai runs skills in a sandboxed code-execution VM (no local fs, no local bash, network varies).
- Limits: 20 skills/session (Managed Agents API); name ≤64 chars, description ≤1024 chars; file-size/bundle-count limits undocumented.

**Working thesis (input to SPECIFY, not yet spec'd):**
- Three tiers: **Crumb-only** (vault machinery — sync, audit, inbox-processor, code-review, etc.), **portable core** (pure procedure/judgment — writing-coach, mermaid, deck-intel method, researcher stages, critic rubric), **claude.ai-only** (non-markdown deliverable production, connector-native workflows, away-from-desk `_inbox/` capture formatting, write-boundary discipline substitute).
- Architecture principle: vault originates; claude.ai/Cowork copies are regenerated projections (same class as `claude-ai-context.md`). No sync daemon, no promotion machinery — a packaging script + operator-triggered upload (ceremony budget).
- Highest-value claude.ai-only candidate: a "Cowork vault etiquette" skill carrying write-boundary classes inline (claude.ai has no CLAUDE.md/hooks/vault-check).

**Next:** Enter SPECIFY (systems-analyst) in a fresh phase of work — define tiers, membership criteria, packaging mechanism, doc-update scope.

## 2026-07-06 — SPECIFY: context inventory

**Context inventory (systems-analyst, standard tier — 4 docs + budget-exempt items):**
1. `_system/docs/work-surfaces.md` — surface roster, memory ownership (vault originates / projections), write-boundary summary, intake policy
2. `Sources/insights/skillsbench-agent-skills-mixed-results.md` — empirical: 2-3 focused skills +18.6pp vs comprehensive −2.9pp; skills only compound where pretraining is weak; Claude Code integrates skills reliably
3. `Sources/signals/trq212-anthropic-skill-design-lessons.md` — first-party skill design: description = trigger conditions; progressive disclosure; gotchas section; config.json; avoid railroading
4. `Sources/research/research-brief-superpowers.md` — real skill-library architecture; distribution-model contrast (personal infra vs marketplace); pressure-test methodology for skill validation
- Budget-exempt: skill-preflight knowledge brief; prior art `_system/docs/solutions/memory-stratification-pattern.md` (high confidence — markdown+git canonical, other stores are caches)
- Overlay check: **no overlay loaded** (Crumb-internal system infrastructure; Network Skills anti-signals it; no business/financial dimension)
- Signal scan: >15 hits on kb/software-dev → keyword intersection filter → 7 candidates presented; operator selected top 3 (items 2-4 above)
- Live inventory: 15 skills in `.claude/skills/` (action-architect, audit, code-review, critic, deck-intel, deliberation, inbox-processor, mermaid, peer-review, researcher, startup, sync, systems-analyst, vault-query, writing-coach)

**Operator decisions (SPECIFY clarification gate):**
1. Sources: top 3 only
2. First-delivery scope: portable tier + packaging; claude.ai-only skills = later tasks in same project
3. Delivery mechanism: manual upload only — no /v1/skills API automation (ceremony budget)
4. Doc revisions (work-surfaces.md + claude-ai-context.md) are IN scope

## 2026-07-06 — Session-end (compound evaluation)

**Session summary:** Project created and SPECIFY completed in one session. Sequence: (1) operator question on work-surfaces roster → identified the two-Class-3-surface picture (Crumb + Cowork/claude.ai) as the operative mental model; (2) cross-surface skills feasibility assessment — verified via claude-code-guide agent against live Anthropic docs (format portable, no sync, sandbox asymmetry); (3) project creation gate (skills-library, software/system, vault-only); (4) SPECIFY via systems-analyst — context inventory (4 docs standard tier), signal scan with noise gate (>15 hits → keyword filter → operator picked 3), no overlay (correctly anti-signaled), 4 operator decisions, spec + summary written. 7 tasks SKL-001–007. Peer review offered (STANDARD), not yet requested.

**Compound evaluation:** One validation, no new promotion: the **memory-stratification pattern** (solutions/, high confidence) extends cleanly from context docs to *executable* artifacts — "vault originates, surfaces get regenerated projections" required zero adaptation when the projected artifact became a skill zip rather than a context file. Recurrence strengthens the existing doc; no edit needed now (spec cites it). Candidate to watch: if SKL-005 upload verification reveals surface-specific transforms are unavoidable (A4 false), that becomes a projection-with-transform variant worth a solutions/ note — defer until evidence.

**Protocol steps (7-step):** (1) log — this entry. (2) project-state refresh — next_action already current (spec complete, gate next) ✓. (3) failure-log — not warranted (clean session, zero rework). (4) code review sweep — N/A (no repo_path). (5) build verification — N/A. (6) qmd update — run at close. (7) commit & push — substantial delta (new project incl. specification.md), descriptive commit, flagged to operator.

**Model routing:** all main-session Fable 5 + one claude-code-guide subagent (docs verification, ~35k tokens — justified: platform facts needed live verification, not memory). No execution-tier delegation (no mechanical skills invoked).

**State for next session:** SPECIFY→PLAN gate (context-checkpoint-protocol) then PLAN. Key design questions carried: A4 single-source mechanism (one SKILL.md both surfaces vs packaging-time transform); tier-marker frontmatter key; dist/ location + .gitignore entry. Optional first: peer review of spec (STANDARD offer stands, one session only).

## 2026-07-07 — Skills system review (operator-requested, pre-PLAN design input)

**Trigger:** Operator requested a full review of all 15 skills before PLAN — practicality vs. original goal, procedure optimization, missing functionality/improvements. Run as a design artifact feeding SKL-001 tier classification.

**Context inventory:** project-state.yaml, specification-summary.md, run-log (state reconstruction); CLAUDE.md ambient. Skill files + logs delegated to subagents (below) — main-session source-doc load stayed within standard tier.

**Method:** 5 parallel subagents (all Fable 5 except usage sweep on Sonnet — mechanical grep/classify work per model-routing policy): 4 cluster reviewers (workflow/ops, quality-panel, intake/content, research/retrieval — full SKILL.md + bundled-file reads, stale-ref spot-checks) + 1 usage-evidence sweep (24 log files, ~14k lines, false-positive filtering). Exception handled per protocol: quality-panel agent died on API server error mid-response → single retry via SendMessage resume of same agent (context preserved) → complete result. Usage agent ~159k tokens (justified: full-corpus sweep); reviewers 63–102k each.

**Deliverable:** `design/skills-review.md` — headline findings, usage table, per-skill findings (15 + defunct obsidian-cli), 15-item drift register, ranked recommendations (A quick wins / B refactors / C operator decisions), SKL-001 portability classification.

**Key findings:** (1) usage is bimodal and follows gate wiring, not skill quality — audit/action-architect/systems-analyst/peer-review carry the load; critic/deliberation/vault-query/writing-coach have zero-to-one real uses ever; sync is bypassed as a norm (inline git). (2) Review cluster's cost is duplication: 3 near-identical dispatch agents (1,211 ln) + duplicated conventions between code-review/peer-review. (3) Systemic drift: session-start triple-claim + silently broken staleness chain (hook emits stale_summaries: 0 unconditionally); superseded knowledge-retrieve.sh steps in both planning skills; CLAUDE.md → deleted obsidian-cli skill; deliberation path bug. (4) Strategic tension for SKL-001: the unused skills are the top portable candidates — portable core confirmed as writing-coach, critic, mermaid/Excalidraw, deck-intel method (researcher deferred: heavy transform, claude.ai has native research).

**Operator decisions pending (review §C):** researcher-vs-deep-research repositioning; sync fold-and-retire; fate of near-zero-usage skills (critic → cheap first gate recommended); deliberation strip-or-archive; code-review silence check (no reviewed merge since 2026-04-18); systems-analyst Step 4 demotion.

**Compound evaluation:** Candidate pattern — **"usage follows wiring"**: skills invoked by workflow gates get used; skills relying on spontaneous trigger-matching starve, regardless of quality (empirical across 15 skills / 5 months of logs). This generalizes the Ceremony Budget Principle: the invocation path is part of the ceremony. Medium confidence → per CLAUDE.md, flagging for operator approval before writing to `_system/docs/solutions/`. Also validates VO's ceremony-reduction thesis with the strongest evidence yet.

**Model routing outcome:** Sonnet usage-sweep delegation = pass (no rework; false-positive filtering held up against spot checks). Fable 5 reviewers = pass. One API-error retry (infra, not model quality).

## 2026-07-07 — Tier A quick wins applied (operator-approved)

**Scope:** all Tier A items from `design/skills-review.md` — 24 edits across 11 skill files + CLAUDE.md + 1 file move. No design decisions taken; Tier B/C untouched.

**Applied:**
- systems-analyst + action-architect: manual `knowledge-retrieve.sh` step replaced with hook-handled note (drift item 1)
- CLAUDE.md: obsidian-cli skill ref → vault-query skill, Obsidian CLI Reference section (item 2; operator-approved CLAUDE.md edit)
- mermaid: dead `html-rendering-bookmark.md` always-load removed from required_context (item 3)
- inbox-processor: spec ref v2-0 → v2-4 (item 6, spec-ref part)
- researcher (item 9, cosmetic parts): model pin → tier reference; allowedTools contradiction resolved (soft scoping per Known Limitation 3); knowledge-note routing → `Sources/research/` (matches produced_artifacts + practice, replaces majority-tier papers/articles logic); RUNNER_COMPUTES → DEFERRED
- vault-query: dossiers path → existing `staging/`/`comms/`; CLI section retitled as vault-wide safety reference with read-only clarification (item 10)
- deliberation: 2× `data/deliberations/` → `_system/data/deliberations/` (item 11)
- code-review: hardcoded reviewer model versions removed from panel headings + run-log template, deferred to code-review-config.md (item 13)
- peer-review: `agentic-extraction-spec.md` → `_system/docs/peer-review-agentic-extraction-spec.md` via git mv; zero inbound refs verified pre-move (item 14)
- critic: intake now captures `review_focus` + `citation_check` (item 15)
- writing-coach: duplicate Convergence Dimensions section removed (pointer to Step 4 retained)
- audit: weekly checks 6+7 merged (escalation block kept), checks renumbered 1–15; `tessHarnessIssues` dropped from dashboard JSON template (verified consumer-free in crumb-dashboard repo)

**Verification:** post-edit grep sweep across `.claude/skills/` clean — zero remaining hits for knowledge-retrieve.sh, html-rendering-bookmark, bare `data/deliberations`, Opus 4.6 / GPT-5.3 / opus-4-6 pins, spec-v2-0, RUNNER_COMPUTES, dossiers. vault-check deferred to pre-commit hook.

**Not committed yet** — substantial delta flagged to operator per conditional-commit policy.

## 2026-07-07 — Addendum: built-in skill overlap (operator question → review doc)

**Trigger:** Operator asked whether Claude Code's built-in code-review skill is real. Confirmed from the live session's own skill roster (first-party, not docs recall): built-ins `/code-review` (+ `ultra` multi-agent cloud mode, billed, operator-invoked; `/ultrareview` deprecated alias), `/review` (PR), `/security-review`.

**Finding:** exact name collision with Crumb's code-review skill — the third built-in-overlap instance after researcher↔deep-research (§C-1) and mermaid↔dataviz. Full 15-skill collision sweep run; no other collisions. Added to skills-review.md as an Addendum section + new §C decision 7 (built-in overlap policy: built-in for the everyday case, Crumb skill as differentiated/escalation tier; consider renaming code-review → review-panel). Candidate guard registered (not applied): built-in-collision row in audit weekly check 13. project-state next_action updated (7 decisions pending).
