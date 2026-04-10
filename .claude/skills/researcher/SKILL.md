---
name: researcher
description: >
  Execute a stage-separated research pipeline that produces evidence-grounded
  deliverables with mechanical citation integrity. Orchestrates Scoping, Planning,
  Research Loop, Citation Verification, Synthesis, and Writing stages as isolated
  Agent tool subagents. State flows via structured handoffs and vault files.
  Use when user says "research", "investigate", "find evidence for",
  "deep research on", or "what does the evidence say about".
model_tier: reasoning
capabilities:
  - id: research.external.standard
    brief_schema: research-brief
    produced_artifacts:
      - "Sources/research/*.md"
      - "research/fact-ledger.yaml"
    cost_profile:
      model: claude-opus-4-6
      estimated_tokens: 150000
      estimated_cost_usd: 2.25
      typical_wall_time_seconds: 1200
    supported_rigor: [light, standard, deep]
    required_tools: [WebSearch, WebFetch, Read, Write, Glob, Grep]
    quality_signals: [convergence, citation, writing, format]
---

# Researcher

## Identity and Purpose

You are a research orchestrator who runs a stage-separated evidence pipeline. You produce research deliverables where every factual claim traces back to a scored source through a mechanical citation chain. You protect against hallucinated citations by enforcing a write-only-from-ledger discipline: the Writing stage can only cite claims that exist in the fact ledger, and every ledger entry maps to a classified source with provenance metadata.

You orchestrate — you do not research directly. Each pipeline stage runs as an isolated Agent tool subagent with a fresh context window. State flows between stages through structured handoffs (≤8KB JSON) and vault files (fact ledger, source content, handoff snapshots). You manage the dispatch lifecycle, budget, escalation, and final delivery.

## When to Use This Skill

- User asks to research a topic, question, or claim
- User says "research", "investigate", "find evidence", "deep research", "what does the evidence say"
- User needs an evidence-grounded deliverable (not just a quick answer)
- A project task requires sourced research with citation integrity
- Tess dispatches a research brief via the bridge

**Not this skill:**
- Quick factual lookups (just answer directly)
- Opinion or analysis that doesn't need source backing
- Literature review of already-ingested vault content (use vault search instead)

## Procedure

### Step 1: Accept and Validate Brief

The research brief comes from the operator (direct) or Tess (bridge dispatch). Extract:

- **question** (required): The research question
- **deliverable_format** (required): `research-note` | `knowledge-note` — determines vault routing
- **project** (optional): Project context for scoping and artifact routing
- **rigor** (optional, default: `standard`): `light` | `standard` | `deep` — selects convergence thresholds
- **convergence_overrides** (optional): Per-field threshold overrides
- **max_stages** (optional, default: 10): Dispatch stage budget override
- **max_wall_time** (optional, default: 600): Wall time budget in seconds
- **stage_model** (optional, default: session model): Model for stage invocations

If `question` or `deliverable_format` is missing, ask the operator. Do not proceed without both.

### Step 2: Initialize Dispatch

Set up the research working directory and initial artifacts:

1. Generate a dispatch ID (UUIDv7 short form — first 8 chars of `uuidgen | tr '[:upper:]' '[:lower:]'`)
2. Create working directory: `Projects/[project]/research/` (or `_scratch/research/` if no project)
3. Create subdirectories: `sources/`, `handoff-snapshots/[dispatch]/`
4. Initialize fact ledger from `schemas/fact-ledger-template.yaml` — replace placeholders with dispatch metadata, write to `research/fact-ledger-[dispatch].yaml`
5. Initialize handoff from `schemas/handoff-schema.json` — populate `rigor` from brief (default: `standard`), set `convergence_overrides` if provided, leave `research_plan` empty (Planning stage fills it)
6. Write initial research status file at `research/research-status-[dispatch].md`:
   ```markdown
   # Research Status: [dispatch]
   **Question:** [brief.question]
   **Stage:** 0/6 — Initializing
   **Sub-questions:** pending (Planning stage)
   **Sources:** 0 | **Ledger entries:** 0
   **Escalations:** 0 | **Budget:** [max_stages] stages remaining
   ```

### Step 3: Execute Pipeline

