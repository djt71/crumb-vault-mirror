---
type: solution
track: pattern
domain: software
status: active
created: 2026-04-21
updated: 2026-04-21
confidence: high
tags:
  - compound
  - llm-integration
  - contract-execution
  - response-parsing
source_projects:
  - tess-v2
source_artifacts:
  - Projects/tess-v2/design/response-harness-analysis.md
  - Projects/tess-v2/design/spec-amendments-harness.md
---

# Lenient Parsing Layer Before Contract Evaluation

## Claim

Between LLM executor output and contract evaluation, a **lenient parsing layer**
should silently recover from common formatting errors. Burning retry budget on
JSON formatting is wasted iterations; retries are precious and should be reserved
for semantic failures. A loop with a 3-iteration retry budget that spends 2
iterations on markdown code-block wrapping has 1 iteration left for actual
reasoning errors.

## Evidence

- **AutoBE function-calling harness:** Documents 7 recurrent recoverable quirks
  in LLM outputs. Achieves convergence across a 10× model-parameter range by
  parsing leniently before validation.
- **Nemotron Cascade 2 at 128K context (TV2-013, 2026-03):** Places tool-call
  answers in `reasoning_content` instead of `content`. Without a lenient
  parser checking both fields, every 128K-context invocation would fail
  parsing despite producing correct answers.
- **Tess v2 contract runner production use (2026-04):** Ships a lenient parser
  between executor output and contract evaluation. Handles the Nemotron quirk
  plus the AutoBE 7. Contract failures now reflect semantic issues, not
  formatting.

## Pattern

### Two classes of parse error

**Recoverable** (fix silently, log the fix):
- Markdown code-block wrapping (`\`\`\`json ... \`\`\``)
- Trailing commas in JSON
- Unclosed brackets (best-effort repair)
- Double-stringification of union types
- Whitespace / newline normalization
- Type coercion for non-critical fields (string `"3"` → int `3`)
- Answer-in-reasoning-field for models with separate reasoning streams

**Non-recoverable** (trigger retry or escalation):
- Missing required fields
- Wrong field names (semantic mismatch, not formatting)
- Content that violates contract constraints
- Truncated output (incomplete response)

### Per-executor quirk profiles

Each LLM accumulates observed parsing quirks during onboarding. The lenient
parser carries a profile per executor and adapts accordingly. Example quirks:

```yaml
profiles:
  nemotron-cascade-2:
    - content_field_fallback: "reasoning_content"  # 128K context
    - strip_think_blocks: true
  kimi-k2.5:
    - strip_reasoning_headers: true
  gpt-5.4:
    - normalize_markdown_wrap: true
```

Profiles are cheap to maintain and pay back the first time a quirk recurs.

## When to Apply

- Any Ralph-loop or contract-runner pattern where retries are budgeted.
- LLM integrations where parse failure would cascade to contract failure.
- Local model integrations (higher formatting variance than frontier models).
- Any system where a semantic retry is expensive enough to protect the budget for.

## When Not to Apply

- When the parse *is* the evaluation (e.g., strict JSON conformance is what
  you're testing). Don't launder formatting away if formatting is the
  contract.
- For truly catastrophic structural failures (truncation, wrong schema entirely).
  These should fail loudly and burn an iteration.

## Design Principle

**Parsing tolerance preserves the retry budget for semantic failures.** Every
recoverable quirk the parser absorbs is an iteration kept available for the
failure modes that actually require the model to reason differently next time.

## Related

- `_system/docs/solutions/behavioral-vs-automated-triggers.md` — adjacent
  pattern on mechanical enforcement over behavioral compliance
- `Projects/tess-v2/design/spec-amendments-harness.md` (Amendment U) —
  original formulation for the tess-v2 contract runner
- `Projects/tess-v2/design/response-harness-analysis.md` — AutoBE analysis
  and the 7 recurring quirks
