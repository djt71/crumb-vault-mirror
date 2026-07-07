---
type: design
project: skills-library
domain: software
status: active
created: 2026-07-07
updated: 2026-07-07
source: specification.md
tags:
  - design
  - skills-review
topics:
  - moc-crumb-architecture
---

# Skills System Review — 2026-07

Operator-requested full review of all 15 skills in `.claude/skills/`, run at the start of skills-library PLAN-phase work. Three review dimensions per skill — (1) practicality vs. original goal, (2) optimization of the procedure, (3) missing functionality / improvements — plus a portability classification that feeds SKL-001 tier classification.

**Method:** four parallel review agents (one per skill cluster, full SKILL.md + bundled-file reads, stale-reference spot-checks) plus a usage-evidence sweep over 24 log files (~14k lines: session logs, failure log, all project + archived run-logs). Usage counts are rough, deduped to distinct invocation events, with common-word false positives manually excluded.

## Headline Findings

1. **Usage is bimodal, and the split follows structural wiring, not skill quality.** Skills wired into workflow gates (audit ~22–25 uses, action-architect ~9–10, systems-analyst ~8–9, peer-review ~7–8) get steady real use. Skills that depend on the operator or model spontaneously reaching for them get almost none. This is the Ceremony Budget Principle confirmed empirically: the invocation path, not the capability, determines adoption.
2. **Four skills have zero-to-one credible uses ever:** critic (one review note, 2026-03-15), deliberation (36 records, but nearly all H1–H4 experiment apparatus — never dispatched on a real operational artifact), vault-query, writing-coach. Three more are near-zero: researcher (1 real dispatch, 2026-03-08), deck-intel (1 project, March), mermaid (no genuine deliverable diagram found in logs). sync is systematically bypassed (~251 commit/push events in logs, ~19 co-occur with "sync"; inline git confirmed as the norm).
3. **Strategic tension for SKL-001:** the zero-usage skills (writing-coach, critic) are precisely the spec's top portable-tier candidates. Two readings: (a) their value was never accessible on Crumb because main-session Claude already does these tasks inline — portable projection to claude.ai is where they finally earn their keep; or (b) they are dead weight and SkillsBench's "exclusion is as valuable as inclusion" says don't ship them. Operator call needed (see Recommendations C3).
4. **Systemic drift cluster around session machinery:** the SessionStart hook, startup skill, and audit §1 triple-claim session-start scanning; the hook emits `stale_summaries: 0` unconditionally (vault-check deferred to pre-commit), so the staleness-detection chain is silently broken end-to-end; sync's description points at a session-end protocol numbering that no longer exists and the protocol re-implemented sync's job without referencing it.
5. **Progressive disclosure failures in both directions:** inbox-processor inlines a ~300-line NotebookLM subpipeline that fires rarely; mermaid inlines ~230 lines of pretraining-redundant Mermaid syntax while correctly deferring its genuinely novel Excalidraw material. researcher is the roster's best disclosure example (orchestrator SKILL.md, per-stage bundled prompts) but carries dead protocol machinery from a retired external-runner architecture.
6. **Stale references found and verified:** CLAUDE.md still points at the deleted obsidian-cli skill (content merged into vault-query, commit 84343a30); inbox-processor cites `crumb-design-spec-v2-0.md` (now v2-4); vault-query's search path includes a `dossiers/` directory that was never created; mermaid always-loads a RESOLVED bookmark doc on every invocation; systems-analyst and action-architect both carry a manual `knowledge-retrieve.sh` step that the skill-preflight hook superseded; deliberation writes batch/synthesis output to a `data/deliberations/` path that doesn't exist.
7. **The review cluster's biggest cost is duplication, not any single skill:** three near-identical dispatch agents (code-review-dispatch, peer-review-dispatch, deliberation-dispatch — 1,211 lines, three maintained copies of the same safety-gate/wrap/dispatch/store procedure) plus severity/synthesis conventions duplicated between code-review and peer-review. One parameterized dispatch agent + one shared conventions doc preserves every capability at under half the maintenance surface.