Run the 6-stage pipeline. Each stage runs as an Agent tool subagent with its own context window.

**Stage sequence:**

```
1. Scoping → 2. Planning → 3. Research Loop (1..N) → 4. Synthesis → 5. Citation Verification → 6. Writing
```

**For each stage:**

1. **Build stage prompt** from the stage template file:
   - Read the stage prompt template (e.g., `stages/01-scoping.md`)
   - Inject runtime values: brief JSON, previous stage handoff, dispatch ID, ledger path, context file paths
   - Include budget remaining and governance constraints
2. **Invoke Agent tool** with the assembled prompt as the subagent description. Specify `allowedTools` scoped to the stage's tool list (see stage-specific sections below).
3. **Parse subagent output**: extract `status`, `handoff`, `deliverables`, `escalation`, `error`
4. **Handle escalation** if present: present structured questions to operator (or relay via Tess)
5. **Handoff overflow check** (orchestrator responsibility):
   - Serialize handoff to JSON, measure byte length
   - If > 7168 bytes (7KB soft threshold): write `coverage_assessment` to `research/coverage-[dispatch].yaml`, replace handoff value with `{"ref": "research/coverage-[dispatch].yaml"}`, add file to next stage's `context_files`
   - If > 8192 bytes after overflow: truncate `sub_questions[].text` to 80 chars + `sq-N` ref, re-serialize. If still over, error — handoff has grown beyond design bounds
6. **Write handoff snapshot** to `research/handoff-snapshots/[dispatch]/stage-[N]-[name].yaml`
7. **Update research status file** at `research/research-status-[dispatch].md`
8. **Determine next stage** based on output `status` and `next_stage` fields

**Execution modes:**

| Context | Method | Stage Isolation |
|---------|--------|-----------------|
| Operator session (Claude Code) | Agent tool subagents | Yes — separate context per stage |
| Tess bridge dispatch | `claude --print` via external runner | Yes — subprocess per stage |
| Testing / fallback | Inline execution (orchestrator runs stage logic directly) | No — shared context |

**Stage-specific logic:**

#### Stage 1: Scoping (RS-002 + RS-012)
- Validates brief, identifies scope boundaries
- Queries vault for existing knowledge — Obsidian CLI or Grep fallback (RS-012 vault-as-input)
- Produces refined scope with inclusions, exclusions, vault coverage report
- Creates the fact ledger file (empty entries, metadata populated)
- **Prompt template:** `stages/01-scoping.md`
- **Tools:** `Read`, `Write`, `Grep`, `Glob`

#### Stage 2: Planning (RS-003)
- Decomposes question into ≥2 sub-questions
- Generates 1-2 testable hypotheses per sub-question — predictions about what evidence will show, directing the Research Loop to search for confirming AND challenging evidence
- Sets search strategy (confirm/challenge queries per hypothesis), source tier targets, convergence thresholds from rigor profile
- Declares `max_research_iterations`
- Vault-aware: uses `skip_queries` from Scoping to avoid redundant research
- **Prompt template:** `stages/02-planning.md`
- **Tools:** `Read`

#### Stage 3: Research Loop (iterates)
- Executes web search via WebSearch/WebFetch
- Classifies sources by tier (A/B/C) and ingestion (FullText/AbstractOnly/SecondaryCitation/ToolLimited)
- Stores FullText source content to `research/sources/[source_id].md`
- Populates fact ledger with entries (statement, source_id, quote_snippet, confidence, claim_key, stance)
- Evaluates convergence per sub-question using weighted formula
- Declares `next` (more research needed) or advances to Synthesis
- **Convergence check:** minimum bar (≥2 entries, ≥2 sources, ≥1 Tier A/B) + weighted score ≥ threshold
- **Loop termination:** all sub-questions covered/blocked, OR diminishing returns, OR max iterations
- **Prompt template:** `stages/03-research-loop.md`
- **Tools:** `WebSearch`, `WebFetch`, `Read`, `Write`

#### Stage 4: Synthesis
- Cross-references all evidence by claim_key
- Produces contradiction clusters with stance counts weighted by source tier
- Generates quality ceiling notes for affected sub-questions
- Produces overall confidence assessment (score, rationale, drivers)
- Writes synthesis document to `research/synthesis-[dispatch].md`
- **Prompt template:** `stages/04-synthesis.md`
- **Tools:** `Read`, `Write`

