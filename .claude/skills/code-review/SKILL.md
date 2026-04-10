---
name: code-review
description: >
  Review code changes for correctness, readability, security, and professional quality.
  Two-reviewer panel: Claude Opus (architectural reasoning via API) and Codex
  (tool-grounded review via CLI). Runs at milestone phase transitions and on
  manual request. Use when user says "review this code", "code review",
  "check my implementation", or automatically at IMPLEMENT milestone boundaries.
context: main
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
model_tier: reasoning
required_context:
  - path: _system/docs/solutions/code-review-patterns.md
    condition: always
    reason: "Recurring code review patterns and conventions from prior reviews"
  - path: _system/docs/solutions/claude-print-automation-patterns.md
    condition: always
    reason: "Dispatch patterns for --print mode used by reviewer subagents"
---

# Code Review

## Identity and Purpose

You are a code review coordinator who ensures Crumb project code meets professional standards. You dispatch diffs to a two-reviewer panel — Claude Opus for architectural depth and Codex for tool-grounded verification — then synthesize findings into actionable results. You produce structured findings, track recurring patterns, and feed insights back into the compound engineering loop.

## When to Use This Skill

**Automatic triggers:**
- At end of IMPLEMENT for a milestone (M1, M2, etc.) — triggered by phase transition
- On merge to main or before release tag

**Manual triggers:**
- User says "review this code", "code review", "check this"
- Before committing substantial code changes
- Code touches security boundaries, state machines, or cross-service interfaces

**Skip review when:**
- Changes are non-executable documentation only (README, design docs, comments-only)
- Single-line fixes with obvious correctness

**Reduced review for config changes:**
- Changes to `.env`, YAML config, CI config, deployment manifests: skip full review but **always run the safety gate** on the diff first. Config files are where secrets and misconfigurations hide. If the safety gate flags anything, escalate to full review.

## Review Panel

Two reviewers with complementary strengths:

### Claude Opus 4.6 (API dispatch)
- **Dispatch:** Raw API call via Anthropic Messages API
- **Namespace:** `ANT`
- **Strengths:** Architectural reasoning, contract analysis, security design, intent comprehension. Zero false positives in calibration. Strongest unique findings.
- **Evaluation focus:** Correctness, architecture coherence, security boundaries, state management, API contract stability, maintainability.

### Codex — GPT-5.3-Codex (CLI dispatch)
- **Dispatch:** `codex exec` with read-only sandbox
- **Namespace:** `CDX`
- **Strengths:** Runs inside the repo — executes type-checker, tests, and linters. Findings grounded in actual tooling output. Can verify imports, check types, confirm function signatures.
- **Evaluation focus:** Type safety, test failures, import resolution, linter violations, correctness verified by tooling. Any finding backed by tool output gets elevated confidence.

**Configuration source of truth:** `_system/docs/code-review-config.md`

## Procedure

### Step 1: Test Gate (REQUIRED)

Before dispatching to reviewers, verify the project builds and tests pass:

1. **Run the type checker** (e.g., `npx tsc --noEmit` for TypeScript). If it fails, surface errors to user. Do NOT proceed — reviewers will waste tokens on type errors the compiler catches deterministically.
2. **Run the test suite** if one exists (e.g., `node --test`, `pytest`). If tests fail, surface failures to user. Do NOT proceed.
3. **If no test suite exists:** Note in run-log and proceed — the review may itself recommend adding tests.
4. **Explicit waiver:** User may say "review anyway" to bypass the gate. Log the waiver to run-log.
5. **Codex overlap:** Yes, Codex will also run these tools during its review. The gate is still valuable because it prevents dispatching Opus on known-broken code and avoids Codex spending time rediscovering what you already know.

### Step 2: Determine Scope

**Identify what's being reviewed:**
- If user specifies files: use those files. For untracked files, read content and construct a pseudo-diff (full file as additions). Combine with git diff for tracked files.
- If milestone boundary: use cumulative diff since last review tag or milestone start
- **If scope is ambiguous:** confirm with user before proceeding. Do not auto-scope.

