---
type: design
domain: software
status: active
project: tess-v2
skill_origin: action-architect
created: 2026-04-01
updated: 2026-04-01
---

# TV2-023: System Prompt Architecture

## 1. Overview

Three execution contexts, three prompt surfaces, one composition engine. Every dispatch
from Tess assembles a prompt envelope from layered components. The composition engine
enforces token budgets, applies compaction when necessary, and validates the envelope
before dispatch.

**Execution contexts:**

| Context | Model | Budget | Role | Response field |
|---------|-------|--------|------|----------------|
| Local executor | Nemotron Cascade 2 | 16K tokens | Contract execution (vault writes, structured output) | `content` at <=64K; `reasoning_content` at 128K |
| Cloud orchestrator | Kimi K2.5 (primary) / Qwen 3.5 (failover) | 32K tokens | Evaluation, triage, multi-step planning | `reasoning_content` always (Kimi); `content` (Qwen) |
| Claude Code dispatch | Sonnet via `claude --print` | No explicit token cap (CLAUDE.md + system prompt) | Complex code tasks, vault operations requiring full tool access | Standard `content` |

## 2. Prompt Layer Stack

Prompts are assembled top-down. Each layer has a fixed position in the final envelope.
No layer can appear out of order. The composition engine concatenates layers with
`\n---\n` separators.

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 1: STABLE HEADER                              <=1.5K    │
│  Identity, role, datetime, hard constraints, response format    │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: SERVICE CONTEXT                            2-4K      │
│  Routing table, action classes, executor profile                │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 3: OVERLAYS (0-3)                             0-3K      │
│  Behavioral overlays injected per AD-005                        │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 4: CONTRACT                                   1-3K      │
│  The contract YAML: tests, artifacts, quality_checks, budget    │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 5: VAULT CONTEXT                              remaining  │
│  Read paths, file contents, search results                      │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 6: FAILURE CONTEXT (iterations 2+ only)       1-2K      │
│  Structured diagnostics from prior iteration (Amendment T)      │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Definitions

**Layer 1 — Stable Header** (always present, never compacted)

Contents:
- Identity excerpt from SOUL.md — 3-4 sentences establishing persona and operating posture
- Role definition for this dispatch: `executor` or `evaluator`
- Current UTC datetime
- Hard constraints: staging write path, escalation policy, retry budget remaining
- Response format directive (structured YAML envelope for executors; evaluation
  schema for orchestrator)
- **Nemotron-specific:** explicit instruction to deliver the final answer in the
  response, not defer to tool calls (addresses orch-05/orch-06 behavioral pattern)

Budget: <=1,500 tokens. This is the only layer with a hard floor — it is never
truncated or removed.

**Layer 2 — Service Context** (per-dispatch)

Contents:
- Routing table entries relevant to the current task type
- Action class definition for this contract's task type
- Executor profile (capabilities, known quirks, token limits)
- Available tools list (for tool-calling executors)

Budget: 2,000-4,000 tokens depending on task complexity.

**Layer 3 — Overlays** (per-dispatch, max 3)

Contents:
- Behavioral overlays from `_system/docs/overlays/` filtered by `dispatch_eligible: true`
- Selected by Tess based on: task type defaults from routing table, project-specific
  overlays, explicit operator requests
- Each overlay is a self-contained markdown section

Budget: 0-3,000 tokens (0-1,000 per overlay). Selection priority when >3 overlays
match: most task-specific first (per AD-005).

**Layer 4 — Contract** (per-dispatch)

Contents:
- The contract YAML block in full — tests, artifacts, quality_checks,
  staging_path, retry_budget, escalation target
- The contract is the authoritative instruction surface (§9.5 Pattern 2)

Budget: 1,000-3,000 tokens. Contracts that exceed 3K should be decomposed.

**Layer 5 — Vault Context** (per-dispatch, variable)

Contents:
- File contents from contract `read_paths`
- Search results from vault queries
- Project state excerpts

Budget: whatever remains after layers 1-4 and 6 are allocated. This is the
compaction target — see section 4.

**Layer 6 — Failure Context** (iterations 2+ only)