## Usage Evidence (condensed)

| Skill | Real usage | Most recent | Signal |
|---|---|---|---|
| audit | ~22–25 | 2026-07-06/07 | Weekly/monthly cadence as designed |
| action-architect | ~9–10 | 2026-07-07 | Reliable PLAN→TASK use across 9 projects |
| systems-analyst | ~8–9 | 2026-07-07 | Reliable SPECIFY use; bypassed 2× (mission-control claude.ai specs) |
| peer-review | ~7–8 | 2026-07-07 | Most consistent SPECIFY-gate skill |
| code-review | ~11 | 2026-04-18 | All pre-April (FIF, tess-v2, MC); zero since despite §23 mandate — recent skips legitimate (no repo_path) but verify no repo project merged unreviewed since April |
| inbox-processor | ~5 | 2026-03-06/08 | Post-fold 7-step redesign untested in production |
| deck-intel | ~2–3 | 2026-03-06 | One real extraction project; idle since |
| researcher | 1 | 2026-03-08 | Single real dispatch ever; ~4 months idle |
| sync | ~2 named | routing test | **Bypassed:** commit/push done inline as a norm |
| mermaid | ~0 genuine | routing test | Diagrams hand-edited in docs without skill invocation |
| startup | 0 manual | — | Hook does the work autonomously; /startup never invoked |
| critic | ~1 | 2026-03-15 | One review note in Sources/research (missed by log sweep); merge into peer-review REJECTED 2026-06-10 |
| deliberation | 0 operational | routing test | 36 records exist but ≈all are H1–H4 experiment artifacts; VO-032 dispatch still "pending" |
| vault-query | 0 | routing test | Born from obsidian-cli merge; never queried for real work |
| writing-coach | 0 | — | Not even in the 2026-07-06 routing spot-check sample |

## Per-Skill Findings

### Workflow / operations cluster

**systems-analyst** (294 ln, reasoning) — Practical and battle-tested; procedure maps cleanly to goal. Issues: dead manual `knowledge-retrieve.sh` step (hook supersedes); Learning Plan Variant ~95 lines inline (fires rarely — extract to bundled file, ~35% SKILL.md cut); Step 4 Task Decomposition does action-architect's job during SPECIFY (task IDs + acceptance criteria → duplicate artifacts that go stale); domain list omits `lifestyle`; unnamed "§5.3/§5.4" refs; missing `learning-plan-patterns/` directory referenced. **Portability:** portable-with-transform. **Severity: moderate.**

**action-architect** (160 ln, reasoning) — Good and right-sized; targeted-partial-read rule is a genuinely practical guard; calibration loop live. Issues: same dead knowledge-retrieve.sh step; Signal Scan / Overlay Check / Peer Review Offer blocks duplicated near-verbatim with systems-analyst — extract to one shared referenced doc. **Portability:** portable-with-transform. **Severity: minor.**

**audit** (174 ln, reasoning) — Weekly/monthly batteries are practical and vault-specific (checklists earn their keep here). Issues: §1 session-start scan is a stale claim — hook owns it now, and the hook's hard-coded `stale_summaries: 0` means nobody detects stale summaries at session start anymore; weekly checks 6+7 are duplicates; dead `tessHarnessIssues` dashboard field (Tess defunct); §4 checkpoint welded on and duplicates context-checkpoint-protocol.md (two sources of truth), and instructs slash commands the model can't invoke autonomously. **Portability:** Crumb-only. **Severity: moderate.**

