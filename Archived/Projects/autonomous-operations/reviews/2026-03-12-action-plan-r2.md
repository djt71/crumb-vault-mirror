---
type: review
review_mode: full
review_round: 2
prior_review: Projects/autonomous-operations/reviews/2026-03-12-action-plan.md
artifact: Projects/autonomous-operations/design/action-plan.md
artifact_type: action-plan
companion_artifact: Projects/autonomous-operations/design/tasks.md
project: autonomous-operations
domain: software
skill_origin: peer-review
created: 2026-03-12
updated: 2026-03-12
status: active
reviewers:
  - anthropic/claude-opus-4-6
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - openai/chatgpt
  - perplexity/perplexity
review_method: manual (operator-submitted to each reviewer via web UI)
prompt_focus_areas:
  - Taxonomy mismatch between tasks.md and action plan
  - Domain field availability for AO-004 correlation windows
  - Acted-on rate validity over 14-day evaluation window
  - AO-004 scheduling (separate cron vs fold-in)
  - Spec summary consistency with action plan operational definitions
tags:
  - review
  - peer-review
---

# Peer Review Round 2: Autonomous Operations — Phase 1 Action Plan

**Artifact:** Projects/autonomous-operations/design/action-plan.md + Projects/autonomous-operations/design/tasks.md
**Mode:** Full review with 5 targeted focus areas
**Reviewed:** 2026-03-12
**Reviewers:** Claude Opus 4.6 (synthesizer), Gemini 3 Pro Preview, DeepSeek Reasoner, ChatGPT (GPT-5.2), Perplexity
**Context:** Round 1 (4 automated reviewers) produced 10 action items, all applied to the action plan. Round 2 reviews the post-R1 plan + the companion tasks.md which was not updated after R1.

---

## Claude (Opus 4.6) — Synthesizer + Independent Review

**Verdict:** Action plan is solid. Biggest issue is tasks.md staleness — two different classification schemes, different sidecar field lists, different table names. One medium-severity issue with domain field availability for AO-004. Several low-severity items around evaluation window and operational guardrails.

**Unique findings:**
- Spec summary uses "context metadata" and "false-positive rate <40%" while the action plan defines "context coverage" and "acted-on rate" — terminology gap creates interpretive risk at gate evaluation time.
- Alias table maintenance is manual-only with no discovery mechanism for file renames. `git log --diff-filter=R` could detect renames automatically in a future enhancement. Accepted as known Phase 1 limitation.
- `action_class` taxonomy in plan doesn't map to spec summary's "context metadata" exit criterion — the relationship is implicit but should be explicit.

---

## Gemini (3 Pro Preview)

**Verdict:** Technically sound bash-and-SQLite philosophy. Critical internal contradictions and metadata gaps must be resolved before AO-002 begins.

**Findings:**

- [GEM2-F1] [CRITICAL] Taxonomy mismatch: action plan defines `do|decide|plan|track|review|wait`, tasks.md defines `surface_only|prepare_only`. Action plan's taxonomy is superior for agentic reasoning. Tasks.md is stale.
- [GEM2-F2] [CRITICAL] Missing `domain` field: AO-004 branches on domain for 48h/7d windows, but sidecar schema and items table omit `domain`. Add to both.
- [GEM2-F3] [SIGNIFICANT] 14-day evaluation yields ~50% effective sample for 7d-window items. Suggested extending to 21 days or acknowledging the constraint.
- [GEM2-F4] [SIGNIFICANT] Separate 11 PM LaunchAgent adds operational surface. Suggested folding into daily-attention.sh pre-processing since correlation is low-cost bash.

---

## DeepSeek (Reasoner)

**Verdict:** Well-structured, technically feasible, responsive to prior review. Discrepancies with tasks.md and missing domain field must be resolved.

**Findings:**

