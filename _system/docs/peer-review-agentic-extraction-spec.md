---
type: specification
domain: software
status: approved
created: 2026-02-23
updated: 2026-02-23
tags:
  - peer-review
  - subagent
---

# Peer Review — Agentic Extraction

## Problem

The peer review skill runs Steps 0–8 in a single Claude Code context window. This works, but the dispatch + collection + raw response storage (Steps 0–5) consumes significant context on mechanical work — constructing payloads, waiting for API responses, extracting text, writing raw JSON files. The synthesis (Step 6) and operator triage then compete for the remaining context budget, which is where judgment quality matters most.

The skill has been used across multiple projects (action plan reviews, M1 capture clock, upcoming M2+M3 review) and the protocol is stable. The structured inputs, outputs, and decision boundaries are well-defined — making this a clean extraction candidate.

## Proposed Change

Extract **Steps 0–5** (safety gate, artifact identification, prompt construction, dispatch, raw response storage, review note skeleton) into a **peer-review-dispatch subagent**. The main session retains **Steps 6–8** (synthesis, presentation, iteration).

This is a skill refactor, not a new capability. The subagent does exactly what the main session does today for Steps 0–5, but in an isolated context window. The main session gets back a completed review note with all raw reviewer responses written to the vault, ready for synthesis.

## Architecture

### Before (current)

```
Main session:
  Step 0: Load API keys
  Step 1: Safety gate
  Step 2: Identify artifact
  Step 3: Construct prompt
  Step 4: Dispatch to reviewers (concurrent curl)
  Step 5: Write review note + raw responses
  Step 6: Synthesize                              ← judgment-heavy
  Step 7: Present results                         ← judgment-heavy
  Step 8: Iterate (if needed)                     ← judgment-heavy
```

All 8 steps share one context window. Steps 0–5 are mechanical but consume context on payload construction, response parsing, and file I/O.

### After (proposed)

```
Main session:
  1. User requests peer review
  2. Identify artifact + review scope (full/diff, custom prompt)
  3. Assemble the review prompt (Layer 2 — review body):
     - Default template from peer-review-config.md, OR
     - Custom prompt replacing it entirely if user provided one, OR
     - Default template + appended focus areas if user added questions
  4. Spawn peer-review-dispatch subagent with:
     - artifact_path
     - review_mode (full | diff)
     - prompt (fully assembled Layer 2 — subagent does not do template logic)
     - base_ref (for diff mode)
  5. Subagent returns summary: reviewer count, success/failure per reviewer,
     review note path, any safety gate events
  6. Main session reads review note (reviewer responses already written)
  7. Synthesize (Step 6 — unchanged)
  8. Present results (Step 7 — unchanged)
  9. Iterate if needed (Step 8 — unchanged, spawns new subagent for re-review)

Subagent (peer-review-dispatch):
  Step 0: Load API keys
  Step 1: Safety gate
  Step 2: Read artifact (path provided by main session)
  Step 3: Wrap prompt (add Layer 1 injection resistance + Layer 3 structured
          output enforcement around the Layer 2 prompt received from main session)
  Step 4: Dispatch to reviewers (concurrent Python script constructed at runtime)
  Step 5: Write review note skeleton + raw responses to vault
  Return: summary to main session
```

### What moves to the subagent

| Step | Current owner | New owner | Rationale |
|------|--------------|-----------|-----------|
| 0 (API keys) | Main | Subagent | Mechanical — .env loading |
| 1 (Safety gate) | Main | Subagent | Mechanical — regex scanning. If hard denylist triggers, subagent halts and returns the match to main session for operator decision. Main session handles the OVERRIDE prompt. |
| 2 (Identify artifact) | Main | **Split** | Main session identifies the artifact and passes the path. Subagent reads the content. This keeps the "what are we reviewing?" decision with the operator. |
| 3 (Construct prompt) | Main | **Split** | Main session assembles the Layer 2 review body (default template, custom replacement, or template + appended questions) and passes the final prompt string. Subagent wraps it with Layer 1 (injection resistance) and Layer 3 (structured output enforcement) — these are mechanical, per-reviewer wrappers. All "what do we want to ask?" judgment stays in the main session. |
| 4 (Dispatch) | Main | Subagent | Mechanical — concurrent curl, retry, response extraction. The biggest context consumer today. |
| 5 (Write review note) | Main | Subagent | Mechanical — frontmatter construction, raw JSON storage, review note skeleton. |
| 6 (Synthesize) | Main | **Main** | Judgment-heavy — consensus detection, contradiction resolution, action item triage. Benefits from full main session context and operator interaction. |
| 7 (Present) | Main | **Main** | Operator-facing — conversation, highlighting, questions. |
| 8 (Iterate) | Main | **Main** | Operator-driven — spawns new subagent if re-review needed. |