**sync** (75 ln, execution) — Weakest primitive of the roster. Session-end protocol §7 re-implemented its core without referencing it; description's "steps 4-5" is stale (protocol has 7 steps); the one judgment step (no work stranded in context) is unverifiable by the Sonnet subagent the routing policy sends it to; backup step is vague and ignores the real launchd backup infrastructure. Worth keeping: stage-specific-files rule + secrets check. **Recommend: fold into session-end protocol and retire, or demote to the protocol's referenced executor.** **Portability:** Crumb-only. **Severity: moderate.**

**startup** (19 ln, execution) — Best-in-roster right-sizing: mechanical work in the script, 4-step display contract in the skill, `disable-model-invocation: true`. Minor: step 4 re-runs actions the silent hook handling already performed (add idempotency note); Sonnet delegation buys nothing for a script run + verbatim echo — keep in-session. **Portability:** Crumb-only. **Severity: minor.**

### Quality / review cluster

**code-review** (435 ln, reasoning) — *Post-review addendum: Claude Code now ships a built-in `/code-review` command — exact name collision; see Addendum and §C-7.* Sound and battle-tested pipeline; the test gate (don't dispatch known-broken code), budget gate, and diff-size thresholds are real-cost lessons. But it's the heaviest skill in the cluster and partly over-engineered: Step 4b signal-detection and Step 7b cluster-analysis tables are railroading — pseudo-mechanical thresholds prescribing what a reasoning-tier model does naturally (~80 lines compressible to ~10 of guidance); reviewer model versions hardcoded in body + run-log template ("Claude Opus 4.6", "GPT-5.3-Codex") despite code-review-config.md being the declared source of truth — pin-tier-not-version violation; 16-item checklist restates the steps; severity table, synthesis structure, decision authority, and round cap duplicated near-verbatim from peer-review (visibly a fork of it). **Portability:** Crumb-only (Codex CLI + git tooling + multi-model dispatch don't survive a sandbox). **Severity: moderate.**

**critic** (231 ln, reasoning) — Best-proportioned skill in the cluster: rigor tiers (light/standard/deep) scale citation-check effort, review dimensions are guidance not script, do-not-invoke rules are sensible anti-ceremony guards, zero external dependencies. Yet only one recorded review note ever (2026-03-15) — either the triggers rarely fire or peer-review absorbs the demand. Spec bug: Step 3 and Output Constraints reference `review_focus` and `citation_check` parameters that intake never captures. Taxonomy diverges from its siblings (C-/S-/M- IDs + accept/revise/reject vs. namespaced IDs + must-fix/should-fix/defer). **Recommend repositioning as the default cheap first gate ahead of peer-review** — zero API cost, full vault access; escalate to the external panel only for HIGH-impact artifacts. **Portability:** portable-with-transform (minimal — only vault colocation/frontmatter strip away); strongest portable candidate in the cluster. **Severity: minor.**

**deliberation** (414 ln, reasoning) — Works (36 records exist) but nearly all are H1–H4 hypothesis-testing and gate-evaluation artifacts: this is experiment apparatus, not an operational tool. Its primary artifact type (`opportunity-candidate`) belongs to the archived opportunity-scout pipeline, and the portfolio is EMPTY by declaration — the main operational use case may be defunct. Path bug: batch/synthesis steps write to `data/deliberations/` (doesn't exist) while Output Constraints say `_system/data/deliberations/` (does). Experiment residue (`experimental_force_pass_2`, blinded rating capture); Step 4 pastes the full dispatch-agent instructions into the prompt instead of using the registered agent type (token waste + two-copy drift); spec shorthand leaks (SS8.6, §9) assume the reader holds the project spec. **Recommend: strip to an operational "panel mode" folded into peer-review, or archive with the overlay/dissent design preserved as a pattern doc.** **Portability:** Crumb-only. **Severity: moderate (major if archive/merge taken).**

**peer-review** (259 ln + 238-ln bundled doc, reasoning) — Strong; the most-used skill in the cluster and right-sized. Diff-mode-by-default, the 3-round cap with reset phrasing, partial-dispatch recovery via raw-JSON ground truth, and the Grok calibration gotcha are accumulated operational lessons. Issues: bundled `agentic-extraction-spec.md` is a completed historical design doc that risks being loaded as context — move to `_system/docs/` or a project design/ folder; Step 3 spawns `general-purpose` + pasted agent-file instructions instead of the registered `peer-review-dispatch` agent type (deliberation shares the defect); it owns the shared conventions core that code-review duplicates. **Portability:** Crumb-only (multi-external-model triangulation is the product). **Severity: minor.**

**Cluster verdict:** keep code-review and peer-review separate (genuinely different inputs and gates — merging would produce one bloated mode-branched skill) but **extract the shared machinery**: one review-conventions doc (severity normalization, synthesis sections, action-item classification, round cap, decision authority, safety-gate OVERRIDE handoff) referenced by both, and **one parameterized dispatch agent replacing the three near-identical dispatch agents (1,211 lines, three maintained copies of the same safety-gate/wrap/dispatch/store procedure — the single largest consolidation win in the roster)**. Reposition critic as the light first-tier gate. Deliberation is the consolidation candidate. Net: ~2,550 lines of skill+agent text → well under half, with no distinct capability lost.

### Intake / content cluster

**inbox-processor** (732 ln, reasoning) — Three skills in a trenchcoat: standard intake (~200 ln), NLM export pipeline (~300 ln), orphan sweeps. Each individually sound and failure-scar-grounded (crash-resilient write-before-move, no-fabricated-descriptions), but length only ~60% earned. Issues: NLM path inline yet rarely fires — extract to bundled file loaded on sentinel detection (~40% cut); companion-note schema triple-encoded; 32-item checklist (~10 non-obvious invariants); stale `crumb-design-spec-v2-0.md` ref; **composability contradiction with deck-intel** — deck-intel declares itself composable from inbox-processor and targets the companion note's `## Visual Content` section, but inbox-processor Step 5c forbids image interpretation and never mentions the handoff; no routing decision rule for intel-bearing PPTX/PDF. **Portability:** Crumb-only. **Severity: moderate.**

**deck-intel** (472 ln, reasoning) — Best-justified long skill: encodes real environment knowledge (hidden-slide XML drop, PNG-export-slide-1-only → PDF intermediary, speaker-notes value) and real analytical discipline (noise filter, shelf-life tagging). Issues: employer-specific vendor table (Infoblox/Zscaler/PAN) hardcoded in skill body — move to Network Skills overlay; knowledge-note schema duplicated with inbox-processor (single-source via file-conventions.md); Output Constraints + checklist restate Step 7 (~40 ln compressible). **Portability:** portable-with-transform (core method runs in claude.ai sandbox VM; loses LibreOffice-dependent rendered-slides mode). **Severity: minor.**

**mermaid** (563 ln + 4 bundled, execution) — Value density split: Obsidian-version caveats, dark-mode corruption rules, pitfalls, and the whole Excalidraw mode (+ validator script) are exactly where a skill beats pretraining; the ~230-line Mermaid syntax quick reference is not. Issues: **`html-rendering-bookmark.md` loaded with `condition: always` on every invocation — the doc is RESOLVED (2026-07-05) and contributes nothing; highest-leverage single edit in the roster**; inverted disclosure (demote syntax reference to bundled file, ~40% cut); stale pointer in diagram-patterns.md to a nonexistent SKILL.md section. **Portability:** portable-with-transform — Excalidraw mode is the most portable high-value asset in the roster. **Severity: moderate.**

**writing-coach** (115 ln, reasoning) — Closest to the lean-skill ideal; condition-gated anti-patterns load is a model of proportionate ceremony. Marginal value thin (editing is pretraining-strong) but cheap. Issues: convergence dimensions listed twice; `writing-patterns/` compound directory never created (loop never fired). **Lightest-transform portable candidate — bundle ai-telltale-anti-patterns.md and it ships nearly as-is.** **Portability:** portable-with-transform. **Severity: minor.**

### Research / retrieval cluster

**researcher** (534 ln + 10 bundled ~1,686 ln, reasoning) — Works when used (7 completed dispatches in `_scratch/research/`, real telemetry, 0 escalations) and has the roster's best progressive disclosure — but 1 real dispatch since mid-March and heavy vestigial protocol: governance hash/canary, token-count fields an LLM can't measure, transcript_path — all residue of a retired external-runner architecture. Internal contradictions: Step 3.2 vs Known Limitation 3 on `allowedTools`; artifact routing says `Sources/papers|articles/` while practice and frontmatter say `Sources/research/`; `cost_profile.model` pins `claude-opus-4-6` (violates pin-tier-not-version policy). ~300 lines of duplicated output-envelope JSON across stage files. **Decision needed vs. built-in deep-research skill** — substantial overlap in stages 3–5 (fan-out search, verification, cited synthesis); researcher's differentiated value is at the edges (vault scoping, persistent fact ledger, `[^FL-NNN]` mechanical validation, vault routing, telemetry). Option (a): reposition researcher as the vault-integration wrapper and delegate the web-research core to deep-research (retires most of stage 03's 450 lines). Option (b): keep both, add disambiguating trigger language. **Portability:** portable-with-transform (ledger discipline transfers; persistence/telemetry don't — and claude.ai has native research). **Severity: moderate.**

**vault-query** (108 ln, execution) — Right-sized; tiered cost-ordered search strategy + 15-file cap are the ideal Crumb shape. Issues: never used for real work (but it's also the designated callable primitive other skills should use — researcher's Scoping stage reimplements it instead of calling it); risk-alignment table lists write/destructive CLI commands in a skill whose constraints say read-only (vestige of the obsidian-cli merge); `customer-intelligence/dossiers/` path never existed; Sonnet round-trip exceeds the task for MINIMAL one-fact lookups (permit inline execution for trivial queries). **Portability:** Crumb-only (the vault, not the skill, is the dependency). **Severity: minor.**

**obsidian-cli** — no longer exists (deleted in ceremony-reduction commit 84343a30; content lives in vault-query). **CLAUDE.md line 71 still references it** — one-line fix, natural rider for VO-037's CLAUDE.md slim-down.

## Cross-Cutting Drift Register

Concrete fixes, each independently applicable:

1. Remove manual `knowledge-retrieve.sh` step from systems-analyst + action-architect (hook supersedes). Two one-line deletions.
2. Fix CLAUDE.md obsidian-cli reference → "see vault-query skill" (rider for VO-037).
3. Remove/condition-gate mermaid's `html-rendering-bookmark.md` always-load.
4. Repair the staleness chain: hook emits `stale_summaries: 0` unconditionally while audit §1 still claims the scan — decide the owner (hook) and delete audit §1; either restore a real staleness feed or stop pretending one exists.
5. Reconcile sync with session-end protocol §7 (fold-and-retire or reference-as-executor).
6. inbox-processor: v2-0 → v2-4 spec ref; add deck-intel handoff rule (closes the composability contradiction).
7. Extract shared Signal Scan / Overlay Check / Peer Review Offer blocks from systems-analyst + action-architect into one referenced doc.
8. Single-source the knowledge-note schema (inbox-processor + deck-intel → file-conventions.md).
9. researcher: strip dead runner-protocol fields; fix allowedTools contradiction; fix artifact routing; unpin model version.
10. vault-query: fix/remove dossiers path; trim write-command rows or retitle section as the vault-wide CLI safety reference.
11. deliberation: fix `data/deliberations/` → `_system/data/deliberations/` path bug.
12. peer-review + deliberation: rewrite dispatch steps to invoke the registered dispatch agent types directly instead of general-purpose + pasted agent-file instructions (token waste, two-copy drift).
13. code-review: remove hardcoded reviewer model versions from body/run-log template; defer to code-review-config.md (pin tier, not version).
14. peer-review: move bundled `agentic-extraction-spec.md` (completed historical design doc) out of the skill directory.
15. critic: capture `review_focus` + `citation_check` at intake (currently referenced but never collected).

## Recommendations (ranked)

### A — Quick wins (one-line to one-section edits, no design decisions)
Drift register items 1, 2, 3, 6 (spec ref), 9 (cosmetic parts), 10, 11, 13, 14, 15; writing-coach dedupe; audit weekly-check 6+7 merge; drop `tessHarnessIssues`.

**STATUS: APPLIED 2026-07-07** (operator-approved, same day). Notes: extraction spec moved to `_system/docs/peer-review-agentic-extraction-spec.md` (no inbound references existed); vault-query CLI section retitled as the vault-wide safety reference (harmonizes with the CLAUDE.md fix) rather than trimming the write-command rows; audit weekly checks renumbered 1–15; `tessHarnessIssues` verified consumer-free in the crumb-dashboard repo before dropping; researcher routing fixed to `Sources/research/` (matches practice), allowedTools contradiction resolved in favor of Known Limitation 3 (soft scoping).

### B — Refactors (extraction/bundling, mechanical but multi-file)
- **Unify the three dispatch agents into one parameterized dispatch agent** (1,211 → est. ~400 lines; largest single consolidation win)
- **Shared review-conventions doc** (severity buckets, synthesis sections, action-item classification, round cap, decision authority, OVERRIDE handoff) owned by peer-review, referenced by code-review; align critic's taxonomy to it
- inbox-processor: extract NLM path to bundled file (~40% cut)
- mermaid: demote syntax reference to bundled file (~40% cut)
- systems-analyst: extract Learning Plan Variant to bundled file (~35% cut)
- researcher: dedupe output-envelope JSON across stage files (~300 ln)
- code-review: compress Step 4b/7b prescriptive tables to guidance (~80 → ~10 ln)
- Shared planning-skill blocks extraction (item 7)
- audit: move §4 checkpoint into context-checkpoint-protocol.md as single source
- Dispatch-step rewrites (item 12)

### C — Operator decisions (change what exists, not just how it's written)
1. **researcher vs. deep-research:** reposition researcher as the vault-integration wrapper around the built-in harness (recommended — retires ~450 lines and 4-month-idle machinery while keeping the ledger/validation/routing value), or keep both with disambiguated triggers.
2. **sync:** fold into session-end protocol and retire the skill (recommended — protocol already re-implemented it; one fewer primitive), or demote to referenced executor.
3. **Fate of the near-zero-usage skills (critic, deliberation, vault-query, writing-coach):** for each — wire into a gate (usage follows wiring, per finding 1), reposition as portable-tier value (writing-coach and critic are top candidates), or retire. The cluster review recommends repositioning **critic as the default cheap first gate ahead of peer-review** (zero API cost; escalate to the external panel only for HIGH-impact artifacts). Note: critic and writing-coach merges were already REJECTED 2026-06-10 — this review adds the usage evidence that wasn't on the table then.
4. **deliberation:** strip to an operational "panel mode" folded into peer-review, or archive with the overlay/dissent design preserved as a solutions pattern (recommended — its experiment purpose has concluded and its primary artifact type belongs to an archived pipeline).
5. **code-review silence check:** verify no repo_path project merged code without review since 2026-04-18.
6. **systems-analyst Step 4 demotion:** coarse work-areas sketch only; leave task IDs + acceptance criteria to action-architect (kills the duplicate-artifact staleness path).
7. **Built-in overlap policy** *(added 2026-07-07, post-review — see Addendum)*: decide a per-skill posture wherever Claude Code ships a built-in equivalent. Current instances: **code-review** (exact name collision with the built-in `/code-review` incl. `ultra` multi-agent cloud mode), **researcher** (functional overlap with built-in deep-research — already §C-1), **mermaid** (partial overlap with built-in dataviz — already noted in its findings). Recommended standing policy: built-in for the everyday case; Crumb skill repositioned as the differentiated/escalation tier with a description that disambiguates it from the built-in. Applied to code-review: built-in `/code-review` (or `ultra`) for routine passes, Crumb's cross-model panel (Codex running repo tooling + §23 gate wiring + run-log integration) reserved for high-stakes merges — mirroring the critic→peer-review tiering recommended above. Consider renaming the Crumb skill (e.g., `review-panel`) to eliminate the exact collision.

## SKL-001 Input: Portability Classification

| Skill | Tier call | Transform cost |
|---|---|---|
| writing-coach | **portable** | lightest — bundle anti-patterns doc, strip overlay/compound refs |
| mermaid (Excalidraw mode esp.) | **portable** | strip vault save-locations + Obsidian caveat layer |
| deck-intel (method) | **portable** | strip vault routing + deletion gate; loses LibreOffice mode |
| systems-analyst (method) | portable-with-transform | strip vault plumbing; learning-plan variant is pure method |
| action-architect (method) | portable-with-transform | strip vault context loading |
| researcher (ledger discipline) | portable-with-transform | heavy — persistence/telemetry don't transfer; claude.ai has native research |
| critic | **portable** | minimal — only vault colocation/frontmatter strip away; strongest cluster candidate |
| peer-review | Crumb-only | multi-external-model dispatch is the product |
| code-review | Crumb-only | Codex CLI + git tooling + API dispatch don't survive a sandbox |
| deliberation | Crumb-only | API keys, evaluator registry, vault record schemas |
| audit | Crumb-only | — |
| inbox-processor | Crumb-only | — |
| startup | Crumb-only | — |
| sync | Crumb-only | — |
| vault-query | Crumb-only | — |

Spec's working guess (3–5 portable: writing-coach, mermaid, deck-intel method, researcher stages, critic rubric) is largely confirmed — the portable core is **writing-coach, critic, mermaid/Excalidraw, deck-intel method** (researcher's transform is heavy and claude.ai has native research; defer it). writing-coach is the cheapest first upload for SKL-005 live verification.

## Addendum (2026-07-07) — Built-In Skill Overlap

Added same-day after the operator asked about Claude Code's built-in code-review capability. Verified against the live session's own skill roster (first-party evidence, not docs recall): Claude Code ships built-in review commands — **`/code-review`** (working-diff/branch review, with an `ultra` mode: multi-agent cloud review of the branch or a PR, operator-invoked and billed; `/ultrareview` is a deprecated alias), **`/review`** (GitHub PR review), and **`/security-review`** (security pass on pending branch changes).

Full collision sweep of the 15 Crumb skills against the built-in roster:

| Class | Instances | Status |
|---|---|---|
| **Exact name collision** | code-review ↔ built-in `/code-review` | Both coexist in the session roster; routing on "review this code" is ambiguous. New — no prior finding covered it. |
| **Functional overlap** | researcher ↔ deep-research; mermaid ↔ dataviz | Already captured (§C-1; mermaid per-skill findings) |
| **Adjacent, no collision** | review, security-review, verify, simplify built-ins vs. Crumb's code-review/audit territory | No action; monitor |

**Pattern worth naming:** the built-in surface is growing release over release, and Crumb skills that duplicate built-in territory inherit the researcher problem — locally maintained machinery sitting idle next to a zero-maintenance built-in that improves on its own. The durable posture is to hold Crumb skills to their *differentiated* value (cross-model panels, vault wiring, gate enforcement — things a built-in structurally can't do) and cede the generic case. Elevated to §C decision 7. Suggested future guard: add a built-in-collision row to audit's operator/architecture drift check (weekly check 13) so new built-ins get caught at audit time rather than by accident — registered as a candidate, not applied (audit edits beyond Tier A are out of scope here).
