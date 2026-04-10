---
type: specification
domain: software
status: active
project: pydantic-ai-adoption
skill_origin: systems-analyst
created: 2026-03-15
updated: 2026-03-15
---

# Pydantic AI Adoption: Specification

**Governed by:** ADR (`design/adr.md`) — architecture decisions, alternatives, risk analysis
**Scope:** First adoption target only (Pydantic Evals for AO decision path verification via Option A — input/output evals, no spans). Subsequent components and span-based evaluation have their own triggers and will be specified separately when triggered.

---

## 1. Problem Statement

Crumb/Tess has no standardized, structured mechanism to verify agent decision-path correctness beyond ad hoc checks. The current eval code (~1,010 lines across three projects) uses binary pass/fail checkers, hardcoded task definitions, and no assertion framework. This pattern recurs: `benchmark.py` (550+ lines in tess-model-architecture), `integration-test.py` (400+ lines), `bbp001-validate.py` (60 lines in batch-book-pipeline).

This spec addresses the immediate need: formalized eval datasets for autonomous-operations (AO) decision paths, using Pydantic Evals if it earns its ceremony budget, pytest if it doesn't. The broader opportunity (standardizing eval patterns across projects) is out of scope — it's evidence that the problem recurs, not a commitment to solve it here.

## 2. Existing Code Inventory

### 2.1 Eval/Testing (pattern evidence — ~1,010 lines across projects)

These files demonstrate the recurring "hand-rolled eval harness" pattern. They are **not replacement targets** for this spec — each belongs to its own project. They establish that a standard framework would have value across the system.

| File | Lines | What It Does | Project Owner |
|------|-------|-------------|---------------|
| `Projects/tess-model-architecture/harness/benchmark.py` | 550+ | Tool-call compliance harness (MC-1 through MC-6 gates). Task dataclasses + checker functions. Binary pass/fail. | tess-model-architecture |
| `Projects/tess-model-architecture/harness/integration-test.py` | 400+ | Latency measurement + behavioral validation across cloud/local/limited modes. 25 prompts per mode. | tess-model-architecture |
| `Projects/batch-book-pipeline/design/bbp001-validate.py` | 60 | Output completeness checks (required section headings, word count). | batch-book-pipeline |

### 2.2 Commodity Code (not being replaced)

| Category | File | Lines | Language | Replacement Fit |
|----------|------|-------|----------|-----------------|
| Token budget | `_openclaw/scripts/daily-attention.sh` | 25 | Bash | **None** — bash stays bash |
| Token budget | `_openclaw/scripts/cron-lib.sh` | 15 | Bash | **None** — bash stays bash |
| Token budget | `_system/scripts/batch-book-pipeline/pipeline.py` | 30 | Python | **Low** — 30 lines, stable, rarely changed |
| Output validation | `_openclaw/scripts/daily-attention.sh` | 80 | Bash+jq | **None** — bash stays bash |
| Output validation | `_system/scripts/batch-book-pipeline/pipeline.py` | 60 | Python | **Low** — regex/YAML parsing, works fine |
| Retry logic | `_system/scripts/batch-book-pipeline/pipeline.py` | 20 | Python | **Low** — standard backoff, stable |
| Retry logic | `_openclaw/scripts/daily-attention.sh` | 40 | Bash | **None** — bash stays bash |
| Usage tracking | `_openclaw/scripts/cron-lib.sh` | 30 | Bash+jq | **None** — bash stays bash |
| Usage tracking | `_openclaw/scripts/daily-attention.sh` | 60 | Bash+SQLite | **None** — bash stays bash |
| Usage tracking | `_system/scripts/batch-book-pipeline/pipeline.py` | 20 | Python | **Low** — JSONL append, trivial |

**Conclusion:** Based on code inventory (~110 lines Python in a single file, stable), the maintenance burden of commodity code appears near-zero. This is treated as sufficient evidence to defer commodity-code replacement unless future experience contradicts it.