### What the subagent writes to the vault

The subagent produces a review note at `{reviews_dir}/{date}-{artifact-name}.md` (where `reviews_dir` is `Projects/{project}/reviews/` if the artifact has a project, otherwise `_system/reviews/`) using a **write-before-dispatch** pattern for crash resilience:

1. **Before dispatch:** Write the review note skeleton with complete frontmatter (type, review_mode, review_round, hashes, reviewer_meta, safety_gate, config_snapshot) and empty per-reviewer section headings. This is the durability boundary — if the subagent crashes after this point, the main session can see which reviewers were attempted.
2. **During dispatch:** Write each raw JSON response to `{reviews_dir}/raw/` as it arrives. Each raw response file is independently durable — if it exists, that reviewer succeeded.
3. **After dispatch:** Populate per-reviewer sections in the review note with formatted, severity-tagged findings from the raw responses.
4. **No synthesis section** — the `## Synthesis` heading is not written. The main session adds it after reading the reviewer responses.

**Partial dispatch recovery:** If the subagent crashes mid-dispatch, the main session sees a review note with some reviewer sections populated and some empty. Raw JSON files in `{reviews_dir}/raw/` are the ground truth — if a response file exists, the reviewer succeeded regardless of whether the review note was updated. The main session can either: (a) re-spawn the subagent targeting only missing reviewers (pass a `skip_reviewers` list), or (b) proceed with available responses. The operator decides.

This is the same output as today minus the synthesis. The main session reads the note, adds synthesis, and updates the file in place.

### What the subagent returns to the main session

