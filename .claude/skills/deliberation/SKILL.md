---
name: deliberation
description: >
  Run a multi-agent deliberation on a vault artifact. Dispatches to external LLM
  evaluators with role-specific overlays, collects structured assessments, generates
  a deliberation outcome, and writes the complete record to the vault with rating
  capture block for Danny's evaluation.
  Use when user says "deliberate on", "run deliberation", "multi-agent review",
  "panel review", or "evaluate this with the panel".
context: main
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
model_tier: reasoning
required_context:
  - path: _system/docs/solutions/peer-review-patterns/reasoning-token-budget.md
    condition: always
    reason: "Token budget management for external evaluators"
---

# Deliberation

## Identity and Purpose

You are a deliberation coordinator who submits vault artifacts to a panel of external LLM evaluators, each running with a unique role overlay and persona bias. You collect their structured assessments, compute split checks, generate a deliberation outcome summary, and produce a complete deliberation record ready for Danny's blinded rating. You protect against single-model blind spots by routing evaluation through diverse models with diverse analytical lenses.

## When to Use This Skill

- User asks to run a deliberation, panel review, or multi-agent evaluation on an artifact
- User wants multiple perspectives on an opportunity, decision, or architectural choice
- User says "deliberate on", "run deliberation", "evaluate with the panel"
- A project workflow calls for deliberation at a decision point

## Procedure

### Step 1: Identify the Artifact

Determine what's being evaluated:
- If the user specifies a file path, note the path
- If the user references a recent output or artifact, identify it
- If ambiguous, ask

Capture:
- **artifact_path**: vault-relative path
- **artifact_type**: `opportunity-candidate` | `signal-note` | `architectural-decision` (determines verdict scale)
- **batch_id**: if the user is running a batch of related deliberations, assign a shared batch_id; null for standalone
- **depth**: `quick` | `standard` | `deep` (default: `standard`; Phase 1 is Pass-1-only regardless of depth)
- **context**: any additional context the user wants evaluators to consider (null if none)
- **panel**: default from config `default_panel`; user can override to subset

### Step 2: Sensitivity Classification

Read the artifact content. Classify sensitivity using the defaults from `deliberation-config.md` `sensitivity_defaults`:

| Artifact Type | Default | Rationale |
|---------------|---------|-----------|
| opportunity-candidate | internal | Vault-only data, acceptable for API dispatch |
| signal-note | internal | Vault-only data |
| architectural-decision | internal | Vault-only data |
| account-dossier | sensitive | Customer data |
| career-choice | sensitive | Career details, employer conflicts |

Present the classification to Danny:

> **Sensitivity check:** This artifact is classified as **{classification}** ({rationale}).
> Proceed with dispatch? [yes / override to {other level} / cancel]

- **open**: No restrictions — dispatch without concern
- **internal**: Vault-only data acceptable for API dispatch — the default for most artifacts
- **sensitive**: Contains customer data, career details, or strategic information — requires explicit opt-in

Wait for confirmation before proceeding. Danny may override the default classification.

### Step 3: Generate Deliberation ID

Generate a UUID for this deliberation:

```bash
python3 -c "import uuid; print(str(uuid.uuid4())[:8])"
```

This produces a short 8-character ID (e.g., `a3f7c2d1`). Prefix with the batch_id if set: `{batch_id}-{short_uuid}`.

### Step 4: Dispatch (Subagent)

Read the artifact content. Read the deliberation config and assessment schema so you can pass them to the subagent.

Spawn the `deliberation-dispatch` agent via the Agent tool. Pass these parameters in the prompt:

- `artifact_path`: vault-relative path
- `artifact_content`: full text of the artifact
- `artifact_type`: type hint for verdict scale
- `deliberation_id`: generated in Step 3
- `batch_id`: from Step 1 (null if standalone)
- `depth`: from Step 1
- `panel`: evaluator IDs list
- `context`: from Step 1 (null if none)
- `sensitivity_classification`: confirmed in Step 2
- `skip_evaluators`: empty list (first run)
- `safety_override`: false
- `pass_number`: 1 (always 1 for initial dispatch; Pass 2 handled in Step 4b)
- `prior_assessments`: null (always null for Pass 1)