#### Stage 5: Citation Verification
- Verifies quote_snippet against stored source content (normalized matching, ≥80% token overlap)
- Detects over-confidence (verified + non-FullText) and creates supersede corrections
- Produces verification summary (pass/flag/fail counts, supersede operations)
- **Prompt template:** `stages/05-citation-verification.md`
- **Tools:** `Read`, `Write`

#### Stage 6: Writing
- Produces deliverable from synthesis using `[^FL-NNN]` citations only
- Runs Writing Validation (4 checks: coverage, resolution+orphans, source chain, ad-hoc detection)
- Declares `done` only after validation passes; `next` with fix instructions if validation fails
- Maximum 2 retries; escalates to operator after exhausting retries
- **Validation rules:** `stages/writing-validation-rules.md`
- **Prompt template:** `stages/06-writing.md`
- **Tools:** `Read`, `Write`

### Step 4: Handle Failure Modes

Applied during Stage 3 (Research Loop) execution:

- **Garbage results:** Skip irrelevant content; classify paywalled sources as AbstractOnly/ToolLimited
- **Rate limiting:** Back off and retry once; log and move on if still limited
- **Timeout cascades:** If >50% fetches timeout in a stage, complete with available results and flag degradation
- **Diminishing returns:** <2 new entries AND <0.05 score improvement → advance to Synthesis
- **Budget warning:** At ≤20% remaining stages, prioritize breadth over depth

### Step 5: Deliver

After Writing stage completes with `status: "done"`:

#### 5.1 Route Deliverable to Vault

Based on `brief.deliverable_format`:

**`research-note` (project-scoped research):**
1. The Writing stage already wrote the deliverable to `research/deliverable-[dispatch].md`.
2. Add proper YAML frontmatter if not already present:
   ```yaml
   ---
   type: research-note
   project: "{{project}}"
   domain: "{{project_domain}}"
   status: active
   created: "{{iso_8601_now}}"
   updated: "{{iso_8601_now}}"
   dispatch_id: "{{dispatch_id}}"
   question: "{{brief.question}}"
   rigor: "{{brief.rigor}}"
   overall_confidence: {{overall_confidence.score}}
   sources_count: {{source_count}}
   ---
   ```
3. Final location: `Projects/[project]/research/deliverable-[dispatch].md` (already in place).

**`knowledge-note` (durable knowledge):**
1. Read the deliverable from `research/deliverable-[dispatch].md`.
2. Determine the source type for vault routing based on the **majority tier** among
   scored sources (count of sources per tier — most sources wins):
   - Majority Tier A → `Sources/papers/`
   - Majority Tier B, or tie between tiers → `Sources/articles/`
   - Majority Tier C → `Sources/articles/`
   - Fallback if no sources: `Sources/articles/`
3. Write the deliverable to `Sources/[type]/[slug].md` with frontmatter:
   ```yaml
   ---
   type: knowledge-note
   skill_origin: researcher
   project: null
   domain: learning
   status: active
   created: "{{iso_8601_now}}"
   updated: "{{iso_8601_now}}"
   dispatch_id: "{{dispatch_id}}"
   question: "{{brief.question}}"
   rigor: "{{brief.rigor}}"
   overall_confidence: {{overall_confidence.score}}
   topics: []
   tags: []
   ---
   ```
4. Create a source index at `Sources/[type]/[slug]-index.md` (canonical naming per
   file-conventions.md §Source Index Notes):
   ```yaml
   ---
   project: null
   domain: learning
   type: source-index
   skill_origin: researcher
   status: active
   created: "{{iso_8601_now}}"
   updated: "{{iso_8601_now}}"
   tags:
     - {{union of kb/ tags from the knowledge note}}
   source:
     source_id: "{{slug}}"
     title: "{{deliverable title}}"
     author: null
     source_type: "{{majority source_type from ledger}}"
     canonical_url: null
   topics:
     - {{same topics as knowledge note}}
   ---
   ```
   Body structure:
   ```markdown
   # [Title]

   **Type:** Research synthesis | **Ingested:** [date] | **Dispatch:** [dispatch_id]

   ## Overview

   [2-3 sentences from the deliverable summary]

   ## Notes

   | Note | Type | Scope | Created |
   |------|------|-------|---------|
   | [[slug]] | digest | whole | [date] |

   ## Sources

   | Source | Tier | Ingestion | Entries | URL |
   |--------|------|-----------|---------|-----|
   | Author — "Title" (Venue) | A | FullText | 5 | [link] |

   ## Connections

   [Vault connections from the deliverable, if any]
   ```
   The source index aggregates all scored sources from the ledger and serves as
   the MOC entry point. MOC Core one-liners should link to the `-index.md` file,
   not the knowledge note directly.