A structured summary (not the full review content — that's in the vault):

```
Peer review dispatch complete.
- Artifact: {artifact_path}
- Mode: {full | diff}
- Reviewers: {N} dispatched, {N} succeeded, {N} failed
- Failed: {list of failed reviewers with error}
- Safety gate: {clean | soft warning (confirmed) | hard denylist (halted)}
- Review note: {reviews_dir}/{date}-{artifact-name}.md
- Raw responses: {reviews_dir}/raw/{date}-{artifact-name}-{reviewer}.json
```

The main session then reads `{reviews_dir}/{date}-{artifact-name}.md` and proceeds to synthesis.

## Subagent Definition

```markdown
# .claude/agents/peer-review-dispatch.md
---
name: peer-review-dispatch
description: >
  Dispatch artifacts to external LLM reviewers and collect structured responses.
  Handles safety gate, prompt construction, concurrent API dispatch, and raw
  response storage. Returns a review note skeleton for the main session to
  synthesize. Spawned by the peer-review skill — not invoked directly.
skills: []
---
```

### Context contract

**MUST load:**
- The artifact file (path passed by main session)
- `_system/docs/peer-review-config.md` (model config, retry policy — prompt template logic stays in main session)
- `~/.config/crumb/.env` (API keys)

**MAY load:**
- Prior review note (path passed by main session, for diff mode and round tracking)
- `_system/docs/peer-review-denylist.md` (if exists, for soft heuristic customer domain check)

**MUST NOT load:**
- Project context, run logs, specs, or any files beyond the artifact and review config
- The peer-review SKILL.md itself (the subagent carries its own procedure)

This is a tight context budget — 2-3 files plus the artifact. The subagent's context is almost entirely the artifact content and API response text.

### Safety gate — subagent/main session handoff

The safety gate (Step 1) runs inside the subagent because it needs the artifact content. But the OVERRIDE decision must come from the operator in the main session. The handoff:

1. Subagent scans artifact against hard denylist
2. If triggered: subagent **halts without dispatching**, returns summary with `safety_gate: hard_denylist (halted)` and the specific matches found
3. Main session shows the user what matched and asks for OVERRIDE
4. If OVERRIDE: main session re-spawns subagent with a `safety_override: true` flag. Subagent logs the override in frontmatter and proceeds.
5. If no override: review cancelled. No vault artifacts written.

Soft heuristics: subagent warns in its return summary. Main session shows warning to user and asks for confirmation before proceeding to synthesis. (The responses are already collected at this point — the warning is about whether to use them, not whether to dispatch.)

## Changes to Existing Skill

The peer-review SKILL.md gets a focused update:

### Steps 0–5 become: "Spawn subagent"

Replace the current Steps 0–5 procedure with:

```markdown
### Steps 0–5: Dispatch (Subagent)

Spawn `peer-review-dispatch` subagent with:
- `artifact_path`: vault-relative path to the artifact
- `review_mode`: full | diff (determined by main session per existing diff mode detection logic)
- `prompt`: fully assembled Layer 2 review body (main session handles template logic)
- `base_ref`: git ref for diff mode (null for full mode)
- `prior_review`: path to prior review note (for round tracking)
- `skip_reviewers`: list of reviewer IDs to skip (for partial dispatch recovery, empty on first run)
- `safety_override`: false (set to true only after explicit operator OVERRIDE)

Wait for subagent return. Check summary:
- If safety_gate halted: show matches to user, ask for OVERRIDE or cancel
- If any reviewers failed: note in conversation, proceed with available responses
- If all reviewers failed: halt, report errors

Read the review note the subagent wrote to vault. Proceed to Step 6.
```

### Steps 6–8 unchanged

The synthesis, presentation, and iteration steps remain exactly as they are today. The only difference is that the main session reads reviewer responses from the vault file instead of having generated them in the same context window.

### Step 8 (Iterate) update

When iterating, the main session spawns a **new** subagent instance for the re-review (diff mode, linking to the prior review note). The subagent increments `review_round` in frontmatter and sets `prior_review` to the previous note's path.

## What Does NOT Change

- **Review note format** — identical frontmatter, identical per-reviewer sections, identical raw JSON storage
- **Peer review config** — `_system/docs/peer-review-config.md` unchanged
- **API dispatch mechanism** — same concurrent Python script constructed at runtime by the executing agent (currently main session, now subagent). The script template is part of the Step 4 procedure, not a standalone file. Same curl calls, same retry policy.
- **Prompt construction** — same 3-layer structure (Layer 1: injection resistance, Layer 2: review body, Layer 3: structured output enforcement). Layer 2 assembly moves to main session; Layers 1 and 3 wrapping stays mechanical in the subagent.
- **Finding ID namespacing** — same OAI-F1, GEM-F1, etc.
- **Synthesis structure** — same 5 sections (consensus, unique, contradictions, action items, declined)
- **Decision authority model** — reviewers gather evidence, Claude synthesizes, operator approves

## Migration

This is backwards-compatible:

1. Create `.claude/agents/peer-review-dispatch.md` with the subagent definition
2. Update `.claude/skills/peer-review/SKILL.md` — replace Steps 0–5 with subagent spawn, keep Steps 6–8
3. The subagent carries the full procedure for Steps 0–5 — **mechanical extraction** from the current SKILL.md, not a rewrite. The implementation work is: cut the Step 0–5 procedure text from SKILL.md, paste into the agent file, adapt parameter sourcing (accept `artifact_path`, `review_mode`, `prompt`, `base_ref` from main session instead of reading from conversation context). The procedure logic, dispatch script template, response parsing, and file I/O patterns are unchanged.
4. First use: the combined M2+M3 peer review for x-feed-intel

No config changes. No new dependencies. No schema changes. The vault output is identical — a downstream consumer reading review notes would see no difference. (Note: review notes are now co-located with their project at `Projects/{project}/reviews/` when a project exists, with `_system/reviews/` as the fallback for non-project reviews.)

## Estimated Effort

Small. The procedure already exists — this is cutting the skill file at the Step 5/6 boundary and putting each half in the right place. The subagent definition is a thin wrapper. The main risks are: (a) getting the safety gate handoff right (subagent halt → main session OVERRIDE → re-spawn), and (b) the write-before-dispatch pattern for crash resilience. Both are new interaction patterns but simple ones.

Iteration re-spawn cost is acknowledged but acceptable — iteration has been rare in practice (0–1 rounds per review), and subagent startup is lightweight (~3 files). If frequency increases, cost data will surface it.

Comparable to one M3 task (XFI-025 or XFI-026 level).

## Resolved Questions

1. **Subagent model selection.** Decision: start with default (same model as main session). Collect cost data over initial uses. Downgrade to Sonnet only if data justifies it — premature optimization risk outweighs cost savings on a low-frequency operation.

2. **Perplexity handling.** Decision: drop from standard rotation. The 4 API-dispatched reviewers provide sufficient coverage. Perplexity remains available as an optional manual add-on — operator submits via web interface and appends findings to the review note outside the subagent pipeline.

3. **Prompt interface.** Decision: main session assembles the final Layer 2 prompt and passes it as a single string. The subagent receives the prompt and wraps it with Layer 1 (injection resistance) and Layer 3 (structured output enforcement) — mechanical, per-reviewer wrappers. This keeps all "what do we want to ask?" judgment in the main session and gives the subagent a simpler contract. The main session handles template selection, custom prompt replacement, and appended focus areas before spawning the subagent.