- [DS2-F1] [CRITICAL] Taxonomy mismatch: same as GEM2-F1. Action plan is canonical.
- [DS2-F2] [CRITICAL] Missing `domain`: same as GEM2-F2. Suggested deterministic path-based mapping as alternative to explicit field.
- [DS2-F3] [SIGNIFICANT] 14-day window caveat: same as GEM2-F3. Suggested minimum item count expectation (~50 window-closed items) as soft criterion.
- [DS2-F4] [MINOR] `priority_rank` in tasks.md vs `urgency` in action plan — another staleness artifact.
- [DS2-F5] [ASSESSMENT] Separate AO-004 cron is appropriate — conceptually different phase (evening correlation vs morning attention), failure isolation.

---

## ChatGPT (GPT-5.2)

**Verdict:** Conditional go. Plan is directionally solid but tasks.md is stale enough to be unusable as execution artifact. Five must-fix issues identified.

**Findings:**

- [GPT-F1] [CRITICAL] **AO-004 idempotency bug.** `NOT EXISTS` predicate checks `action_source = 'vault_change_correlation'` but successful classifications write `git_commit_correlation` or `mtime_correlation`. On rerun, these items pass the filter and get reprocessed. The plan's claim of idempotency is false. Fix: broaden predicate to `action_source IN (...)` or add uniqueness constraint.
- [GPT-F2] [CRITICAL] Taxonomy mismatch: same as GEM2-F1. Additionally flags `priority_rank`, `source_mtime` in tasks.md that don't exist in the plan.
- [GPT-F3] [CRITICAL] Domain field gap: same as GEM2-F2.
- [GPT-F4] [CRITICAL] 14-day gate needs explicit cohort rule with minimum closed-sample size.
- [GPT-F5] [SIGNIFICANT] `parse_warnings` referenced throughout plan but never declared as table, column, or file. Needs formalization.
- [GPT-F6] [SIGNIFICANT] `operator_actions` (tasks.md) vs `actions` (action plan) table name mismatch.
- [GPT-F7] [SIGNIFICANT] AO-003 prompt "treat it as new with updated context" risks semantic duplication for same-path items. Should say: same object_id, refreshed rationale, `is_recurrence = true`.
- [GPT-F8] [SIGNIFICANT] AO-002 schema validation omits `urgency` from required-key check despite it being in success criteria.
- [GPT-F9] [SHOULD-FIX] Keep `attention-correlate.sh` standalone for manual reruns but invoke from daily-attention.sh. Script-level isolation without scheduler-level isolation.
- [GPT-F10] [SHOULD-FIX] Pull operational guardrails from tasks.md: `PRAGMA user_version`, `<30s` correlation, `<10s` scoring, JSON output for monthly review.

---

## Perplexity

**Verdict:** Good shape overall. Several real contract mismatches need fixing before coding.

**Findings:**

- [PPX-F1] [CRITICAL] Taxonomy mismatch: same as GEM2-F1. Most detailed side-by-side comparison of plan vs tasks.md sidecar schemas.
- [PPX-F2] [CRITICAL] Domain field gap: same as GEM2-F2. Noted that domain exists only in YAML frontmatter of project artifacts, not per-item. Offered two resolution paths (add field vs single 7d window).
- [PPX-F3] [SIGNIFICANT] 14-day window: effective sample is first 7 days. Sufficient for directional Phase 1 gate but should be explicitly acknowledged.
- [PPX-F4] [ASSESSMENT] Keep AO-004 as separate scheduled job — decouples correlation from morning generation, preserves re-run flexibility.
- [PPX-F5] [SIGNIFICANT] Spec summary stale: "false-positive rate <40%" and "context metadata" need updating to match action plan's acted-on rate and context coverage definitions.
- [PPX-F6] [MINOR] DB table naming: `operator_actions` (tasks.md) vs `actions` (plan).
- [PPX-F7] [MINOR] Sidecar schema drift: plan requires 5 keys, tasks.md requires 7 (including `domain`, `priority_rank`, `source_mtime`).

---

## Synthesis

### Consensus Findings