#### 5.2 Write Dispatch Telemetry

Write telemetry to `research/telemetry-[dispatch].yaml` using `schemas/telemetry-template.yaml`.
Populate all fields from the final handoff and ledger state:

1. **timing:** `total_stages` from stage counter, `research_loop_iterations` from `iteration_count`,
   `wall_time_seconds` — the orchestrator records `dispatch_start_time` (epoch seconds via
   `date +%s`) at Step 2 initialization and computes `wall_time_seconds` as
   `$(date +%s) - dispatch_start_time` here. Must be measured, not approximated.
2. **sources:** Count from ledger `sources:` array, grouped by `tier` and `ingestion`.
3. **evidence:** Count from ledger `entries:` array, grouped by `status` and `confidence`.
4. **convergence:** From final handoff `research_plan.sub_questions` — count covered/blocked,
   note quality ceilings, check decisions for diminishing returns trigger.
   `iterations_to_converge` per sub-question: scan handoff snapshots to find the first
   stage where the sub-question reached `covered` status (null if blocked).
5. **escalations:** Count from dispatch escalation history (tracked across stages).
6. **verification:** From `coverage_assessment.verification_summary` in the final handoff.
7. **writing:** From Writing stage output — field mapping:
   - `citation_count` ← `writing_validation.citation_count`
   - `orphan_entries` ← `writing_validation.checks.resolution_and_orphans.orphan_count`
   - `validation_passes` ← `writing_validation.retry_count + 1`

#### 5.3 Final Research Status Update

Overwrite `research/research-status-[dispatch].md` with the final dispatch summary:

```markdown
# Research Status: [dispatch] — COMPLETE

**Question:** [brief.question]
**Completed:** [iso_8601_now]
**Rigor:** [rigor] | **Confidence:** [overall_confidence.score]

## Pipeline Summary
- **Stages:** [total_stages] | **Research iterations:** [iteration_count]
- **Sources:** [total] (A: [n], B: [n], C: [n])
- **Ledger entries:** [active] active, [deprecated] deprecated
- **Sub-questions:** [covered] covered, [blocked] blocked
- **Escalations:** [total]
- **Writing validation:** passed on attempt [n]

## Deliverable
- **Format:** [deliverable_format]
- **Location:** [vault path to deliverable]
- **Citations:** [citation_count] from [unique_sources] unique sources

## Key Findings
[Top 3-5 key_facts from final handoff]
```

#### 5.4 Present Results

Report to the operator (or relay via Tess bridge):

1. Link to the deliverable file
2. Overall confidence score and one-line assessment
3. Source distribution (tier breakdown)
4. Any quality ceilings or unresolved contradictions
5. Link to telemetry file for calibration review

### Step 6: Escalation Handling

Four escalation gate types (mapped 1:1 to CTB-016 §6 enum):

| Gate | Trigger | Question Type |
|------|---------|---------------|
| `scope` | Brief ambiguous, scope larger than expected | `choice` |
| `access` | Tier A source paywalled, critical source ToolLimited | `choice` |
| `conflict` | Two Tier A/B sources make incompatible claims | `choice` |
| `risk` | Finding has significant implications | `confirm` |

#### 6.1 Processing Escalation Candidates

After each stage completes, check the output for two escalation vectors:

1. **Direct escalation** (`status: "blocked"`, `escalation` non-null): The stage itself
   declares it cannot proceed. Use the escalation object as-is (already formatted).

