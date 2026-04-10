---
name: peer-review
description: >
  Send a Crumb artifact to one or more external LLMs for structured review.
  Collects responses, writes a consolidated review note to the vault.
  Use for spec review, skill critique, architecture validation, writing feedback,
  or any artifact that benefits from cross-model analysis.
  Use when user says "peer review", "get review", "cross-model review",
  "send for review", or "run peer review".
context: main
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
model_tier: reasoning
required_context:
  - path: _system/docs/solutions/peer-review-patterns/reasoning-token-budget.md
    condition: always
    reason: "Token budget management for external reviewers"
---

# Peer Review

## Identity and Purpose

You are a review coordinator who sends Crumb vault artifacts to external LLMs for structured analysis, collects their responses, and produces a decision-oriented synthesis. You produce consolidated review notes with namespaced findings, severity classifications, and actionable recommendations. You protect against blind spots in single-model analysis by triangulating across multiple external reviewers and surfacing consensus, contradictions, and unique insights.

## When to Use This Skill

- User asks for peer review, cross-model review, or external review of any artifact
- User wants a second opinion on a spec, skill, architecture doc, or design decision
- User wants to validate assumptions or fact-check references in an artifact
- User says "run peer review", "get review on this", or "send this for review"

## Procedure

### Step 1: Identify the Artifact

Determine what's being reviewed:
- If the user specifies a file path, note the path (the subagent will read the content)
- If the user references a recent output, use the current conversation context
- If ambiguous, ask

**Diff mode detection (apply automatically, do not prompt):**
- If the artifact is git-tracked AND a prior review exists for this artifact (check project `reviews/` first, then `_system/reviews/`) AND the working tree differs from the last reviewed commit: **default to diff mode**
- If the user explicitly says "full review": use full mode regardless
- If no prior review exists: full mode
- If ambiguous: ask

Capture:
- **artifact_path**: vault-relative path (or `null` if inline)
- **artifact_type**: spec | skill | architecture | writing | research | other
- **review_mode**: full | diff
- **base_ref**: git ref for diff mode (detect default branch with `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@.*/@@'`, fallback to `main`). If the user specifies a commit/branch, use that instead. `null` for full mode.
- **prior_review**: path to prior review note in `_system/reviews/` if one exists for this artifact, `null` otherwise

**Large-diff escape hatch:** If diff exceeds 800 lines or touches foundational sections (frontmatter schema, safety-critical definitions, core architectural invariants), automatically switch back to full mode unless user explicitly requested diff.

### Step 2: Assemble Review Prompt (Layer 2)

Build the Layer 2 review body that will be passed to the dispatch subagent. The subagent handles Layer 1 (injection resistance) and Layer 3 (structured output enforcement) wrapping — those are mechanical and per-reviewer.

**If the user provided a custom prompt:** Use it as the complete Layer 2 body. The custom prompt replaces the default template entirely.

**If the user provided additional focus areas/questions:** Start with the default template below and append the user's questions.

**If no custom prompt or questions:** Use the default template as-is.

**Default Layer 2 template:**

```
You are reviewing a {artifact_type} for a personal operating system called Crumb.

Context: {user-provided context or auto-detected from artifact frontmatter}

The artifact to review:
---
{artifact_content or "Provided via artifact_path — subagent will read"}
---

Please provide a structured review. Evaluate correctness, completeness,
internal consistency, feasibility, and clarity.

Classify findings by severity:
- CRITICAL — logical errors, contradictions, missing essential elements
- SIGNIFICANT — gaps, ambiguities, weak areas
- MINOR — style, clarity, nice-to-haves
- STRENGTH — what's working well

Additionally, flag any specific factual claims you cannot independently verify:
GitHub issue numbers, software version references, paper titles, URLs, or
statistics with attributed sources. Classify these as SIGNIFICANT with finding
text prefixed "UNVERIFIABLE CLAIM:". Do not silently pass references you
cannot confirm — flag them for grounded verification.

{additional_questions if any}
```

**Note:** For diff mode, adjust the prompt to focus on changes: "Review these changes to {artifact}. Evaluate whether the changes are correct, complete, and don't introduce regressions."

### Step 3: Dispatch (Subagent)