Contents:
- Structured failure diagnostics per Amendment T:
  - Which checks failed (check_id, expected, actual, delta)
  - Failure class from §9.4
  - Retry strategy recommendation
  - Iteration count and budget remaining
- Prior iteration's response (summary, not full) if reasoning failure

Budget: 1,000-2,000 tokens. On iteration 3 (final retry), only the most
recent failure is included — do not accumulate all prior failures.

## 3. Token Budget Allocation

### 3.1 Nemotron (Local Executor) — 16K Budget

```
Layer 1: Stable header           1,500 tokens (fixed)
Layer 2: Service context         2,000 tokens (minimal — executor doesn't route)
Layer 3: Overlays (0-2)          0-2,000 tokens
Layer 4: Contract                1,500 tokens (typical)
Layer 5: Vault context           7,000-9,000 tokens (the variable pool)
Layer 6: Failure context         0-2,000 tokens (iterations 2+ only)
                                 ─────────────
                                 16,000 tokens maximum
```

Iteration 1: ~12,000 tokens available for vault context (layers 1+2+4 = ~5K).
Iteration 2+: ~10,000 tokens for vault context after failure context allocation.

**Critical threshold:** Keep total dispatch under 64K actual tokens sent to the
model. At 128K, Nemotron leaks answers to `reasoning_content` — the extraction
fallback (section 6) handles this, but staying under 64K avoids the issue entirely.
The 16K budget is well within this range.

### 3.2 Kimi K2.5 / Qwen 3.5 (Cloud Orchestrator) — 32K Budget

```
Layer 1: Stable header           1,500 tokens (fixed)
Layer 2: Service context         3,500 tokens (full routing table for triage)
Layer 3: Overlays (0-3)          0-3,000 tokens
Layer 4: Contract                2,000 tokens (evaluation contracts are larger)
Layer 5: Vault context           18,000-22,000 tokens (the variable pool)
Layer 6: Failure context         0-2,000 tokens (iterations 2+ only)
                                 ─────────────
                                 32,000 tokens maximum
```

Evaluation dispatches get richer vault context because the orchestrator needs to
compare executor output against specs, project state, and quality criteria.

### 3.3 Claude Code Dispatch — Unbounded (Cost-Governed)

Claude Code dispatch via `claude --print` does not use the layered envelope.
Instead:

```
CLAUDE.md (loaded automatically by claude --print in vault directory)
  + System prompt (passed via --system-prompt flag or piped)
    ├── Contract YAML (the authoritative instruction)
    ├── Vault context (file paths — Claude Code reads them with its own tools)
    └── Failure context (if retrying)
```

Key differences from local/cloud dispatch:
- **No token budget enforcement by Tess.** Claude Code manages its own context.
- **File paths, not file contents.** Claude Code has Read/Glob/Grep tools — pass
  paths and let it read. This is cheaper and avoids stale-content bugs.
- **CLAUDE.md is the stable header.** The vault's CLAUDE.md serves the identity
  and constraint role that Layer 1 serves for local/cloud.
- **Contract is the system prompt.** Pass the contract YAML as the system prompt
  or as the first section of the prompt.

Cost: ~$0.10-0.15 per dispatch on Sonnet. Use for V1/V2 verifiability contracts
that require tool access (code execution, git operations, multi-file vault edits).

## 4. Compaction Priority Table

When the composed envelope exceeds the context budget, the composition engine
removes content in this order. **Never remove Layer 1 (stable header) or
Layer 4 (contract).**

| Priority | Layer | Compaction action | Trigger |
|----------|-------|-------------------|---------|
| 1 (first to cut) | L5: Vault context | Remove most-distant files first. Distance = fewest wikilink hops from contract target paths. | Budget exceeded by any amount |
| 2 | L5: Vault context | Truncate remaining files to frontmatter + first section only | After all distant files removed, still over budget |
| 3 | L3: Overlays | Remove least-specific overlay first. Specificity: explicit request > project-specific > task-type default. | After L5 compaction, still over budget |
| 4 | L2: Service context | Truncate routing table to current task type entry only. Remove executor profiles for non-selected executors. | After L3 compaction, still over budget |
| 5 | L6: Failure context | Reduce to most recent iteration's failure only (drop earlier iterations). Summarize diagnostics to check_id + delta only. | After L2 compaction, still over budget |
| 6 (last resort) | L5: Vault context | Remove ALL vault context. Executor works from contract alone. | Emergency — should trigger escalation review |