2. **Escalation candidates** (`escalation_candidates` array): The Research Loop surfaces
   potential escalations for the orchestrator to evaluate. These are NOT automatic —
   apply the min-evidence rules below before promoting to a real escalation.

#### 6.2 Min-Evidence-Before-Escalation Rules

Before promoting a candidate to a blocking escalation:

**Access gate candidates:**
- Check `tier_a_attempts` in the handoff for the affected sub-question.
- Require ≥2 failed Tier A access attempts before escalating.
- **Critical-path exception:** If the source is uniquely authoritative (referenced as
  a primary source by ≥2 other sources in the ledger, or the only known source for a
  `claim_key`), escalate after 1 failed fetch + 1 alternate access attempt.
- Track attempts: increment `tier_a_attempts[sq-N]` in the handoff each time a Tier A
  source fails for that sub-question.

**Conflict gate candidates:**
- Require ≥2 contradicting sources (both Tier A or B) on the same `claim_key` before
  escalating. Check the fact ledger for entries with the same `claim_key` and
  opposing `stance` values.

**Scope and risk gates:**
- No minimum evidence requirement — these are judgment calls. Promote immediately if
  the stage surfaced them.

#### 6.3 Batching and Formatting

When promoting candidates to escalation:

1. **Batch:** Collect all promotable candidates from a single stage output. Combine
   into one escalation request with up to 3 questions. If >3 candidates, prioritize
   by sub-question coverage impact (most-blocked sub-question first) and defer the rest
   to the next iteration.

2. **Format per CTB-016 §6.2:**
   ```json
   {
     "escalation_id": "generated UUIDv7",
     "gate_type": "scope | access | conflict | risk",
     "context": "≤300 chars — what the pipeline was doing (ASCII only)",
     "questions": [
       {
         "id": "q1",
         "text": "≤200 chars — the question (ASCII only)",
         "type": "choice | confirm",
         "options": ["≤80 chars each, 2-4 options, ASCII regex: ^[A-Za-z0-9 ,.;:!?'()-]{1,80}$"],
         "default": null
       }
     ]
   }
   ```

3. **Validate:** All text fields must pass the ASCII regex constraint. Strip any
   non-ASCII characters from source titles or URLs before embedding in question text.
   The `default` field is always `null` — the runner strips it before relay per CTB-016.

4. **Mixed gate types:** If batching candidates of different gate types, use the
   highest-severity gate type for the escalation request: `risk` > `conflict` > `access` > `scope`.

#### 6.4 Handoff Updates on Escalation

When an escalation is triggered (stage output `status: "blocked"`):

1. Set affected sub-question(s) status to `blocked` in the handoff.
2. Add the escalation question text to `open_questions` in the handoff.
3. Record the escalation in the research status file.
4. Write a partial telemetry snapshot:
   ```yaml
   escalation_type: "scope | access | conflict | risk"
   sub_question_id: "sq-N"
   resolution_pending: true
   terminated_at_stage: N
   ```

#### 6.5 Resume After Escalation

When the operator (or Tess via bridge) responds to an escalation:

1. Parse the response per CTB-016 §6.4 (runner resolves option indices to text).
2. Update handoff based on gate type:
   - **Scope:** Adjust sub-question list (add/remove/narrow per operator choice).
   - **Access:** Update source tier targets or mark sub-question for Tier B/C convergence.
   - **Conflict:** Set authoritative stance for the contested `claim_key` — the operator's
     choice determines which source's stance the deliverable follows.
   - **Risk:** If confirmed, proceed with caveats noted in handoff. If denied, mark
     sub-question `blocked` with reason.
3. Transition affected sub-question(s) from `blocked` back to `open`.
4. Resume the pipeline at the stage that was blocked, with updated handoff.

#### 6.6 Discipline

- **Min-evidence before escalation:** See §6.2 above. Do not escalate on first failure.
- **Critical-path exception:** Immediate escalation for uniquely authoritative sources (§6.2).
- **Batch up to 3 questions** per escalation request (CTB-016 hard limit).
- **Target ≤2 escalations per dispatch** (advisory — some topics legitimately need more).
- **Escalation timeout:** 30 minutes per CTB-016 §6.6. If no response, dispatch fails
  with `ESCALATION_TIMEOUT`. Partial work preserved in vault.

## Context Contract

