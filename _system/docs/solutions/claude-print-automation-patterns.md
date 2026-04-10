---
type: solution
domain: software
status: active
track: pattern
created: 2026-02-22
updated: 2026-04-04
skill_origin: compound
confidence: high
linkage: discovery-only
tags:
  - kb/software-dev
  - claude-code
  - automation
  - dispatch
topics:
  - moc-crumb-operations
---

# Claude `--print` Automation Patterns

Patterns for building reliable orchestration around `claude --print` sessions.
Derived from crumb-tess-bridge Phase 2 live deployment (6 iterations, 4 code
fixes, 2026-02-22). Confirmed independently by both human and system analysis.

## Pattern 1: Runner Owns Deterministic Fields

**Problem:** When a model produces structured output (JSON schema), it reliably
generates *content* (summaries, findings, decisions) but unreliably reproduces
*metadata* (IDs, paths, schema versions, stage numbers). Field names get
paraphrased (`stage` instead of `stage_number`), values get approximated, and
paths get reformatted.

**Solution:** Split responsibility at the content/metadata boundary. The runner
(orchestrator) injects deterministic fields post-output using `setdefault()` —
values it already knows before the stage runs. The model is only responsible for
fields that require judgment.

```python
# Runner injects after reading model output, before validation
runner_defaults = {
    "schema_version": "1.1",
    "dispatch_id": dispatch_id,
    "stage_number": stage_number,
    "stage_id": f"{dispatch_id}-stage-{stage_number}",
    "transcript_path": f"{transcripts_path}/{stage_id}-transcript.md",
}
for key, value in runner_defaults.items():
    stage_output.setdefault(key, value)
```

**Boundary rule:** If the runner knows the value before the stage runs, the
runner owns it. If the value requires model judgment, the model owns it.

**Counterexample:** When the model generates a `stage_id` with semantic meaning
(e.g., `planning`, `research-1`) rather than the dispatch-ID-based format, the
runner's default is correct for validation but loses the semantic signal. If
stage IDs are later used for human-facing display, the model's choice may be
preferable. Currently the runner format wins; revisit if semantic stage naming
becomes a requirement.

## Pattern 2: CLAUDE.md as Durable Instruction Surface

**Problem:** Prompt-only instructions (system prompt, user prompt) are
interpreted loosely by the model. Field names get paraphrased, formats get
approximated, constraints get selectively followed. The prompt can say "use
exact field name `stage_number`" and the model writes `stage`.

**Solution:** Put schema and format requirements in CLAUDE.md — the auto-loaded,
governance-verified instruction file. Every `claude --print` session loads
CLAUDE.md automatically. The prompt can reinforce, but CLAUDE.md is the
backstop.

**What belongs in CLAUDE.md vs prompt:**
- CLAUDE.md: field names, required structure, format constraints, governance
  computation instructions — anything the runner validates strictly
- Prompt: task-specific context, the actual work to do, budget info, stage
  handoff — anything that varies per invocation

**Why this works:** CLAUDE.md is structurally privileged — it loads before the
conversation starts, it's verified by governance, and models treat it as
authoritative configuration rather than conversational suggestion.

**Counterexample:** CLAUDE.md has a line budget (target <200, ceiling 250).
Adding per-operation schema details for every dispatch operation type would
bloat CLAUDE.md past its ceiling. When the number of operation types grows,
the schema should move to a referenced file that `claude --print` loads
explicitly, not CLAUDE.md itself. This pattern works for a small number of
stable schemas, not for a growing registry.

## Pattern 3: Hash-Verify, Canary-Stamp

**Problem:** Governance verification requires the model to reproduce both a
SHA-256 hash (deterministic computation) and a canary string (last N bytes of
a file). Models reliably reproduce the hash but fail on byte-boundary-sensitive
string extraction — off-by-one on boundaries, whitespace normalization,
trailing newline differences.

**Solution:** Verify the computable part (hash), stamp the extractable part
(canary) from the runner's authoritative values. Preserve the model's original
governance output under a forensics key for audit.

```python
model_hash = model_governance.get("governance_hash", "")
if model_hash != expected_governance["governance_hash"]:
    # Real governance failure — CLAUDE.md changed or not loaded
    raise GovernanceFailure(details)

# Hash verified — stamp authoritative canary + fields
stage_output["_model_governance_check"] = model_governance  # forensics
stage_output["governance_check"] = {
    "governance_hash": expected_governance["governance_hash"],
    "governance_canary": expected_governance["governance_canary"],
    "claude_md_loaded": expected_governance["claude_md_loaded"],
    "project_state_read": model_governance.get("project_state_read", False),
}
```

**Generalization:** When verifying model-reproduced values, distinguish between
*computable* values (hashes, checksums — verify strictly) and *extractable*
values (substrings, byte ranges — stamp from source). This applies to any
integrity verification scheme that asks a model to attest to file contents.

**Counterexample:** If the canary's purpose is to detect model-side
manipulation (not just file content verification), then stamping authoritative
values defeats the check. In that threat model, canary mismatch IS the signal.
The hash-verify/canary-stamp pattern assumes the threat is external file
tampering, not model-side evasion of governance.

## Pattern 4: Budget Time for Live Deployment Iteration

**Problem:** Mocked unit tests and integration tests cannot catch prompt-model
contract gaps. The model interprets prompts differently than the test author
expects. Each gap only surfaces when a real model processes a real prompt — and
each fix requires a restart-requeue-wait cycle.

**Solution:** Budget explicit iteration time for first live deployment of any
system that asks a model to produce structured output. This is predictable, not
a failure — the prompt-model contract needs live calibration that mocks can't
provide.

**Expect:** 3-6 iterations on first deployment. Each iteration peels back the
next validation layer (routing → schema → field names → types → governance).
The fix-restart-requeue cycle is the deployment pattern, not a bug.

**Reduce iterations by:**
- Runner-side defaults for deterministic fields (Pattern 1)
- Durable instruction surface for schema (Pattern 2)
- Coercion/tolerance for non-critical type mismatches
- Layered validation that reports all failures at once, not one at a time

**After first deployment:** Subsequent dispatches with the same operation type
typically succeed on first attempt. The iteration cost is per-operation-class,
not per-invocation.

**Counterexample:** If the structured output schema is simple (e.g., a single
status field and a message), the prompt-model contract is unlikely to need live
calibration. This pattern applies to schemas with 5+ required fields, nested
objects, and type-specific conditional requirements — where the combinatorial
surface exceeds what prompt engineering alone can nail on first attempt.

## Evidence

All four patterns derived from crumb-tess-bridge Phase 2 live deployment,
2026-02-22. Six dispatch attempts, four code fixes, independently confirmed by
both human and system analysis (consensus on top 3 patterns).

- **Pattern 1:** Attempts 2-3 (4 missing fields → 3 field name mismatches → fix via `setdefault()`)
- **Pattern 2:** User observation after attempt 5; CLAUDE.md section added, attempt 6 succeeded
- **Pattern 3:** Attempt 5 (hash matched, canary off-by-one; hybrid approach preserved security tests)
- **Pattern 4:** Meta-observation across all 6 attempts; each peeled back exactly one validation layer

Project reference: `Projects/crumb-tess-bridge/progress/run-log.md`, Session 31,
"Phase 2 Live Deployment" section.

## Applicability

These patterns apply to any system that:
- Spawns `claude --print` (or equivalent) for structured work
- Validates the output against a schema
- Needs governance/integrity verification
- Operates unattended (no human in the loop to fix output)

Known future applications: researcher-skill dispatch, new dispatch operation
types (start-task, quick-fix), any multi-agent orchestration using Claude Code.
