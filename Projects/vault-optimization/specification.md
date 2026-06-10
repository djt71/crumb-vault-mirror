---
type: specification
project: vault-optimization
domain: software
skill_origin: systems-analyst
status: active
created: 2026-06-10
updated: 2026-06-10
related_projects:
  - agentic-sunset
topics:
  - moc-crumb-operations
tags:
  - specification
---

# vault-optimization — Specification

## Problem Statement

Post-agentic-sunset, the vault still carries the primitive surface, documentation, and storage weight built for the retired "personal multi-agent OS" era, while the actual core — a durable knowledge store and reasoning substrate — has never been formally defined and accepted. This project defines that core (by refreshing and accepting the proposed Crumb v3 identity ADR), then optimizes the vault down to it: pruning primitives, consolidating docs, reducing workflow ceremony, and deleting dead weight. Without it, maintenance gravity keeps growing against a shrinking operational need.

## Inputs & Provenance

1. `_system/docs/adr-crumb-v3-knowledge-store-identity.md` (2026-05-15, status: proposed) — **baseline by operator decision**
2. `_system/docs/crumb-v2-system-health-assessment.md` — ceremony budget provenance ("Reducing ceremony is higher leverage than adding capability", §Observations Worth Sitting With)
3. `_system/docs/solutions/infrastructure-teardown-discipline.md` — consumer-graph + end-condition disciplines
4. `Projects/agentic-sunset/action-plan-summary.md` — scope boundary
5. Signals (operator-selected): `Sources/signals/trq212-anthropic-skill-design-lessons.md` (trigger-condition descriptions = Anthropic-flagged HIGH value / LOW effort per its Gap 3; gotchas sections; anti-railroading), `Sources/insights/skillsbench-agent-skills-mixed-results.md` (arXiv 2602.12670: 2–3 focused skills +18.6pp vs 4+ skills +5.9pp vs exhaustive −2.9pp; skills net-negative in well-covered domains; self-generated skills fail)
6. `Projects/vault-optimization/reviews/2026-06-10-specification.md` — round-1 peer review (4-model panel); amendments A1–A9 applied 2026-06-10

## Facts

- The v3 ADR exists, is high-confidence, and was never accepted — its acceptance criteria are unchecked and its 4 operator questions unanswered.
- agentic-sunset (IMPLEMENT, M2 complete) owns runtime teardown and M6/M7 vault surgery: AS-025 (CLAUDE.md diff), AS-026–027 (`_openclaw/`/`_staging/TV2-*`/`_tess/` archival, gitignore churn), AS-028–029 (skills + memory cleanup), AS-030–032 (project closures, soak, archival proposals). **Operator decision: agentic-sunset keeps that scope.**
- Live inventory (2026-06-10, snapshot for planning only — regenerate baseline at TASK start): 2,504 markdown files (`find . -name "*.md" | wc -l`); 20 skills / 4 agents (`ls .claude/skills .claude/agents`), 8 overlays (overlay-index table), 20 `_system/scripts/`, 6 `_system/docs/protocols/`, 25 solution docs, 12 project directories, 9 domains. Directory weight (`du -sh`): `Archived/` 147 MB, `Projects/` 41 MB, `Sources/` 12 MB, `_system/` 5 MB, `_attachments/` 4.7 MB; vault total ≈211 MB, so `Archived/` ≈70% of working-tree weight.
- Operator decisions (2026-06-10, this session): (a) v3 ADR adopted as spec baseline; (b) all four axes in scope — primitive surface, docs & staleness, ceremony reduction, storage & weight; (c) **aggressive deletion** — git history is the archive; no Archived/-style reversibility requirement.
- No skill-usage telemetry exists; usage evidence must be reconstructed from session logs, run-logs, and git history.

## Assumptions (to validate)