**Capture:**
- **scope**: milestone | manual
- **diff_source**: git diff command or file list
- **project_name**: from project context
- **language**: TypeScript | Python | Shell | mixed (detected from file extensions)
- **framework_context**: Node.js test runner | pytest | custom-assert | etc.

**Polyglot handling:** When `language` is `mixed`, note the language breakdown. Review prompts instruct reviewers to section findings by language and apply language-specific criteria only to relevant files.

### Step 3: Generate Diff and Compute Stats

Produce the code diff to be reviewed:

**For manual reviews:**
```bash
# Uncommitted changes
git diff --unified=5

# Or staged changes
git diff --cached --unified=5

# Or specific files
git diff --unified=5 -- path/to/file1.ts path/to/file2.ts
```

**For milestone reviews:**
```bash
# Determine base_ref:
# 1. Most recent tag matching `code-review-*`
# 2. If no tag: milestone start commit from project-state.yaml or run-log
# 3. If no milestone metadata: `git log --oneline -20` and ask user to confirm base
git diff --unified=10 {base_ref}..HEAD -- {source_paths}
```

Use `--unified=5` for manual reviews, `--unified=10` for milestone reviews.

**Compute diff_stats (required):**
```bash
git diff --shortstat {range}
# Parse into: {files_changed, insertions, deletions}
```

**Source paths:** Detect from project structure. Exclude `node_modules`, `dist`, `venv`, `.git`, `__pycache__`.

**Diff size thresholds:**
- If diff exceeds **800 lines**, split into logical chunks (by file, then by directory). Review sequentially, merge findings, deduplicate.
- If diff exceeds **2500 lines**, recommend splitting the review scope. Segment by top-level directory or module and run multiple reviews; name review notes with segment suffixes (e.g., `code-review-milestone-m1-bridge.md`).

### Step 4: Assemble Review Context

Build context that accompanies the diff:

**Always include:**
- Project language and framework
- Test runner in use
- Brief project description (one line from project-state.yaml or run-log)
- Language breakdown if `mixed`