**Hard floor:** Layers 1 + 4 must always fit within budget. If they don't
(theoretically >16K for just header + contract), the contract itself is malformed
and should be rejected before dispatch.

**Compaction logging:** Every compaction event is logged to the contract execution
ledger with: which layers were compacted, how many tokens were removed, and the
final envelope size. This feeds convergence rate tracking (Amendment W) — contracts
that consistently require heavy compaction should have their read_paths trimmed.

## 5. Context-Specific Prompt Assembly

### 5.1 Orchestrator Prompt (Kimi K2.5 evaluating a contract result)

The orchestrator receives a different Layer 1 and Layer 2 than executors. Its
job is evaluation, not execution.

**Layer 1 differences:**
- Role: `evaluator`
- Response format: evaluation schema (pass/fail per check, structured diagnostics,
  promotion recommendation)
- No tool-call suppression (Kimi routes through reasoning_content by default)

**Layer 2 differences:**
- Full routing table (orchestrator needs it for re-routing decisions)
- All executor profiles (for routing failed contracts to alternates)
- No tool definitions (evaluation is judgment, not tool use)

**Layer 4 differences:**
- Contract includes the executor's output artifacts (or staging paths)
- Quality_checks section is the primary instruction surface

### 5.2 Executor Prompt (Nemotron executing a vault-write contract)

**Layer 1 includes:**
- Role: `executor`
- Explicit instruction: "Produce your final answer directly. Do not defer to tool
  calls when the task asks for analysis, evaluation, or written output."
- Response format: execution result YAML envelope (§10.3)

**Layer 2 includes:**
- Only the current task type's action class
- Only the selected executor's profile
- Tool definitions if the contract requires tool use

### 5.3 Claude Code Dispatch Prompt

Assembled as a single text block passed to `claude --print --system-prompt`:

```
You are executing contract {contract_id} for Tess.

## Contract
{contract YAML}

## Context
Read these files for context:
- {path_1}
- {path_2}

## Constraints
- Write all output to {staging_path}
- Do not modify files outside staging
- Return the execution_result YAML envelope when complete

## Failure Context (if iteration 2+)
{structured diagnostics from prior iteration}
```

CLAUDE.md loads automatically when `claude --print` runs in the vault directory.
The system prompt above is additive — it does not replace CLAUDE.md.

## 6. Response Extraction

### 6.1 Nemotron Response Handling

Based on TV2-013 probe results:

| Context size | Answer location | Extraction |
|-------------|-----------------|------------|
| <=64K | `content` field | Direct read |
| 128K | `reasoning_content` field | Fallback extraction |

**Extraction procedure:**
1. Check `content` field. If non-empty and parseable as the expected response
   schema, use it.
2. If `content` is empty or unparseable, check `reasoning_content`.
3. If `reasoning_content` contains the expected response schema, extract it.
4. Apply the lenient parsing layer (Amendment U) to whichever field yielded content.
5. If neither field contains parseable output, classify as a tool failure and retry.

**Design goal:** Keep Nemotron dispatches under 64K total context to avoid the
reasoning_content fallback path. The 16K prompt budget achieves this — the model's
own output plus any tool-call responses would need to exceed ~48K to push past 64K.

### 6.2 Kimi K2.5 Response Handling