**Include the full agent instructions** from `.claude/agents/deliberation-dispatch.md` in the Agent prompt so the subagent has its complete procedure.

Wait for the subagent to return. Check the summary:

- **If `safety_gate: hard_denylist (halted)`:** Show Danny what matched. Ask: "Sensitive content detected. Remove it and re-run, or type OVERRIDE to send anyway." On OVERRIDE: re-spawn with `safety_override: true`. On no override: cancel.

- **If `min panel check: fail`:** Report which evaluators failed and why. The record is written with `status: incomplete`. Ask Danny whether to retry failed evaluators or accept the partial panel.

- **If soft warnings present:** Note them for display after outcome generation.

- **If any evaluators failed but >=3 succeeded:** Note failures, proceed with available assessments.

### Step 4a: Pass 2 Decision (Split Check)

After Pass 1 dispatch returns, read the deliberation record to check:
1. `split_detected` in frontmatter
2. `experimental_force_pass_2` in deliberation config

**Trigger Pass 2 if ANY of:**
- `split_detected: true` AND `depth` is `standard` or `deep`
- `experimental_force_pass_2: true` (forces Pass 2 regardless of split or depth)

**Skip Pass 2 if:**
- `depth: quick` (unless `experimental_force_pass_2` overrides)
- No split detected AND `experimental_force_pass_2: false`
- Record status is `incomplete` (fewer than 3 evaluators in Pass 1)

If Pass 2 is not triggered, proceed to Step 5.

### Step 4b: Pass 2 Dispatch

Extract structured Pass 1 data from the deliberation record. For each evaluator's Pass 1 assessment, capture ONLY:
- evaluator_id
- verdict
- confidence
- key_finding
- findings array (claim + domain per finding)
- flags

Do NOT include full reasoning text — per spec post-validation principle, only structured fields cross the agent boundary.

Re-spawn the `deliberation-dispatch` agent with updated parameters:
- `pass_number`: 2
- `prior_assessments`: the structured Pass 1 data above
- All other parameters same as Step 4 (artifact, config, schema, etc.)

The dispatch agent will:
1. Assemble Pass 2 prompts (Pass 1 data + dissent_instruction per evaluator)
2. Wrap prior assessments with injection resistance boundary
3. Apply prompt size check (SS8.6) — summarize if >30,000 tokens
4. Dispatch to all evaluators concurrently
5. Write Pass 2 assessments to the deliberation record under "## Pass 2: Dissent"
6. Update frontmatter: `pass_2_triggered: true`, `pass_2_truncated: {true if truncated}`

After Pass 2 dispatch returns:
- If any evaluator returned `dissent_type: null` with empty findings, that's valid (they had nothing to add)
- Note how many evaluators produced material dissent vs. null responses
- Proceed to Step 5

### Step 5: Generate Deliberation Outcome

After the dispatch subagent returns and the record is written, generate the Deliberation Outcome section.

Read the deliberation record from the vault. Extract the structured verdicts and key findings from each evaluator's assessment (NOT full reasoning — just verdict, confidence, key_finding, and findings arrays). If Pass 2 ran, also extract dissent data (dissent_type, dissent_targets, findings per dissenting evaluator).

Generate a 3-sentence summary using a lightweight prompt:

> Given these structured assessments of "{artifact title}":
> {verdict, confidence, key_finding per evaluator}
> {if Pass 2: dissent summary — who dissented, dissent_type, key findings}
>
> Write a 3-sentence deliberation outcome that:
> 1. States the overall pattern (agreement, divergence, or split)
> 2. Identifies the key tension or insight across perspectives
> 3. Notes the most novel or consequential finding (prioritize Pass 2 novel findings if present)
>
> This is a structured summary, NOT a decision or recommendation.

Write the outcome to the Deliberation Outcome section of the record using Edit.

### Step 6: Verify Record Completeness

Read the final deliberation record and verify:

- [ ] All frontmatter fields from SS10 are present (type, deliberation_id, artifact_ref, artifact_type, batch_id, depth, panel, method, split_detected, pass_2_triggered, pass_2_truncated, status, version_tracking, evaluator_meta)
- [ ] Each Pass 1 evaluator section has: verdict, confidence, key_finding, reasoning, findings array, flags
- [ ] Split Check section is populated with verdict values and distance
- [ ] If Pass 2 ran: `pass_2_triggered: true` in frontmatter, Pass 2 sections populated under "## Pass 2: Dissent" with evaluator_id, dissent_targets, dissent_type, findings (or null if no material dissent)
- [ ] If Pass 2 ran: `pass_2_truncated` reflects whether any prompts were truncated
- [ ] Deliberation Outcome section is populated (3 sentences, includes Pass 2 insights if applicable)
- [ ] Rating Capture block is present with empty ratings YAML
- [ ] Per-evaluator cost fields are populated in frontmatter (prompt_tokens, completion_tokens, estimated_cost_usd) — for both Pass 1 and Pass 2 calls if applicable
- [ ] Raw response files exist in the raw/ subdirectory

If any field is missing, fill it from the subagent's return summary or by reading the raw responses.

### Step 7: Present Results

Display a summary in conversation:

```
Deliberation complete: {deliberation_id}
Artifact: {artifact_path} ({artifact_type})
Panel: {N}/{panel_size} evaluators responded

Verdicts: {evaluator_id}: {verdict} ({confidence}) [per evaluator]
Split: {yes/no} (distance: {N})

Outcome: {3-sentence outcome}

Cost: ${total} ({per-evaluator breakdown})
Record: {path to deliberation record}
```

If soft safety warnings were flagged, display them now.

If this is part of a batch, note progress: "Deliberation {N} of {total} in batch {batch_id}."

## Context Contract

**MUST have:**
- The artifact to evaluate (file path)
- `_system/docs/deliberation-config.md` (evaluator registry, model config)
- `_system/schemas/deliberation/assessment-schema.yaml` (for subagent prompt)

**Subagent loads separately (not in main session context):**
- `~/.config/crumb/.env` (API keys)
- Overlay and companion files for each evaluator
- `_system/docs/review-safety-denylist.md` (safety gate)

**AVOID:**
- Loading full project history
- Loading multiple artifacts in a single deliberation
- Loading overlay files in the main session (the subagent handles this)

**Typical budget:** Standard tier (2-3 docs). The artifact plus config plus schema.

## Output Constraints

- Deliberation records written to `Projects/multi-agent-deliberation/data/deliberations/`
- Raw JSON responses stored in `Projects/multi-agent-deliberation/data/deliberations/raw/`
- Record frontmatter must include all SS10 fields
- Rating Capture block must be present with empty ratings YAML (Danny rates after blinding)
- Deliberation Outcome generated by lightweight Opus call, not copied from evaluator output
- All API dispatch handled by the subagent — the main session does not make API calls

## Pass 2 Behavior

- **Split-triggered:** When `split_detected: true` and depth is `standard` or `deep`, Pass 2 runs automatically.
- **Force mode:** When `experimental_force_pass_2: true` in config, Pass 2 runs on ALL deliberations regardless of split detection. Used during H3 testing.
- **Quick depth:** Pass 2 never runs at `quick` depth unless `experimental_force_pass_2` overrides.

## Batch Mode

When the user wants to evaluate multiple artifacts:

1. Assign a shared `batch_id` (e.g., `h4-cold-batch`)
2. Create a **batch manifest** at `data/deliberations/batch-{batch_id}.md` listing:
   - Planned artifact list (paths, types)
   - Expected deliberation count
   - Completion tracking (updated as each deliberation finishes)
3. Run Step 1-7 for each artifact sequentially
4. After all deliberations in the batch complete, note the batch summary:
   - Artifact count, panel composition, total cost
   - Verdict distribution across artifacts
5. When Danny signals "synthesize" (or all batch artifacts are complete), run the Synthesis Procedure below

## Synthesis Procedure (§9)

Synthesis runs when a batch is complete. It identifies cross-artifact patterns that individual deliberations don't surface. Triggered manually — Danny says "synthesize" or "run synthesis."

### Synth Step 1: Verify Batch Completeness

Read the batch manifest. Confirm all planned deliberations have `status: active` (not `incomplete`). If any are missing or incomplete, flag to Danny before proceeding.

### Synth Step 2: Structured Extraction (Mechanical)

For each deliberation record in the batch, extract into a structured dataset:

```yaml
extracted:
  - deliberation_id: string
    artifact_ref: string
    artifact_type: string
    pass_1:
      evaluators:
        - evaluator_id: string
          model: string
          verdict: string
          verdict_numeric: integer
          confidence: number
          key_finding: string (first sentence only)
          findings_count: integer
          finding_domains: [string]  # domain tags from findings array
          flags: [string]
    split_detected: boolean
    split_distance: integer
    pass_2:
      evaluators:
        - evaluator_id: string
          dissent_type: string | null
          verdict: string
          verdict_numeric: integer
          confidence: number
          key_finding: string (first sentence only)
          findings_count: integer
          finding_domains: [string]
          flags: [string]
      verdict_shift_count: integer
      shift_direction: string  # "all down" / "mixed" / "all up" / "none"
    total_cost_usd: number
```

This extraction is mechanical — read each record's frontmatter and assessment sections, map to the schema above. No LLM judgment needed.

### Synth Step 3: Evaluator Diagnostics (Mechanical)

Compute from the extracted dataset:

```yaml
evaluator_diagnostics:
  - evaluator_id: string
    model_used: string
    verdict_distribution:
      # count per verdict value across all artifacts in batch
      reject: integer
      cautionary: integer
      neutral: integer
      promising: integer
      strong: integer
    avg_confidence: number  # mean confidence across all assessments
    dissent_rate: number    # fraction of Pass 2 assessments with non-null dissent
    persistent_themes: [string]  # flags that appear in ≥50% of this evaluator's assessments
    verdict_shift_magnitude: number  # mean absolute P1→P2 verdict change
```

These are deterministic computations — no LLM analysis.

### Synth Step 4: LLM Pattern Detection

Prompt Opus (in the main session — not a subagent) with the extracted dataset and diagnostics. The prompt:

> You are analyzing structured data from {N} multi-agent deliberations on a batch of artifacts.
>
> **Extracted dataset:**
> {structured extraction from Synth Step 2}
>
> **Evaluator diagnostics:**
> {diagnostics from Synth Step 3}
>
> Identify patterns across these deliberations. For each pattern, classify as:
> - **convergence**: Multiple evaluators across different artifacts independently flag the same theme
> - **contradiction**: Evaluators reach opposing conclusions on the same dimension
> - **trend**: Persistent evaluator behavior pattern (e.g., one model consistently rates lower)
> - **emergence**: Connections between artifacts that no single deliberation surfaces
>
> For each pattern found:
> 1. State the pattern clearly
> 2. List the deliberation_ids that provide evidence
> 3. Rate confidence (0.0-1.0)
> 4. Is this actionable? If yes, suggest a specific action
>
> Focus on patterns Danny wouldn't see from reading individual records. Skip obvious observations.
> Output as YAML following the synthesis schema.

### Synth Step 5: Write Synthesis Output

Write the synthesis to `data/deliberations/synthesis-{batch_id}.md` with frontmatter:

```yaml
---
type: synthesis
domain: software
project: multi-agent-deliberation
batch_id: string
artifact_count: integer
deliberation_count: integer
status: active
created: iso8601
updated: iso8601
---
```

Include sections:
1. **Batch Summary** — artifact list, total cost, completion status
2. **Evaluator Diagnostics** — the mechanical computations from Synth Step 3
3. **Patterns** — the LLM-identified patterns from Synth Step 4
4. **Rating Capture** — empty YAML block for Danny to rate each pattern:
   ```yaml
   pattern_ratings:
     - pattern_index: 1
       novelty: 0|1|2        # same rubric as finding ratings
       actionability: 0|1|2  # 0=not actionable, 1=maybe, 2=clear action
       action_taken: null     # filled if Danny acts on it
   ```

### Synth Step 6: Present Synthesis Results

Display:
```
Synthesis complete: batch {batch_id}
Artifacts: {N} deliberations analyzed
Patterns found: {count} ({by type})
Evaluator diagnostics: {brief highlights}

Cost: synthesis was in-session Opus (no additional API cost)
Record: {path}
```

## Convergence Dimensions

1. **Safety** — Sensitivity classification confirmed, safety gate ran, no secrets leaked
2. **Completeness** — All panel evaluators attempted, >=3 responded, record has all SS10 fields
3. **Actionability** — Deliberation outcome captures the key tension, rating capture block ready for Danny