*Line counts are approximate, derived from code inventory survey on 2026-03-15.*

### 2.3 AO Decision Paths (the actual test target)

The two decision paths in scope for this spec:

1. **Idempotency predicate** — determines whether a task has already been completed. The class of bug ChatGPT surfaced in AO-004 was a false negative (predicate said "not done" when it was done). Test cases should cover the full confusion matrix: true positive, true negative, false positive, false negative, plus edge cases (partial completion, stale state, concurrent modification, re-run after rollback).

2. **Signal assembly tiered approach** — tags are guaranteed (always applied), domain concepts are priority-filled (applied if budget allows). Test cases should verify: tags always present, domain concepts appear when budget allows, domain concepts omitted when budget exhausted (not randomly dropped).

**Deferred:** Tool-call sequence verification requires span-based evaluation (OTel instrumentation of execution context), which is out of scope for this spec. See §3.3.

## 3. Environment Design

### 3.1 Where the Python Code Lives

New directory: `Projects/pydantic-ai-adoption/evals/`

```
evals/
├── .venv/                     # dedicated venv (not committed)
├── requirements.txt           # pinned: pydantic-evals==X.Y.Z
├── conftest.py                # shared fixtures (vault paths, model config, env vars)
├── datasets/
│   ├── ao_idempotency.yaml    # test cases for idempotency predicate
│   └── ao_signal_assembly.yaml # test cases for signal assembly
├── evaluators/
│   └── custom_evaluators.py   # domain-specific evaluators
└── run_evals.py               # entry point
```

`requirements.txt` only — no `pyproject.toml` for the spike. Add packaging if the eval suite grows beyond a single runner.

### 3.2 Venv and Setup

```bash
cd Projects/pydantic-ai-adoption/evals
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Python version: 3.11+ (Mac Studio has 3.14 via Homebrew).

### 3.3 How It's Invoked

```bash
source Projects/pydantic-ai-adoption/evals/.venv/bin/activate
python3 Projects/pydantic-ai-adoption/evals/run_evals.py
```

**Execution model note:** The ADR (§1.2) says Pydantic AI components are "imported as a library" within the Claude Code context. The eval suite is the exception — it runs as a **standalone Python process** outside Claude Code, calling the Anthropic API directly. This is deliberate: evals must be reproducible, independent of session state, and runnable from Tess automation without a Claude Code session. This divergence from the ADR's general framing is specific to the testing use case and does not set precedent for runtime adoption of other Pydantic AI components.

**Tess automation:** Deferred. The eval suite must be proven manually first. Cron/post-deployment automation is a future task once evals are stable and the per-run cost is understood.

### 3.4 Test Boundary

Evals call AO decision-path logic as **imported Python functions** with test inputs, not as end-to-end model calls. The test boundary:

```
Test input (fixture) → AO decision function (imported) → Decision output → Evaluator assertion
```

This means: the idempotency predicate and signal assembly logic must be extractable as Python callables that accept structured inputs and return structured outputs. If the logic is too tightly coupled to Crumb's session context (can't be imported without the full tool/skill environment), that is a finding from the empirical spike — not something to discover during dataset creation.

**Test modes:**
- **Primary (deterministic):** Extracted pure logic with fixture inputs. No LLM calls. Cheap, fast, reproducible.
- **Secondary (live model):** Full model calls for cases where the decision depends on LLM reasoning. Uses Haiku for development iterations, Sonnet for final validation. Non-deterministic — use `temperature=0` where supported.
- **Optional (replay):** Captured model transcripts replayed through evaluators. Deterministic re-evaluation of prior outputs without API cost.

Deterministic evaluators are the default. LLM-as-judge evaluators are used only when deterministic evaluation is impossible for a given test case.

### 3.5 Dataset Schema

Each test case in a dataset YAML follows this structure:

```yaml
- id: idem-001
  description: "True positive — task fully completed, predicate correctly returns done"
  input:
    vault_state:
      task_file: "fixtures/ao-task-complete.yaml"
      run_log_entry: "fixtures/run-log-complete.md"
    task_id: "AO-007"
  expected:
    decision: true
    rationale_contains: ["completed", "run-log entry exists"]
  mode: deterministic  # or "live_model"
  tags: [confusion-matrix, true-positive]