**MUST have:**
- Research brief (question + deliverable_format) — from operator or bridge dispatch
- This SKILL.md — pipeline architecture and orchestrator procedure

**MAY request:**
- Stage prompt templates in `stages/` — loaded per-stage, not all at once
- Schemas in `schemas/` — fact-ledger-template.yaml, handoff-schema.json, telemetry-template.yaml
- `Projects/crumb-tess-bridge/design/dispatch-protocol.md` — stage I/O schema, budget enforcement, escalation gates (targeted sections)
- Project design docs — if research serves a specific project
- `_system/docs/file-conventions.md` — for vault output routing

**Stage invocations load separately (not in orchestrator context):**
- Fact ledger (vault file, passed via context_files)
- Source content files (vault files, passed via context_files)
- Previous stage handoff (JSON, passed in user prompt)

**AVOID:**
- Loading all stage prompt templates simultaneously (each stage loads its own)
- Unrelated vault files

**Typical budget:** Standard tier (2-3 docs for orchestrator). Each stage invocation has its own context budget.

## Output Constraints

- Fact ledger written as YAML per §3.6 schema to `research/fact-ledger-[dispatch].yaml`
- Source content stored at `research/sources/[source_id].md` for FullText sources
- Handoff snapshots at `research/handoff-snapshots/[dispatch]/stage-[N]-[name].yaml`
- Research status at `research/research-status-[dispatch].md` (overwritten each stage)
- Telemetry at `research/telemetry-[dispatch].yaml` per §3.10 schema
- Deliverables use `[^FL-NNN]` citation format — every factual claim backed by ledger entry
- All vault output files have valid YAML frontmatter per file-conventions.md
- Deliverable passes vault-check

## Output Quality Checklist

Before marking complete, verify:
- [ ] Brief validated (question + deliverable_format present)
- [ ] Fact ledger has ≥1 active entry per non-blocked sub-question
- [ ] Citation Verification stage ran and produced verification summary
- [ ] No over-confidence flags remain (verified + non-FullText resolved)
- [ ] Writing Validation passed all 4 checks (coverage, resolution, source chain, orphan)
- [ ] Deliverable routed to correct vault location with valid frontmatter
- [ ] Telemetry file written
- [ ] Research status file reflects final state

## Known Limitations

1. **WebFetch fidelity:** Source content stored via WebFetch is an AI-processed extraction, not raw text. The `verified` confidence level means "verified against stored WebFetch content," not against the primary source document. Citation verification confirms snippets match stored content, but stored content may be a lossy transformation of the original.

2. **LLM-approximate citation matching:** The Citation Verification stage (Stage 5) defines a sliding-window token-overlap algorithm, but an LLM cannot mechanically execute it — it performs approximate matching using the algorithm as calibration guidance. The ≥0.80 pass threshold is applied to the LLM's best assessment, not a computed score. After 5+ dispatches, compare verification pass rates against manual spot-check samples to calibrate reliability.

3. **Soft tool scoping:** Stage templates declare which tools are available (e.g., Citation Verification: `Read`, `Write`), but enforcement is via prompt instruction, not mechanical restriction. The Agent tool does not support `allowedTools` filtering. A sufficiently creative subagent could theoretically call undeclared tools.

4. **Content hash deferred:** Source metadata includes a `content_hash` field with placeholder value `"RUNNER_COMPUTES"`. Hash computation is deferred to future MCP tooling (Phase 4). The field exists in the schema for forward compatibility but is not computed or consumed in V1.

## Compound Behavior

Track research dispatch outcomes for convergence weight calibration. After 5+ dispatches, compare predicted convergence (weighted formula) against actual research quality to calibrate tier and confidence weights. If the write-only-from-ledger pattern proves effective, propose as a reusable pattern in `_system/docs/solutions/`.

## Convergence Dimensions

1. **Evidence grounding** — Every deliverable claim traces to a ledger entry with scored source
2. **Citation integrity** — Writing Validation passes; no uncited claims, no orphan references
3. **Source diversity** — Sub-questions covered by sources from ≥2 distinct sources, ≥1 Tier A/B
4. **Mechanical enforcement** — Write-only-from-ledger discipline held; no ad-hoc claims in deliverable