Kimi K2.5 returns ALL responses in `reasoning_content` with `content: null` — this
is confirmed default behavior, not edge-case (hermes-patch-tracking.md). The Hermes
patch (#4467) handles this at the gateway level.

**For direct API consumers (if Hermes is bypassed):**
1. Always read `reasoning_content` first for Kimi.
2. Fall through to `content` only as a defensive check.
3. The lenient parsing layer applies to `reasoning_content` output.

### 6.3 Qwen 3.5 Response Handling (Failover)

Qwen 3.5 uses standard `content` field. No special extraction needed. Apply lenient
parsing layer as with all executors.

### 6.4 Claude Code Response Handling

`claude --print` returns plain text to stdout. Use `--output-format json` for
structured output including token usage. The response is always in the standard
output field.

## 7. Nemotron Behavioral Mitigations

TV2-013 identified two patterns that prompt design must address:

### 7.1 Tool-Call Deferral on Evaluation Tasks

**Pattern:** On tasks requiring evaluation or classification (orch-05, orch-06),
Nemotron produces correct reasoning but outputs a tool call (vault_search) instead
of delivering the analysis.

**Mitigation — Layer 1 directive (stable header):**

```
RESPONSE DISCIPLINE: When the contract asks you to evaluate, classify, analyze,
or produce written output — deliver your answer directly in the response. Do NOT
issue tool calls as a substitute for providing your analysis. Tool calls are for
retrieving information you need. Your analysis IS the deliverable.
```

This directive appears in the stable header for ALL Nemotron dispatches, not just
evaluation tasks. The cost is ~50 tokens and prevents the pattern from surfacing
on any task type.

**Fallback — harness-level detection:**
If the response contains only a tool call and no substantive content, the Ralph
loop runner:
1. Executes the tool call
2. Feeds the result back as additional context
3. Requests the final answer in a second turn
4. This counts as one iteration, not two — the tool-call-then-answer is a single
   logical iteration of the Ralph loop

### 7.2 128K Reasoning Content Leak

Addressed in section 6.1. The architectural mitigation is keeping prompt budgets
well under the 64K threshold. The extraction fallback is defense-in-depth.

## 8. Example Prompts

### 8.1 Nemotron Executing a Vault-Write Contract

```
# Layer 1: Stable Header
You are Tess — Danny's primary agent. Practical, evidence-driven, efficient.
You are operating as an EXECUTOR for contract TV2-001-C.

Current time: 2026-04-01T14:30:00Z
Role: executor
Staging path: _staging/TV2-001-C/
Retry budget remaining: 3
Escalation target: tess

RESPONSE DISCIPLINE: When the contract asks you to evaluate, classify, analyze,
or produce written output — deliver your answer directly in the response. Do NOT
issue tool calls as a substitute for providing your analysis. Tool calls are for
retrieving information you need. Your analysis IS the deliverable.

Return your result as a YAML execution_result envelope.

---
# Layer 2: Service Context
## Action Class: vault-write
Writes structured markdown artifacts to staging. Executor produces files with
valid YAML frontmatter. All paths are vault-relative from /Users/tess/crumb-vault/.

## Executor Profile: nemotron-cascade-2
- Context budget: 16K tokens
- Strengths: fast structured output, tool calling, vault operations
- Known quirk: may defer to tool calls on evaluation tasks (see response discipline)
- Output field: content (<=64K context)

---
# Layer 3: Overlays
## cost-optimization
Minimize token usage. Prefer concise output. Do not pad deliverables with
explanatory prose unless the contract requires it.

---
# Layer 4: Contract
```yaml
contract_id: TV2-001-C
type: vault-write
description: "Migration inventory of all existing Tess operational wiring"
created: 2026-04-01
staging_path: "_staging/TV2-001-C/"

tests:
  - type: file_exists
    path: "_staging/TV2-001-C/migration-inventory.md"
  - type: frontmatter_valid
    path: "_staging/TV2-001-C/migration-inventory.md"
    required_fields: [type, status, created]

artifacts:
  - description: "Inventory covers all OpenClaw cron jobs"
    verification: "grep -c 'ai.openclaw' migration-inventory.md >= 5"
    executor: runner
  - description: "Each service has migrate/rebuild/drop classification"
    verification: "frontmatter action_class present on all service entries"
    executor: runner

quality_checks:
  - description: "No critical service missed"
    evaluator: tess
  - description: "Classifications are reasonable"
    evaluator: tess

termination: "ALL tests pass AND ALL artifacts verified"
retry_budget: 3
escalation: "tess"
```

---
# Layer 5: Vault Context
## File: Projects/tess-v2/design/specification.md §11.2 (excerpt)
| Service | Current Platform | Trigger | Status |
|---|---|---|---|
| Feed-intel pipeline | OpenClaw cron | Scheduled (hourly) | Active |
| Email triage | OpenClaw cron | Scheduled (every 30 min) | Active |
| Morning briefing | OpenClaw cron | Scheduled (daily 7am) | Active |
| Overnight research | OpenClaw cron | Scheduled (nightly) | Disabled |
| Daily attention | OpenClaw cron | Scheduled (daily) | Active |
| Apple data snapshots | LaunchAgent (danny) | Scheduled (every 30 min) | Active |
| Heartbeat mechanics | OpenClaw cron | Scheduled (every 15 min) | Active |

## File: _openclaw/state/tess-context.md (current services section)
[... truncated vault content ...]
```

**Token estimate:** ~2,800 tokens (header 400 + service 350 + overlay 150 +
contract 650 + vault 1,250). Well within the 16K budget with ~13K remaining for
vault context expansion.

### 8.2 Kimi K2.5 Evaluating a Contract Result

```
# Layer 1: Stable Header
You are Tess — Danny's primary agent. Practical, evidence-driven, efficient.
You are operating as an EVALUATOR for contract TV2-001-C, iteration 1.

Current time: 2026-04-01T15:45:00Z
Role: evaluator
Contract: TV2-001-C
Executor: nemotron-cascade-2
Staging path: _staging/TV2-001-C/

Produce your evaluation as a structured YAML block:
```yaml
evaluation:
  contract_id: TV2-001-C
  iteration: 1
  quality_checks:
    - check_id: "quality_check_1"
      description: "..."
      result: pass | fail
      evidence: "..."
      delta: "..."  # only on failure
  promotion_recommendation: promote | hold_for_review | reject
  reasoning: "..."
```

---
# Layer 2: Service Context
## Routing Table (evaluation context)
| Action Class | Default Executor | Failover | Verifiability |
|---|---|---|---|
| vault-write | nemotron-cascade-2 | claude-sonnet | V1: deterministic |
| research | kimi-k2.5 | qwen-3.5 | V2: heuristic |
| evaluation | kimi-k2.5 | qwen-3.5 | V3: judgment |

## Executor Profile: nemotron-cascade-2 (for context on executor limitations)
- Known to defer to tool calls on evaluation tasks
- Output under 64K is in content field; verify artifacts, not response metadata

---
# Layer 3: Overlays
(none for this evaluation — pure contract evaluation, no domain overlay needed)

---
# Layer 4: Contract (original, for reference)
```yaml
contract_id: TV2-001-C
type: vault-write
description: "Migration inventory of all existing Tess operational wiring"
# ... full contract as dispatched to executor ...
quality_checks:
  - description: "No critical service missed"
    evaluator: tess
  - description: "Classifications are reasonable"
    evaluator: tess
```

---
# Layer 5: Vault Context
## Executor Output: _staging/TV2-001-C/migration-inventory.md
---
type: reference
status: draft
created: 2026-04-01
---
# Tess v2 — Migration Inventory

| Service | Platform | Cron Label | Trigger | Classification |
|---|---|---|---|---|
| Feed-intel pipeline | OpenClaw | ai.openclaw.feed-intel | hourly | migrate |
| Email triage | OpenClaw | ai.openclaw.email-triage | 30min | migrate |
| Morning briefing | OpenClaw | ai.openclaw.morning-brief | daily 7am | migrate |
| Overnight research | OpenClaw | ai.openclaw.overnight-research | nightly | drop (broken) |
| Daily attention | OpenClaw | ai.openclaw.daily-attention | daily | migrate |
| Apple data snapshots | LaunchAgent | com.crumb.apple-snapshot | 30min | keep (danny domain) |
| Heartbeat mechanics | OpenClaw | ai.openclaw.heartbeat | 15min | rebuild |
[... rest of inventory ...]

## Reference: specification.md §11.2 (ground truth service list)
[... service table for cross-reference ...]

## Runner Test Results
- file_exists: PASS
- frontmatter_valid: PASS
- artifact grep check: PASS (7 matches >= 5)
- artifact classification check: PASS
```

**Token estimate:** ~4,200 tokens. Well within 32K budget with ample room for
richer vault context on complex evaluations.

## 9. Composition Engine Interface

The composition engine is a function called by the dispatch orchestrator before
every Ralph loop dispatch. It is deterministic — no LLM in the composition path.

```python
def compose_envelope(
    context: str,          # "executor" | "evaluator" | "claude-code"
    contract: dict,        # Parsed contract YAML
    executor: str,         # Model identifier
    overlays: list[str],   # Overlay file paths (max 3)
    vault_paths: list[str],# Files to include as vault context
    failure_context: dict | None,  # Structured diagnostics from prior iteration
    iteration: int,        # Current Ralph loop iteration (1-indexed)
) -> EnvelopeResult:
    """
    Returns:
        EnvelopeResult:
            prompt: str           # The assembled prompt text
            token_count: int      # Estimated token count
            budget: int           # Budget for this context (16K/32K)
            compacted: list[str]  # Layers that were compacted
            warnings: list[str]   # Budget warnings
    """
```

**Token counting:** Use tiktoken with cl100k_base encoding as a fast approximation.
Actual model tokenizers differ, but cl100k is conservative (over-counts slightly
for most models). The budget includes a 5% safety margin — a 16K budget dispatches
at most 15,200 estimated tokens.

**Validation gates (mechanical, per AD-006):**
1. Total token count <= budget (after compaction)
2. Layer 1 is present and non-empty
3. Layer 4 (contract) is present and parseable as YAML
4. Overlay count <= 3
5. Staging path in contract matches the dispatch staging_path
6. If iteration > 1, failure_context is non-null

If any gate fails, the dispatch is rejected with a structured error — no silent
degradation.

## 10. Prompt Versioning

Prompt components live in the vault as markdown files. Changes are tracked by
vault-check and picked up on the next dispatch cycle (§10b.2). No service restart
required.

**Stable header:** `_openclaw/prompts/headers/executor.md`, `evaluator.md`
**Overlays:** `_system/docs/overlays/` (existing location)
**Executor profiles:** `_openclaw/prompts/profiles/{model-name}.md`
**Response format templates:** `_openclaw/prompts/formats/execution-result.md`,
`evaluation-result.md`

The composition engine reads these files at dispatch time. Caching is permitted
with a 60-second TTL — prompt file changes take effect within one minute.

## 11. Design Decisions

**D1: Failure context at the bottom, not the top.**
Failure context (Layer 6) goes last because it is the most recent and most
actionable information. LLMs attend more strongly to content at the beginning
and end of prompts (primacy/recency). The stable header gets primacy; failure
context gets recency.

**D2: Contract as a separate layer from vault context.**
The contract is the authoritative instruction surface — it defines what "done"
means. Keeping it distinct from vault context (reference material) prevents the
model from treating reference files as instructions or the contract as optional
context.

**D3: Overlay budget of 1K per overlay, not variable.**
Fixed per-overlay budget prevents one verbose overlay from starving the others.
Overlays that exceed 1K tokens should be split or compacted at authoring time,
not at dispatch time.

**D4: No recursive vault reads in prompts.**
If a vault file references other files via wikilinks, the composition engine does
NOT follow those links. The contract's `read_paths` is the exhaustive list of
files to include. This prevents unbounded context growth and makes token counting
deterministic.

**D5: Claude Code gets paths, not contents.**
Claude Code has its own file-reading tools. Passing paths instead of contents
avoids stale-content bugs (file changed between Tess reading it and Claude Code
using it) and reduces the system prompt size. The contract YAML is the only
content passed inline.

## 12. Downstream Dependencies

- **TV2-031d (dispatch envelope validator):** Implements the validation gates
  from section 9. The validator is a standalone function that can be tested
  independently of the composition engine.
- **TV2-017 (state machine):** The composition engine is called at the dispatch
  transition. State machine provides the contract, executor selection, and
  overlay list.
- **TV2-019 (contract schema):** Contract YAML structure (Layer 4) must match
  the schema. The composition engine validates parseability but not schema
  compliance — that is the contract validator's job.
- **Amendment T (structured diagnostics):** Layer 6 format depends on the
  failure context schema from Amendment T.
- **Amendment U (lenient parsing):** The extraction procedure (section 6) feeds
  into the lenient parsing layer, which is a separate component downstream of
  prompt composition.