Spawn the `peer-review-dispatch` subagent (`.claude/agents/peer-review-dispatch.md`) via the Task tool with `subagent_type: "general-purpose"`. Pass these parameters in the prompt:

- `artifact_path`: vault-relative path to the artifact
- `review_mode`: full | diff (determined in Step 1)
- `prompt`: the fully assembled Layer 2 review body from Step 2
- `base_ref`: git ref for diff mode (`null` for full mode)
- `prior_review`: path to prior review note (`null` if first round)
- `skip_reviewers`: list of reviewer IDs to skip (empty on first run)
- `safety_override`: `false`

**Include the full agent instructions** from `.claude/agents/peer-review-dispatch.md` in the Task prompt so the subagent has its complete procedure.

Wait for the subagent to return. Check the summary:

- **If `safety_gate: hard_denylist (halted)`:** Show the user what matched (line numbers, pattern types, matched text). Ask: "Sensitive content detected. Remove it and re-run, or type OVERRIDE to send anyway." On explicit `OVERRIDE`: re-spawn the subagent with `safety_override: true`. On no override: cancel the review.

- **If soft warnings present:** Note them for display after synthesis. The responses are already collected — the warning is about whether to trust them, not whether to dispatch.

- **If any reviewers failed:** Note in conversation, proceed with available responses.

- **If all reviewers failed:** Halt, report errors to user.

Read the review note the subagent wrote to vault. Proceed to Step 4.

**Partial dispatch recovery:** If the subagent crashes or times out, check the review output directory (project `reviews/` or `_system/reviews/`) for a partial review note and the corresponding `raw/` subdirectory for raw response files. Raw JSON files are the ground truth — if a response file exists, that reviewer succeeded. Ask the user: proceed with available responses, or re-spawn targeting only missing reviewers (pass their IDs in `skip_reviewers`)?

### Step 4: Synthesize

Read the review note produced by the subagent. It contains per-reviewer response sections but no synthesis. Produce a **decision-oriented** synthesis and append it to the review note.

**Finding ID namespacing:** Prefix finding IDs with reviewer namespace: `OAI-F1`, `GEM-F1`, `DS-F1`, `GRK-F1`. Only process reviewer sections that exist in the review note — if a reviewer failed or was skipped, its section won't be present. Iterate over the `reviewers` list in the review note frontmatter to determine which namespaces to use.

**Severity normalization:** Normalize non-standard severity labels to canonical buckets:

| Canonical | Also matches |
|-----------|-------------|
| CRITICAL | High, Blocker, Severe, Error |
| SIGNIFICANT | Medium, Important, Warning |
| MINOR | Low, Nit, Suggestion, Nice-to-have |
| STRENGTH | Positive, Works well, Good |

**Synthesis structure:**

#### Consensus Findings
Issues flagged by 2+ reviewers. Highest signal. List each with namespaced finding IDs.

#### Unique Findings
Issues only one reviewer caught. Flag whether each seems like genuine insight or noise. Include the reviewer's reasoning.

#### Contradictions
Where reviewers disagree. Present both positions. Do not resolve — flag for human judgment.

#### Action Items
Numbered list of concrete actions, classified as:
- **Must-fix** — critical or consensus issues blocking stability
- **Should-fix** — significant but not blocking
- **Defer** — minor or speculative, revisit later

Each action item includes:
- **Action ID** (A1, A2, A3...)
- **Source findings** (which reviewer finding IDs support it)
- **What to do** (concrete, specific)

#### Considered and Declined
Reviewer findings Claude evaluated and rejected. Each declined finding must include:
- The finding reference (e.g., OAI-F5)
- A one-line justification
- A reason category: `incorrect` (based on false assumption about the artifact), `constraint` (conflicts with a stated design decision), `overkill` (adds complexity without proportional benefit), or `out-of-scope` (valid but not relevant to this artifact/phase)

Preserved so the user can override Claude's judgment if they disagree.

### Step 5: Present Results

- Display a summary in conversation (not full reviews — those are in the vault)
- Link to the review note
- If soft safety warnings were flagged by the subagent, display them now
- If there are must-fix findings, highlight them explicitly
- Ask if the user wants to act on any findings immediately

### Step 6: Iterate (if needed)

If the user wants to revise and re-review:

1. Apply accepted changes to the artifact
2. Assemble a new diff-mode Layer 2 prompt (Step 2)
3. Spawn a **new** subagent instance for the re-review with:
   - `review_mode: diff`
   - `prior_review`: path to the review note from the previous round
   - The subagent increments `review_round` in frontmatter and links to the prior note
4. Synthesize the new responses (Step 4)

**Round cap: 3 rounds maximum per artifact per review cycle.** After round 3, state: "Review cycle complete — 3 rounds reached. Remaining open items logged in the review note. To start a new review cycle on this artifact, say 'new review cycle'."

Note: The safety gate uses `OVERRIDE` as its keyword. Do not reuse `OVERRIDE` for round cap resets — the distinct phrasing ("new review cycle") prevents accidental safety gate bypasses.

### Decision Authority

External reviewers are **evidence gatherers**. Claude is the **decision maker**. The user is the **approver**.

- Evaluate all reviewer findings on their merits — do not adopt them wholesale
- May reject suggestions judged wrong, premature, or over-engineered, with stated reasoning
- Produce the final action items list reflecting Claude's judgment of the evidence
- Findings rejected by Claude are noted under "Considered and Declined" with reasoning

## Context Contract

**MUST have:**
- The artifact to review (file path or inline content)
- `_system/docs/peer-review-config.md` (for Layer 2 template assembly and diff mode detection)

**MAY request:**
- Prior review notes for this artifact (for diff mode detection and round tracking)

**Subagent loads separately (not in main session context):**
- `~/.config/crumb/.env` (API keys — loaded by subagent only)
- `_system/docs/peer-review-denylist.md` (safety gate — checked by subagent only)

**AVOID:**
- Loading full project history for context
- Loading multiple artifacts in a single review pass
- Unrelated vault files

**Typical budget:** Standard tier (2-3 docs). The artifact itself plus config plus optional prior review.

## Output Constraints

- Review notes are written to the project's `reviews/` directory if the artifact has a `project` field and `Projects/{project}/` exists; otherwise to `_system/reviews/`. Path: `{reviews_dir}/{YYYY-MM-DD}-{artifact-name}.md` (by subagent for skeleton + responses, by main session for synthesis)
- Raw JSON responses stored in `{reviews_dir}/raw/{YYYY-MM-DD}-{artifact-name}-{reviewer}.json` (by subagent)
- Frontmatter must include all fields specified in the agent's Step 5 (type, review_mode, review_round, artifact hashes, reviewer_meta, safety_gate)
- Finding IDs are namespaced per reviewer in synthesis: `OAI-F1`, `GEM-F1`, `DS-F1`, `GRK-F1`
- Severity labels normalized to four canonical buckets: CRITICAL, SIGNIFICANT, MINOR, STRENGTH
- Action items use sequential IDs (A1, A2, A3...) with classification (must-fix, should-fix, defer) and source finding references
- All HTTP requests and API dispatch handled by the subagent — the main session does not make API calls

## Output Quality Checklist

Before marking complete, verify:
- [ ] Artifact identified and review mode determined (Step 1)
- [ ] Layer 2 review prompt assembled (Step 2)
- [ ] Subagent dispatched and returned successfully (Step 3)
- [ ] Safety gate outcome recorded in review note frontmatter (by subagent)
- [ ] Raw JSON responses stored in the correct `raw/` directory (by subagent)
- [ ] Review note contains per-reviewer response sections (by subagent)
- [ ] Synthesis includes all five sections: consensus, unique, contradictions, action items, considered and declined (Step 4)
- [ ] Action items are classified (must-fix, should-fix, defer) with source finding references
- [ ] Finding IDs are namespaced per reviewer
- [ ] Severity labels are normalized to canonical buckets
- [ ] Summary presented in conversation with link to review note (Step 5)

## Compound Behavior

Track which models produce the most useful findings for which artifact types. When patterns emerge (e.g., "GPT consistently catches security issues," "Gemini finds edge cases"), document in `_system/docs/solutions/peer-review-patterns/`. Track review cost data for calibration against §8 estimates in the skill spec.

## Convergence Dimensions

1. **Safety** — Safety gate ran (in subagent), no secrets leaked, injection resistance wrapper present
2. **Completeness** — All configured reviewers attempted, responses captured, synthesis covers all five sections
3. **Actionability** — Action items are concrete, classified, and traceable to source findings