- A1: The ADR's Tier 1/2/3 assignments are still approximately correct post-sunset; only refresh, not redesign, is needed. *(Validate in VO-001 review.)*
- A2: "Aggressive deletion" applies to working-tree content. Git **history rewrite** (the only way to shrink the repo itself) is out of scope unless separately decided. *(Confirm in VO-004.)*
- A3: The agentic-sunset operator decision to keep the dashboard stack (dashboard, vault-web, cloudflared) still stands; vault-optimization must not contradict it without an explicit new decision.
- A4: vault-check + Obsidian indexing will surface broken links/tags caused by deletions; no additional tooling needed.

## Unknowns

- U1: Actual usage frequency per skill/overlay/script — required evidence for keep/delete dispositions.
- U2: Exact AS-028/029 cleanup scope (not yet designed in detail) — joint boundary with VO primitive-surface work must be settled at task level before IMPLEMENT.
- U3: Whether the 6 protocols can consolidate without losing hook-enforced behavior.
- U4: Operator appetite for git history rewrite given `Archived/` 147 MB (high risk, separate decision).

## System Map

**Components:** CLAUDE.md (constitution) · primitive surface (skills, agents, overlays, scripts, protocols, hooks) · `_system/docs/` (reference + solutions library) · KB (`Sources/`, `Domains/`, `#kb/` taxonomy, MOCs) · project record (`Projects/`, `Archived/`) · harness memory (`~/.claude/.../memory/`) · git (history = the archive under aggressive deletion) · backup/drive-sync scripts · vault-check (enforcement).

**Dependencies:**
- agentic-sunset M3–M7 → hard sequencing gate for anything touching CLAUDE.md, `_openclaw/`/`_tess/`/`_staging/`, skills/memory cleanup (AS-owned).
- Deletion candidates → their consumer graphs (hooks, plists, wikilinks, MOCs, memory files, backup filter lists) per infrastructure-teardown-discipline #2.
- Aggressive deletion → git as sole recovery path → backup integrity (vault-backup, drive-sync, mirror-sync) must be verified **before** the deletion pass.

**Constraints:**
- Never break vault-check green / clean-tree discipline at batch boundaries (see VO-008 execution model — green is required at every commit checkpoint, not after every individual file operation).
- Liberation directive: revenue prompts take priority claim; this is infra and yields. Execution consequence: all IMPLEMENT work must be interruptible at commit-level checkpoints — small batches, never a half-applied state across sessions.
- CLAUDE.md modification remains stop-and-ask (and is AS-025's surface first).
- No external repo (vault-only project). Scope clarification: *modifications* are vault-only; dependency *analysis* includes adjacent non-repo surfaces (harness memory at `~/.claude/projects/-Users-danny-crumb-vault/memory/`, plists, `~/.config/crumb/`) which are coordinated via the joint-surface contract but not modified by this project unless separately authorized.

**Levers (high-impact intervention points):**
1. **ADR acceptance** — single decision that governs every downstream disposition.
2. **Keep-set manifest with usage evidence** — converts "optimize the vault" into mechanical per-item dispositions.
3. **Skill description audit** (trigger-condition phrasing) — Anthropic-flagged HIGH value / LOW effort; fixes undertriggering on kept skills.
4. **Ceremony reduction on kept workflows** — health assessment says this beats capability work; SkillsBench says focused beats exhaustive.
5. **`Archived/` deletion** — 147 MB ≈ 70% of vault weight in one directory.

**Second-order effects:**
- Deleting docs breaks wikilinks/MOC synthesis sections → consumer-graph sweep is mandatory, not optional.
- Deleting scripts can break plists/hooks that reference them (launchd quirks already bit this system) → same sweep.
- Memory files reference vault paths (AS-029 rewrites memories; VO deletions change targets) → coordinate at the AS boundary.
- A leaner primitive surface changes skill-routing behavior in every future session — descriptions must be re-tested after pruning.

## Domain Classification & Workflow Depth

- **Domain:** software (type: system, vault-only — no external repo).
- **Workflow:** full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT). Rationale: aggressive deletion is irreversible-in-working-tree, the surface is the system's own constitution-adjacent machinery, and the agentic-sunset precedent shows phase gates earn their keep on system surgery. Risk concentration (VO-008 execution) demands a validated plan and atomic tasks.

