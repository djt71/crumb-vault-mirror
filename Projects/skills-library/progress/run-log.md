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

## 2026-07-07 — §C decisions: all seven decided and executed (roster 15 → 11)

**Operator decisions (interactive, AskUserQuestion flow):** C1 researcher RETIRE (beyond wrapper rec); C2 sync fold & retire; C3a critic RETIRE (after refresher); C3b vault-query keep + inline execution for trivial lookups; C3c writing-coach portable tier, local source kept; C4 deliberation archive + pattern doc; C5 verified clean by Claude (zero commits in semuta/crumb-dashboard since 2026-04-18; tess-v2's two commits were AS decommission sweeps — no unreviewed merges); C6 systems-analyst Step 4 demote; C7 adopt built-in overlap policy + rename code-review → review-panel.

**Execution (all applied this session):**
- Retired via git rm (history preserves; follows 84343a30 precedent): `.claude/skills/researcher/` (SKILL.md + 10 bundled), `critic/`, `sync/`, `deliberation/` + `.claude/agents/deliberation-dispatch.md`
- Renamed via git mv: `.claude/skills/code-review/` → `review-panel/`; SKILL.md name + description repositioned (escalation tier above built-in /code-review); code-review-dispatch agent references updated (spawned-by, skill_origin, tags). Rename verified live: built-in /code-review no longer shadowed
- sync fold: secrets-check + stage-specific-files rules absorbed into session-end-protocol.md §7; CLAUDE.md model-routing Phase 1 now startup-only; sync removed from skill-preflight fast-path
- Pattern doc: `_system/docs/solutions/deliberation-panel-pattern.md` (confidence: medium, linkage: discovery-only) — role overlays/persona bias, two-pass dissent, blinded rating, stagger/config-hash mechanics; revival guidance = peer-review panel mode, not standalone skill
- systems-analyst: Step 4 Task Decomposition → Work Areas Sketch (coarse areas + risk only; task IDs/AC explicitly deferred to action-architect); Output Constraints updated; `lifestyle` added to domain list; 2 researcher refs → built-in deep-research
- Policy codified: skills-reference.md new "Built-In Overlap Policy" section (4 rules + current tiering); audit weekly check 13 gained built-in collision row
- Reference sweep: vault-check.sh REGISTERED_SKILLS → 11 (review-panel in; retired out), skill_pattern += review-panel (historical names retained for old artifacts); skills-reference.md fully reconciled (tables, counts, tree, retirement note); vault-query + operator docs (the-vault-as-memory, first-crumb-session) researcher refs → deep-research; skills-review.md §C statuses + SKL-001 table + portable core (now 3: writing-coach, mermaid/Excalidraw, deck-intel method)

**Tier B consequence:** dispatch-agent unification shrinks to two agents (review-panel + peer-review); researcher envelope dedupe moot; shared review-conventions doc still applies.

**Compound note:** "usage follows wiring" pattern candidate (flagged earlier this session) now has a governance corollary applied in practice: the built-in overlap policy prevents maintaining local machinery the harness ships for free. Both await operator approval as solutions/ entries — the deliberation pattern doc was operator-approved explicitly (C4).

## 2026-07-07 — Session-end (compound evaluation)

**Session summary:** Single session spanning the full arc: (1) 15-skill system review via 5-agent fan-out (4 Fable 5 cluster reviewers + 1 Sonnet usage sweep over 24 log files) → `design/skills-review.md`; (2) Tier A quick wins applied and committed (98911107 + af5c2640, pushed); (3) operator discussion — Crumb as harness engineering (usage-follows-wiring as the empirical core); (4) built-in `/code-review` question → collision sweep → Addendum + §C-7; (5) all seven §C decisions made interactively and executed same-session: roster 15→11 (researcher, critic, sync, deliberation retired; code-review → review-panel; built-in overlap policy adopted; systems-analyst Step 4 demoted; vault-query inline allowance; C5 verified clean). Rename verified live in-harness (built-in no longer shadowed).

**Compound evaluation:** One pattern candidate carried, not yet promoted: **"usage follows wiring, not quality"** — skills invoked by mechanical paths (hooks, gates, pre-commit) get used; skills relying on spontaneous trigger-matching starve (empirical: 15 skills, ~5 months of logs). Generalizes the Ceremony Budget Principle (invocation path is part of the ceremony) and directly motivated §C outcomes. Medium confidence → solutions/ write awaits operator approval (Ask First per CLAUDE.md). Conventions routed this session instead of new solutions docs where possible: built-in overlap policy → skills-reference.md (existing doc); deliberation design → solutions/deliberation-panel-pattern.md (operator-approved via C4). Validation: the review's method (usage evidence grounding practicality claims) proved decisive — three §C retirements would have been undetectable from SKILL.md text alone.

**Protocol steps (7-step):** (1) log — this entry. (2) project-state refresh — next_action updated post-§C ✓ (verified consistent with outcomes). (3) failure-log — not warranted (clean session; one subagent API-error retry recovered per exception chain step 1). (4) code review sweep — N/A (no repo_path; script edits to vault-check.sh/skill-preflight.sh syntax-verified). (5) build verification — N/A. (6) qmd update — run at close. (7) commit & push — substantial delta flagged to operator earlier; operator ended session → descriptive commit + push per protocol.

**Model routing:** main session Fable 5 throughout. Subagents: 4× Fable 5 (cluster reviews, 63–102k tokens each — reasoning-tier judgment work, justified), 1× Sonnet (usage sweep, 159k tokens, mechanical grep/classify = execution tier; quality: pass, no rework). One API-error mid-response on the quality-cluster reviewer → single SendMessage resume retry → full recovery (infra, not model). AskUserQuestion used for the 7-decision flow — one clarification round (critic refresher) before final answer.

**State for next session:** SPECIFY→PLAN gate (context-checkpoint-protocol), then PLAN. Key design question: A4 single-source mechanism + tier-marker frontmatter key. Portable core locked: writing-coach (SKL-005 first upload), mermaid/Excalidraw, deck-intel method. Tier B refactors available and reshaped by §C (dispatch unification = 2 agents; shared review-conventions doc; NLM/syntax/learning-variant extractions). Pending operator approvals: "usage follows wiring" solutions doc; peer review of spec (STANDARD offer stands).