```

Fields: `id` (unique), `description` (human-readable), `input` (structured — vault state, task context), `expected` (decision + optional rationale signals), `mode` (deterministic or live_model), `tags` (for filtering/grouping).

### 3.6 Config and Secrets

Environment variables (set in shell or `.env` file, not committed):
- `ANTHROPIC_API_KEY` — required for live-model test mode
- `EVAL_MODEL` — model for live-model tests (default: `claude-haiku-4-5-20251001` for dev, override to Sonnet for validation)
- `EVAL_OUTPUT_DIR` — where results are written (default: `progress/eval-results/`)
- `EVAL_MODE` — `deterministic` (default), `live`, or `replay`

### 3.7 Results Artifact Format

Each run produces a JSONL file at `{EVAL_OUTPUT_DIR}/{YYYY-MM-DD}-{run-id}.jsonl`:

```json
{"run_id": "...", "timestamp": "...", "git_commit": "...", "model": "...", "pydantic_evals_version": "...", "python_version": "...", "mode": "deterministic"}
{"case_id": "idem-001", "dataset": "ao_idempotency", "passed": true, "expected": "true", "actual": "true", "duration_ms": 12}
{"case_id": "idem-002", "dataset": "ao_idempotency", "passed": false, "expected": "false", "actual": "true", "duration_ms": 15, "error": "false negative on partial completion"}
{"summary": {"total": 18, "passed": 17, "failed": 1, "datasets": {"ao_idempotency": {"total": 10, "passed": 9}, "ao_signal_assembly": {"total": 8, "passed": 8}}}}
```

## 4. Scope Boundaries

**In scope:**
- Pydantic Evals adoption for AO decision path testing (Option A only — input/output evals)
- Eval dataset creation (2 datasets: idempotency, signal assembly)
- Custom evaluators for domain-specific assertions
- Environment setup (venv, requirements.txt, directory structure)
- Empirical spike (install, write one test case, confirm it runs)

**Out of scope:**
- Span-based evaluation / Option B (deferred to future spec — see §3.3 deferral note below)
- Tool-call sequence verification (requires spans)
- Replacing benchmark.py or other projects' eval code
- Replacing commodity code in pipeline.py
- MCP client adoption, Cloudflare Sandbox, production Pydantic AI agents
- Tess automation of eval runs (deferred until evals proven manually)

**Option B deferral:** Span-based evaluation (wrapping AO decision paths as Pydantic AI agents, OTel instrumentation, tool-call sequence assertions) is deferred to a future spec. Revisit only if Option A reveals specific gaps in decision-path coverage that require tool-call sequence verification.

## 5. Acceptance Criteria

### 5.1 Empirical Spike (gate — must pass before proceeding)

- [ ] Dedicated venv created, `pip install pydantic-evals` succeeds
- [ ] `pip audit` run on dependency tree, no critical vulnerabilities
- [ ] One test case (idempotency predicate, deterministic mode) written as a Pydantic Evals dataset + evaluator
- [ ] `python3 run_evals.py` executes and produces a pass/fail result with structured output
- [ ] Record elapsed setup time, lines of code written, and blockers encountered
- [ ] If AO decision logic cannot be cleanly imported as Python callable: document why, treat as a finding

**Stop condition:** If the empirical spike takes more than 1 full day including environment setup, treat that as a signal that adoption cost exceeds value for this scope and fall back to pytest.

### 5.2 Adoption Checkpoint (gate — go/no-go before dataset build)

30 minutes comparing pydantic-evals to what pytest + custom assertions would require.

**Pass/fail rule:** If pytest + custom assertions can express the same AO test cases with comparable or fewer lines of code and no missing capabilities that matter for this scope, stop and use pytest.

**Output documented in run-log:**
- Lines of code comparison (pydantic-evals vs estimated pytest equivalent)
- Capabilities present/absent in each approach (dataset management, evaluator composition, result reporting)
- Explicit go/no-go decision with rationale

### 5.3 First Adoption (definition of "done")

- [ ] 2 eval datasets created (idempotency, signal assembly)
- [ ] Idempotency dataset: 8-10 test cases covering full confusion matrix (TP, TN, FP, FN) plus edge cases (partial completion, stale state, concurrent modification, re-run after rollback)
- [ ] Signal assembly dataset: 5+ test cases
- [ ] Custom evaluators written for domain-specific assertions
- [ ] All deterministic tests pass on AO implementation at pinned commit hash
- [ ] At least one test deliberately fails on a known-bad input (e.g., AO-004 reproducer with expected failure mode documented)
- [ ] Live-model tests (if any): expected flakiness tolerance documented, `temperature=0` used
- [ ] Eval suite runnable via single command from activated venv
- [ ] Results saved as JSONL to `progress/eval-results/` (format per §3.7)
- [ ] Run-log entry documenting: adoption outcome, actual dependency cost, checkpoint comparison, per-run API cost

## 6. V2 Decision Gate

Per ADR implementation sequence step 1:

- **If Pydantic AI V2 ships before the empirical spike:** Adopt V2 directly. Review migration guide for Evals-specific changes first.
- **If V2 doesn't ship within 4 weeks of spike start:** Adopt V1, pin to latest stable (v1.68.x as of 2026-03-15 per PyPI; verify at spike time). Budget migration pass when V2 lands.
- **Decision factors beyond calendar:** Migration surface, AO testing gap urgency, V2 ETA confidence. Check https://github.com/pydantic/pydantic-ai/releases for current status.

## 7. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| AO decision paths too tightly coupled to Crumb to extract as Python callables | Medium | High | Spike tests extraction first (§5.1). If extraction fails, that's a finding — fall back to pytest with looser integration. |
| V2 breaks Evals API | Low | Medium | Evals appears stable across V1 releases (based on changelog review, 2026-03-15). Pin version. |
| 25-package dependency tree introduces vulnerability | Low | High | `pip audit` in spike (§5.1). Version pinning. Exit strategy to pytest. Dep tree verified 2026-03-15 — see ADR §1.5. |
| Adoption ceremony exceeds value | Medium | Medium | Checkpoint with falsifiable pass/fail rule (§5.2). 1-day stop condition on spike (§5.1). |
| Per-run API cost | Medium | Low-Medium | Deterministic mode is the default (no API cost). Live-model mode: Haiku for dev (~$0.05/run), Sonnet for validation (~$0.50-2.00/run). Soft ceiling: $5/day during development. |

## 8. Implementation Sequence

**Estimated effort:** Spike ~0.5 day, checkpoint ~0.5 day, datasets + evaluators ~1-2 days. Total: 2-3 days if everything goes smoothly.

1. **V2 gate** — check Pydantic AI release status at https://github.com/pydantic/pydantic-ai/releases
2. **Empirical spike** — venv, install, extract one AO decision path, write one test case, verify (§5.1). Stop condition: 1 day max.
3. **Adoption checkpoint** — 30-minute pytest comparison with falsifiable pass/fail rule (§5.2). Go/no-go documented in run-log.
4. **Dataset creation** — 2 datasets (idempotency 8-10 cases, signal assembly 5+)
5. **Evaluator development** — custom evaluators for domain assertions
6. **Integration** — single-command runner, JSONL results to vault
7. **Retrospective** — run-log entry with actual costs, effort, and comparison to estimates