**1. tasks.md is stale and cannot be used as execution artifact** (5/5 reviewers)
Every reviewer flagged the taxonomy mismatch (`surface_only|prepare_only` vs `do|decide|plan|track|review|wait`) and sidecar schema drift. ChatGPT and Perplexity additionally flagged `priority_rank`, `source_mtime`, and `operator_actions` as stale artifacts. The action plan is the canonical spec; tasks.md needs a full resync.

**2. Domain field missing from sidecar schema and items table** (5/5 reviewers)
AO-004 branches on `domain` for correlation windows but the canonical sidecar schema doesn't require it. Universal agreement this is a real gap. Minor disagreement on fix: 3 reviewers lean toward adding the field, 2 offer the alternative of dropping domain-aware windowing for Phase 1.

**3. 14-day evaluation window produces reduced effective sample** (5/5 reviewers)
Items with 7d windows surfaced in the second half of the period won't have closed windows at evaluation time. All agree the denominator should be explicitly documented. Gemini suggests extending to 21 days; others say 14 is fine with proper scoping and printed sample sizes.

**4. Spec summary exit criteria are stale** (5/5 reviewers)
"False-positive rate <40%" and "context metadata" language doesn't match the plan's operational definitions (acted-on rate, context coverage). The plan has evolved legitimately; the summary needs to catch up.

### Unique Findings

**GPT-F1 — AO-004 idempotency bug** (CRITICAL)
The `NOT EXISTS` predicate checks for `vault_change_correlation` but successful correlations write `git_commit_correlation` or `mtime_correlation`. Reruns would reprocess already-classified items. **This is a real logic bug that no other reviewer caught.** Highest-impact unique finding in the round.

**GPT-F5 — `parse_warnings` never formalized** (SIGNIFICANT)
Referenced in taxonomy fallback, dedup merge events, and schema validation but never declared as a storage location. Needs to be a column on `cycles` (JSON array) or a dedicated table.

**GPT-F7 — AO-003 "treat as new" risks semantic duplication** (SIGNIFICANT)
The prompt instruction for changed items says "treat it as new with updated context" but identity is path-based — same path = same object. The instruction should say: same object_id, refreshed rationale, `is_recurrence = true`.

**GPT-F10 — Operational guardrails from tasks.md worth preserving** (MINOR)
`PRAGMA user_version`, runtime thresholds (`<30s`, `<10s`), and JSON output format are useful constraints that the action plan doesn't capture but tasks.md does. Pull them into the plan rather than losing them in the resync.

**DS2-F2 — Deterministic path-based domain mapping** (alternative approach)
Suggested `Projects/software/*` → `software` as a fallback if model compliance on `domain` field is unreliable. Fragile (couples to directory structure, breaks for synthetic IDs) but worth noting as a Plan B.

### Contradictions

**AO-004 scheduling: fold in vs separate job**
- Claude, Gemini, ChatGPT (3/5): Fold into daily-attention.sh as pre-processing step. Keep standalone script for manual reruns.
- DeepSeek, Perplexity (2/5): Keep as separate scheduled job for failure isolation and timing flexibility.

Resolution: **Fold in.** ChatGPT's formulation resolves the contradiction — script-level isolation (standalone `attention-correlate.sh`) without scheduler-level isolation (no separate LaunchAgent). The standalone script preserves re-run capability that DeepSeek and Perplexity wanted.

**Domain field: add explicitly vs drop branching**
- Gemini, DeepSeek, Claude: Add `domain` to schema.
- Perplexity: Offered both paths, leaned toward dropping branching for simplicity.
- ChatGPT: Flagged the gap, no strong preference.

Resolution: **Add `domain` to schema (operator decision).** Low implementation cost (model already has domain context from input sources), and 48h windows on software/career items provide faster feedback signal — which is the whole point of Phase 1 instrumentation.

### Action Items

**B1 (must-fix)** — Fix AO-004 idempotency bug
Source: GPT-F1
Change `NOT EXISTS` predicate to `action_source IN ('git_commit_correlation', 'mtime_correlation', 'vault_change_correlation')`. Add UNIQUE(`item_id`, `action_source`) constraint on `actions` table as DB-level safety net.