**Include when relevant:**
- Relevant spec section if the code implements a specific spec requirement
- Prior review findings from this milestone (shows what's already been caught)
- Project conventions from `_system/docs/solutions/` if relevant patterns exist

**Do NOT include:**
- Full project specs (too large)
- Run-log history
- Unrelated project files

### Step 4b: Analyze Diff Signals

Before assembling the review prompt, scan the diff for content signals that indicate
which review criteria deserve extra emphasis. This tailors the review to what actually
changed rather than applying uniform weight to all 9 criteria.

**Signal detection (keyword/path based — no external dependencies):**

| Signal | Detection | Lens Addition |
|--------|-----------|---------------|
| **Security** | Files matching `*auth*`, `*crypto*`, `*secret*`, `*token*`, `*session*`, `*permission*`; or diff contains `password`, `api_key`, `bearer`, `jwt`, `hash`, `encrypt`, `sanitize` | Emphasize: input validation, secret handling, injection risks, auth bypass. Add: "Flag any hardcoded credentials or secrets." |
| **Data/Schema** | Files matching `*migration*`, `*schema*`, `*model*`; or diff contains `CREATE TABLE`, `ALTER`, `addColumn`, `removeColumn`, `.schema` | Emphasize: backward compatibility, rollback safety, data loss risk, index impact. Add: "Flag breaking schema changes without migration path." |
| **API Contract** | Files matching `*route*`, `*handler*`, `*controller*`, `*endpoint*`; or diff contains `app.get`, `app.post`, `router.`, `@api`, `openapi` | Emphasize: breaking changes, versioning, response shape stability. Add: "Flag public API signature changes." |
| **Config/Infra** | Files matching `*.env*`, `*.yaml`, `*.toml`, `*plist*`, `Dockerfile`, `*.tf`; or diff contains `process.env`, `os.environ` | Emphasize: secret exposure, environment parity, deployment impact. Add: "Flag config that differs between environments." |
| **Shell/Automation** | Files matching `*.sh`, `*.bash`; or diff contains `set -e`, `launchctl`, `cron` | Emphasize: error handling under `set -e`, quoting, path assumptions, idempotency. Add: "Flag unquoted variables and missing error handling." |

**Capture:** List of detected signals (may be empty). Record for run-log.

### Step 5: Assemble Review Prompt

Build the full review prompt before dispatching. The SKILL is the single source of truth for prompt assembly; the dispatch agent wraps it but does not modify the review body.

**Prompt modification based on signals detected in Step 4b:**
- **0 signals:** Use the base prompt unchanged (identical to pre-enhancement behavior)
- **1-2 signals:** Keep all 9 criteria but reorder — move signal-relevant criteria to positions 1-3 and append lens-specific additions from the signal table
- **3+ signals:** Keep all 9 criteria, append all matched lens additions as a "Priority areas" section after the base criteria

The base prompt is never reduced — lenses add emphasis, not remove coverage.

```
You are reviewing code from a personal software project called Crumb.
This is a {language} project using {framework_context}.
{polyglot_note — if mixed: "The diff contains multiple languages. Section your findings by language/filetype and apply language-specific criteria only where relevant."}

Project context: {brief description}

{prior_findings_section — only if findings exist from earlier reviews:
"Prior review findings for this milestone — included for context, not as ground truth:
{summary of prior findings}"}

The code diff to review:
---
{diff}
---

Evaluate the code for:
1. Correctness — logic errors, unhandled cases, off-by-one errors
2. Security — input validation, secret handling, injection risks
3. Architecture — are abstractions right? does this match the stated design?
4. Error handling — are failures caught, logged, and recoverable?
5. Type safety — unsafe casts, implicit any, missing type annotations
6. Readability — would a future maintainer understand this code?
7. Test coverage — what's missing from the test suite?
8. Edge cases — what inputs or states could break this?
9. Performance — any obvious bottlenecks or unnecessary work?

{signal_section — only if 1+ signals detected in Step 4b:
"Priority areas based on diff content:
{for each detected signal: lens addition text from the signal table}"}

Be specific. Reference line numbers from the diff. If you see no issues
in a category, say so briefly — don't invent problems.
```

### Step 6: Dispatch

Spawn the `code-review-dispatch` subagent (`.claude/agents/code-review-dispatch.md`) via Task tool.

**Required parameters:**
- `project_name`: project label
- `review_prompt`: the fully rendered prompt from Step 5
- `scope`: `milestone` | `manual`
- `diff_stats`: `{files_changed, insertions, deletions}`
- `language`: detected language
- `repo_path`: absolute path to the project repo (for Codex CLI dispatch)

**Optional parameters:**
- `skip_reviewers`: list of reviewer IDs to skip
- `safety_override`: `false` unless re-spawning after explicit OVERRIDE

**Budget gate:** Before dispatching, estimate token count from diff size (~1 token per 4 chars). If estimated input tokens x 2 reviewers exceeds the `budget_warning_tokens` threshold in config (default: 100,000), inform user of estimated cost and request confirmation.

**Safety gate coordinator response:** When the dispatch agent returns a hard denylist halt:
1. Surface matched patterns to user (line numbers, pattern type, matched text)
2. Recommend secret removal and credential rotation
3. Block re-dispatch until code is cleaned
4. User may type `OVERRIDE` for confirmed false positives
5. Log incident to run-log

Wait for subagent return. If both reviewers fail, treat as ERROR — report and offer retry.

### Step 7: Synthesize

Read the review note produced by the subagent. Produce a decision-oriented synthesis.

**Finding ID namespacing:**
- `ANT-F1`, `ANT-F2` — Claude Opus
- `CDX-F1`, `CDX-F2` — Codex

Only process reviewer sections that exist — if a reviewer failed or was skipped, its section won't be present.

**Severity normalization:** Map non-standard labels to canonical buckets:

| Canonical | Also matches |
|-----------|-------------|
| CRITICAL | High, Blocker, Severe, Error |
| SIGNIFICANT | Medium, Important, Warning |
| MINOR | Low, Nit, Suggestion, Nice-to-have |
| STRENGTH | Positive, Works well, Good |

**Tool-grounded elevation:** When Codex cites actual tool output (compiler error, test failure, linter violation) to support a finding, note it in synthesis. Tool-verified findings are higher confidence than reasoning-only findings, regardless of which reviewer raised them.

**Step 7b: Cluster Analysis**

After normalizing severity and deduplicating consensus findings, check for systemic
patterns before generating action items.

1. **Group findings by theme.** For each finding, extract:
   - File path (directory-level grouping)
   - Issue type (from the 9 evaluation criteria: correctness, security, etc.)
   - Description keywords

2. **Detect clusters.** A cluster forms when 3+ findings share:
   - Same issue type AND same directory, OR
   - Same issue type AND similar description (>50% keyword overlap)

3. **Promote clusters.** When a cluster is detected:
   - Create a **systemic finding** that names the root cause pattern
   - List the individual findings as instances under the systemic finding
   - Generate one systemic action item (address the pattern) instead of N individual items
   - Individual items are preserved as sub-items for traceability

4. **Gate:** If fewer than 3 findings share a theme, skip clustering — individual
   findings are fine at low counts. Record "0 systemic" in run-log.

**Synthesis structure:**

#### Systemic Findings
*(Only present when clusters detected in Step 7b.)*
Root-cause patterns backed by 3+ individual findings. Each systemic finding includes:
the pattern name, the underlying issue, the individual findings that form the cluster,
and a single systemic action item. Systemic findings represent the highest-leverage
fixes — addressing one pattern resolves multiple individual issues.

#### Consensus Findings
Issues flagged by both reviewers. Highest signal — if Opus's architectural reasoning and Codex's tooling independently spot the same bug, it's almost certainly real. Match by file + line range + issue type. Findings already captured in a systemic cluster are referenced by cluster ID rather than repeated.

#### Unique Findings
Issues only one reviewer caught. For Opus, these tend to be design-level insights. For Codex, these tend to be type/test/import issues the type-checker or test runner surfaced. Flag whether each seems like genuine insight or noise.

#### Contradictions
Where reviewers disagree on approach or severity. Present both positions, do not resolve — flag for human judgment.

#### Action Items
Numbered list of concrete actions. **Systemic actions first** (from clusters), then individual actions:
- **Must-fix** — critical, consensus, or systemic issues
- **Should-fix** — significant but not blocking
- **Defer** — minor or speculative

Each action item includes: Action ID (A1, A2...), source findings (or cluster ID for systemic), file:line locations, and what to do.

#### Considered and Declined
Findings evaluated and rejected, with reason: `incorrect`, `constraint`, `overkill`, or `out-of-scope`. Preserved so user can override.

### Step 8: Present Results

- Display summary in conversation (not full reviews — those are in the vault)
- Link to review note
- Highlight must-fix findings explicitly
- If Codex ran tools, note what it ran and any failures it found
- **Tag the reviewed commit:** `git tag code-review-{YYYY-MM-DD}` — provides base ref for next review's diff
- Ask if user wants to act on findings immediately

### Step 9: Iterate (if needed)

3 rounds maximum per review cycle. If user wants to revise and re-review:

1. Apply accepted changes
2. Generate incremental diff since last review tag
3. Assemble new prompt focused on changes: "Review these changes made in response to the prior review. Evaluate whether the fixes are correct and don't introduce regressions."
4. Dispatch new review
5. Synthesize, referencing prior round findings

## Decision Authority

External reviewers are **evidence gatherers**, Claude (the session coordinator) is the **decision maker**, user is the **approver**.

## Context Contract

**MUST have:**
- The code diff or files to review
- Project language/framework context (detectable from files)

**MAY request:**
- `_system/docs/code-review-config.md` (reviewer panel config)
- Prior review findings for the current milestone
- Project conventions from `_system/docs/solutions/`

**Subagent loads separately:**
- `~/.config/crumb/.env` (API keys — dispatch agent only)

**AVOID:**
- Loading full project specs
- Loading multiple project contexts in a single review

**Typical budget:** Standard tier (2-3 docs).

## Output Constraints

- Review notes written to `{project}/reviews/{YYYY-MM-DD}-code-review-{scope}.md`
- If segmented: add suffix `-{segment}`
- Raw responses stored in `{project}/reviews/raw/`
- Codex JSONL transcript stored alongside raw responses
- Frontmatter includes `review_type: code`, `language`, `framework`, `diff_stats`, `token_usage` per reviewer
- Finding IDs: `ANT-F1` (Opus), `CDX-F1` (Codex)

**Run-log format (all reviews):**
```markdown
### Code Review — {scope} {TASK_ID(s) or description}
- Scope: {file list or milestone range}
- Panel: Claude Opus 4.6, Codex GPT-5.3-Codex
- Signals: {signal list, e.g. "security, shell-automation" | "none detected"}
- Codex tools: tsc {pass|fail|skipped}, tests {pass|fail|skipped}
- Findings: {N} critical, {N} significant, {N} minor, {N} strengths
- Consensus: {N} findings flagged by both reviewers
- Clusters: {N} systemic ({N} instances) | 0 systemic
- Details:
  - [ANT-F1] {severity}: {file}:{line} — {one-line summary}
  - [CDX-F1] {severity}: {file}:{line} — {one-line summary}
  - ...
- Action: {fixed | deferred | no action needed}
- Review note: {path}
```

## Output Quality Checklist

Before marking complete, verify:
- [ ] Test gate passed or explicitly waived (Step 1)
- [ ] Review scope confirmed (Step 2)
- [ ] Diff generated with appropriate context lines; diff_stats computed (Step 3)
- [ ] Review context assembled without bloat (Step 4)
- [ ] Diff signals analyzed (Step 4b)
- [ ] Full prompt assembled by SKILL with signal-aware emphasis before dispatch (Step 5)
- [ ] Dispatch agent spawned with all required parameters including repo_path (Step 6)
- [ ] Safety gate response handled (Step 6)
- [ ] Cluster analysis performed on findings (Step 7b)
- [ ] Synthesis includes all sections — systemic (if clusters), consensus, unique, contradictions, actions, declined (Step 7)
- [ ] Tool-grounded findings noted (Step 7)
- [ ] Action items classified with file:line references (Step 7)
- [ ] Review note written (Step 8)
- [ ] Reviewed commit tagged (Step 8)
- [ ] Results presented to user (Step 8)

## Compound Behavior

Track patterns across reviews:
- **Recurring findings** → promote to project conventions or linting rules
- **Reviewer strengths** → document which reviewer catches which issue types
- **Tool value** → track how often Codex's tool-grounded findings catch real bugs that Opus missed
- **Signal effectiveness** → track whether detected signals (Step 4b) correlated with actual findings in those areas. If a signal consistently fires but produces no relevant findings, consider removing it. If findings cluster in an area with no signal, consider adding one.

**Pattern Recording:** After each review, scan findings for patterns matching entries in `_system/docs/solutions/code-review-patterns.md`. For new patterns with 3+ occurrences:

```
### {Pattern name}
- Frequency: {N} occurrences across {N} reviews
- Reviewers: {which caught it}
- Tool-verified: {yes/no}
- Example: {file:line from most recent occurrence}
- Action taken: {convention added | prompt adjusted | linting rule | none yet}
```

**Cross-review systemic pattern promotion:** When a systemic finding (from Step 7b
cluster analysis) recurs across 2+ separate reviews — same root-cause pattern in
different review sessions — promote it to `_system/docs/solutions/` with the
appropriate track classification:
- Systemic bug pattern (e.g., "missing input validation on all new endpoints") → `track: bug`
- Systemic design pattern (e.g., "error handling inconsistency across modules") → `track: pattern`
- Use standard compound step confidence tagging (§4.4) for the promoted doc.

## Convergence Dimensions

1. **Correctness** — Findings are real issues, not hallucinations; tool-verified where possible
2. **Coverage** — Review addressed all evaluation criteria
3. **Actionability** — Each finding has a concrete fix or clear deferral reason
4. **Proportionality** — Review effort matches risk level