## Task Decomposition (initial — action-architect refines at TASK)

| ID | Task | Tags | Risk | Depends on |
|----|------|------|------|------------|
| VO-001 | Refresh + accept v3 identity ADR: review Tier 1/2/3 against post-sunset reality, answer its 4 open operator questions, check acceptance criteria, status → accepted. **Decision gate:** minor drift → proceed; material change to Tier model or identity → re-plan before VO-002 | #decision | medium | — |
| VO-002 | Core-functionality keep-set manifest: every skill/agent/overlay/script/protocol/doc-cluster gets a disposition per the evidence methodology below. **Appendix A: joint-surface contract** — per-surface ownership matrix vs agentic-sunset (AS-owned / VO-owned / jointly-reviewed / blocked-until-AS-close), covering skills, memory files, `_openclaw`/`_tess`/`_staging`, CLAUDE.md-adjacent docs | #research | low | VO-001 |
| VO-003 | Consumer-graph survey for all deletion candidates — mechanical search protocol: hooks, plists, wikilinks, **plain-text path/name grep**, MOCs, memory refs, backup/sync filter lists, Obsidian config/workspace, dashboard/web-serving config, naming-convention assumptions | #research | low | VO-002 |
| VO-004 | Storage & weight policy: `Archived/` deletion pass scope, `_attachments/` orphan sweep, **non-markdown top-N size audit**, log rotation policy, explicit git-history-rewrite decision (default: out of scope). Policy must state expected outcomes separately for (a) working-tree weight, (b) active-vault navigation surface, (c) repo/clone size — and state plainly that (c) does not improve without history rewrite | #decision | medium | VO-002 |
| VO-005 | Primitive surface optimization: prune per manifest; kept skills get trigger-condition descriptions + gotchas sections; overlay/protocol consolidation; consumer-graph remediation for every pruned item | #code #writing | medium | VO-002 (incl. Appendix A frozen), VO-003, AS M6 closure sign-off in run-log |
| VO-006 | Docs & staleness consolidation: `_system/docs/` curation, solutions library pruning, dead-reference sweep post-sunset, removal of Archived/-as-category assumptions from taxonomy/MOCs if VO-004 deletes it. Retention rule for superseded docs: **delete unless canonical-reference or compound-provenance** (no dormant-marking middle state) | #writing | low | VO-002, VO-003 |
| VO-007 | Ceremony reduction on kept workflows: phase gates, context-checkpoint protocol, session-end sequence, intake ceremony — optimize, don't just shrink | #decision #writing | medium | VO-001, **VO-002** (keep-set must exist before its workflows are redesigned), AS-025 complete |
| VO-008 | Execution & verification per the execution model below: backup verification → batched deletion with per-batch remediation → structural verification | #code | high | VO-003–VO-007 |
| VO-009 | Functional validation + soak: representative core workflows (per accepted ADR Tier 1) executed against the pruned vault during a defined soak window; failures block project completion | #research #decision | medium | VO-008 |

**Evidence methodology (VO-002):**
- Type-specific standards — skills: invocation traces in session/run-logs or repeated task contexts served; scripts: executions in logs/shell history OR references from hooks/plists/launchd (structural use counts as use); overlays/protocols: workflow inclusion or constitutional reference; docs: backlinks, MOC presence, canonical designation, or recent edits; project records: open dependency or active reference.
- Five-category disposition rubric: **proven active use · inferred structural necessity · low-use/high-consequence contingency (keep) · superseded/duplicative · no-evidence-and-no-dependency**.
- Extraction is mechanical (grep over session logs/run-logs/git log) and timeboxed per item — the timebox bounds search effort, never auto-converts to a delete verdict.
- **Every no-evidence deletion requires explicit operator review** — absence of evidence is not evidence of non-use, especially for contingency tooling.