**B2 (must-fix)** — Add `domain` to canonical schema
Sources: GEM2-F2, DS2-F2, GPT-F3, PPX-F2, Claude
Add `domain` to: sidecar JSON required fields, items table, schema validation, prompt instruction. Define 8 canonical values + fallback (`software` if unrecognized). Update context coverage metric to include `domain` validation.

**B3 (must-fix)** — Formalize `parse_warnings`
Source: GPT-F5
Add `parse_warnings TEXT` column to `cycles` table. JSON array of warning strings. All references to "log to parse_warnings" (taxonomy fallback, dedup merge, schema validation) point to this column.

**B4 (must-fix)** — Resync tasks.md to action plan
Sources: All 5 reviewers
Replace `surface_only|prepare_only` with `do|decide|plan|track|review|wait`. Replace `priority_rank` with `urgency`, `operator_actions` with `actions`. Align sidecar required keys with action plan. Add `domain` to AO-002 acceptance criteria.

**B5 (should-fix)** — Add evaluation window caveat to M4
Sources: All 5 reviewers
Document that acted-on rate is computed over window-closed items only. Print `N_window_closed` in score output. Acknowledge effective sample size (~7-10 days of items in a 14-day period).

**B6 (should-fix)** — Fold AO-004 into daily-attention.sh
Sources: Claude, Gemini, ChatGPT (3/5)
Invoke `attention-correlate.sh` as pre-processing step from daily-attention.sh (before context gathering). Keep standalone script for manual reruns and backfills. Remove "11 PM LaunchAgent" from plan.

**B7 (should-fix)** — Update spec summary exit criteria
Sources: All 5 reviewers
Replace "false-positive rate <40%" with acted-on rate (directional proxy, not strict threshold). Replace "context metadata" with context coverage (non-null `source_path` + valid `action_class` + valid `domain`). Add evaluation window caveat.

**B8 (should-fix)** — Pull operational guardrails into action plan
Source: GPT-F10
Add to plan: `PRAGMA user_version = 1` for schema versioning, `<30s` correlation runtime threshold, `<10s` scoring runtime threshold, JSON output format for scoring with raw counts alongside rates.

**B9 (should-fix)** — Fix AO-003 prompt instruction
Source: GPT-F7
Rewrite: same `object_id`, refreshed rationale, `is_recurrence = true` for changed items at the same path. Remove "treat it as new with updated context" which risks semantic duplication.

**B10 (should-fix)** — Add `urgency` and `domain` to schema validation
Sources: GPT-F8, B2
Required-key check in post-processing should validate: `object_id`, `source_path`, `title`, `domain`, `action_class`, `urgency`. Currently omits `urgency` despite it appearing in success criteria.

### Considered and Declined

**Gemini: Extend evaluation period to 21 days** — `unnecessary`
14 days with proper window-closure scoping and printed sample sizes is sufficient for a directional Phase 1 gate. The gate is "are the pipes working?" not "do we have statistical power?" Extending adds calendar time without proportional signal improvement.

**DeepSeek: Deterministic path-based domain mapping** — `fragile`
Coupling domain assignment to vault directory structure breaks for synthetic IDs, cross-domain items, and any future restructuring. Having the model include `domain` in the sidecar is simpler and more robust. Noted as Plan B if model compliance is unreliable.

**Perplexity: Separate AO-004 LaunchAgent** — `superseded`
ChatGPT's standalone-script-invoked-from-cron formulation provides the re-run capability without the operational surface. Both dissenting reviewers' concerns are addressed by script-level isolation.

**DeepSeek: Minimum item count threshold for gate** — `deferred`
Suggested requiring ≥50 window-closed items before the gate can pass. This is a useful guardrail but hard to enforce (depends on daily item volume which varies). The printed `N_window_closed` in score output lets the operator make this judgment call at evaluation time. May formalize in Phase 2 if the first gate reveals sample size concerns.