**VO-008 execution model:**
- Backup verification (before first deletion): identify the authoritative backup set; confirm freshness; **restore-drill a sample file set on a throwaway clone**; verify ignored-path coverage or document exclusions; record the restoration procedure in the run-log.
- Deletions execute in **planned batches with atomic commit checkpoints**: each batch = consumer remediation + deletion + verification + commit; vault-check green required at every checkpoint.
- Partial-pass rule: finish or revert the current batch before stopping — never leave a half-applied state across sessions.
- Abort condition: vault-check turns red unexpectedly or a consumer surfaces that the VO-003 survey missed → stop, revert batch, re-survey before continuing.

**Acceptance criteria (per task):**
- VO-001: ADR `status: accepted`; all 5 acceptance-criteria boxes checked; 4 open questions answered in the ADR; operator sign-off recorded in run-log; decision-gate outcome (proceed / re-plan) recorded.
- VO-002: manifest covers 100% of the regenerated inventory baseline; every row carries one of the five rubric categories with type-appropriate evidence; no row is "unknown"; all no-evidence deletions carry operator-review sign-off; Appendix A ownership matrix complete and frozen, with AS concurrence noted in run-log.
- VO-003: every `delete` row from VO-002 has a consumer list (possibly empty) produced by the mechanical search protocol, not recall; protocol commands recorded for reproducibility.
- VO-004: written storage policy doc with the three-outcome distinction (working tree / navigation / repo size); git-history decision recorded explicitly either way; non-markdown top-N audit included.
- VO-005: pruned counts reported; every kept skill description states trigger conditions; every pruned item's consumers remediated in the same batch; vault-check green.
- VO-006: zero dead wikilinks to deleted/AS-archived paths in kept docs; superseded-era solutions entries either deleted or justified as canonical-reference/compound-provenance.
- VO-007: diff of each protocol/process doc with ceremony rationale; no phase-gate semantics silently lost; CLAUDE.md edits only post-AS-025 and stop-and-ask.
- VO-008: backup restore-drill passed and procedure logged before first deletion; all deletions executed in batches per the execution model with green checkpoints; deletions enumerated in run-log; tree clean at completion.
- VO-009: soak window defined with explicit end-condition (per teardown discipline #1); representative Tier-1 workflows pass; zero urgent restores from git; no repeated workarounds for removed primitives; operator sign-off closes the project.

## Deliverables / End State

The project is complete when these canonical artifacts exist (this list is the completion contract — smaller is not the goal; a defined center is):
1. **Accepted v3 identity ADR** (`status: accepted`, questions resolved).
2. **Core-functionality operating note** — what Crumb is, what must exist for it to remain itself, what is deliberately no longer part of it, and a **future-addition decision rubric** (does it serve knowledge storage / reasoning substrate directly? core, support, or residue? net maintenance burden vs demonstrated value? can a retained primitive satisfy the need?). This is the canonical entrypoint for future maintenance.
3. **Keep-set manifest** with evidence and dispositions (VO-002), including the joint-surface contract.
4. **Storage policy** (VO-004).
5. **Reduced primitive surface** — pruned skills/agents/overlays/scripts/protocols with trigger-condition descriptions on everything kept.
6. **Functional validation record** (VO-009) demonstrating the pruned vault still performs its Tier-1 workflows.

## Cross-Project Dependencies

- vault-optimization **depends on** agentic-sunset AS-025–032 (CLAUDE.md, directory archival, skills+memory cleanup, closures) for VO-005/VO-007 surfaces. Recorded in `_system/docs/cross-project-deps.md` (XD-027). Entry gates: VO-001–004 are read-only analysis and may proceed during AS M3–M5; VO-005/007 require the Appendix A ownership matrix frozen **and** AS M6 closure sign-off; any ADR conclusions that depend on AS outcomes are reconfirmed after AS milestone closure.
