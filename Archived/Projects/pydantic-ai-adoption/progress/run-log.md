---
type: run-log
project: pydantic-ai-adoption
status: active
created: 2026-03-15
updated: 2026-03-15
---

# Run Log — pydantic-ai-adoption

## 2026-03-15 — Project creation

**Context:** Research session produced two paired artifacts — a Pydantic AI platform analysis (v1.68.0) and an Architecture Decision Record for Crumb/Tess infrastructure evolution. Both went through internal review (Crumb critique), critic skill, and full 4-model peer review (GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast). All review findings (9 action items) were applied to the documents before project creation.

**Key decisions (from ADR):**
- Local core (Tess, Crumb, vault, Telegram) stays bespoke — no framework owns orchestration
- Pydantic AI adopted as library, not framework — component-level, not wholesale
- Pydantic Evals is first adoption target, scoped to AO decision path verification
- V2 timing gate: wait for V2 (expected April 2026) if it ships within 4 weeks, otherwise adopt V1 pinned
- Empirical spike required before committing (install, write test case, verify OTel span compatibility)
- MCP and Cloudflare Sandbox deferred as directional hypotheses, not decisions

**Key findings from reviews:**
- pydantic-evals pulls in 25 packages including pydantic-ai-slim, logfire-api, opentelemetry-api (not lightweight standalone)
- Span-based evaluation requires OTel instrumentation — compatibility with Claude Code tool calls unverified
- Ecosystem coherence (shared types, unified deps) is the rationale for Pydantic AI as default source, not best-in-class per component
- Modal identified as lower-ceremony alternative to Cloudflare Sandbox for burst compute
- FastMCP wraps the same implementation Pydantic AI uses (FastMCPToolset)

**Artifacts created:**
- `design/adr.md` (Architecture Decision Record, moved from _inbox/)
- `design/pydantic-ai-analysis.md` (platform analysis, moved from _inbox/)
- `reviews/2026-03-15-critic-infrastructure-evolution.md` (critic review of ADR)
- `reviews/2026-03-15-infrastructure-evolution-adr.md` (4-model peer review of ADR with synthesis)

**Phase:** SPECIFY — ADR is the decision record, not the specification.

## 2026-03-15 — Specification written + reviewed

**Context:** Code inventory survey identified ~1,010 lines of hand-rolled eval code across 3 projects (pattern evidence) and ~110 lines of stable commodity Python code (near-zero maintenance burden, not being replaced). Specification written grounding the ADR decisions in concrete implementation details.

**Key spec decisions:**
- Option A only (input/output evals, no spans). Option B (span-based) deferred to future spec.
- 2 datasets: idempotency (8-10 cases, full confusion matrix) + signal assembly (5+ cases). Tool-sequence dataset dropped (requires spans).
- Test boundary: AO logic imported as Python callables with fixture inputs, not end-to-end model calls.
- 3 test modes: deterministic (default, no API cost), live-model (Haiku dev / Sonnet validation), replay.
- Falsifiable adoption checkpoint: if pytest can express same tests with comparable LOC, stop and use pytest.
- 1-day stop condition on empirical spike.
- Effort estimate: 2-3 days total.

**Reviews:**
- Critic review: not run on spec (already had 2 rounds on ADR)
- Internal peer review: 3/4 reviewers responded (GPT-5.4, Gemini 3.1 Pro, Grok 4.1 Fast; DeepSeek timed out). Consensus: Option A/tool-sequence contradiction, benchmark.py narrative, execution targets undefined, acceptance criteria reproducibility.
- External peer review (Perplexity + ChatGPT via claude.ai): converged on execution model contradiction (M1), test boundary (M4), falsifiable checkpoint (M3), venv setup (M5), Option B deferral (M6).
- All findings applied in single revision pass.

**Artifacts:**
- `design/specification.md` (specification — implementation-ready)
- `reviews/2026-03-15-specification.md` (3-model peer review with synthesis)

**Model routing:** All work on Opus. Peer review dispatch delegated to subagents (mechanical). No Sonnet delegation this session — spec writing and review synthesis required judgment-level work throughout.

**Compound reflection:** The code inventory survey (§2.2) conclusively answered the ADR's §1.6 measurement gate: commodity code maintenance burden is near-zero. This eliminates UsageLimits, structured output validation, and retry logic from the adoption roadmap unless a future Python agent creates volume that justifies unified infrastructure. The "measure before adopting" gate worked exactly as designed — it prevented unnecessary adoption.

**Phase:** SPECIFY complete. Next: phase transition to PLAN (task breakdown of implementation sequence §8).

## 2026-03-16 — Spike, checkpoint, pivot to pytest

**Context:** Full execution of M1 (empirical spike) and M2 (adoption checkpoint) in a single session. Transitioned SPECIFY → PLAN → TASK, then executed PAA-001 through PAA-008.

### M1: Empirical Spike Results

**PAA-001 — V2 gate:** No V2 release. Latest is v1.68.0 (Mar 12, 2026). No V2 signals in changelog. Decision: adopt V1 pinned to v1.68.0 per spec §6.

**PAA-002 — Environment:** venv created (Python 3.14.3), pydantic-evals 1.68.0 installed. pip-audit clean (no vulnerabilities). Note: pydantic-evals pulls pydantic-ai-slim + pydantic-graph + logfire-api + opentelemetry stack — 25 transitive deps as predicted by reviewers.

**PAA-003 — AO extraction:** Key finding — AO decision logic is **Bash + SQL**, not Python. The idempotency predicate is a `NOT EXISTS` SQL query against SQLite (`attention-correlate.sh` lines 48-66). The correlation decision tree is a Bash case/if chain (lines 86-204). Extracted as Python reimplementations in `evals/ao_predicates.py` (~130 LOC):
- `get_uncorrelated_items(db_path)` — the idempotency predicate (SQL query)
- `classify_item(item, git_commit_count, mtime_in_window)` — the correlation decision tree
- Extraction was clean — the SQL query ports directly, the decision tree is a faithful reimplementation
- Limitation: we're testing a Python port, not the production Bash code. Bash-specific bugs (date parsing, IFS splitting) won't be caught.

**PAA-004 — First test:** 7 test cases via pydantic-evals, all passing. Rich table output and JSONL results produced. One API mismatch hit (`ReportCase.duration` → `task_duration`, `scores` → `assertions`) — fixed in <5 min.

**Spike metrics:**
- Setup time: ~15 minutes
- LOC written: ~330 (ao_predicates.py + evaluators + runner + conftest)
- Blockers: 1 API mismatch (minor), 0 extraction blockers
- 1-day stop condition: well within budget (~30 min total)

### M2: Adoption Checkpoint — NO-GO on pydantic-evals

**30-minute comparison result:**

| Dimension | pydantic-evals | pytest |
|---|---|---|
| LOC (excluding ao_predicates.py) | ~200 | ~70 |
| Dependencies | 25 packages | 1 package |
| Dataset management | Built-in YAML serialization | Manual fixtures/parametrize |
| Result reporting | Rich tables, JSONL export | Standard pytest output, junit-xml |
| Evaluator composition | Reusable evaluator classes | Assert statements |

**Decision: NO-GO.** Spec §5.2 falsifiable rule triggered — pytest expresses the same tests in fewer LOC with no missing capabilities at this scale. Pydantic-evals advantages (YAML datasets, evaluator composition, rich reporting) don't justify 25 transitive dependencies for 7-13 test cases. Break-even would be ~50+ cases across projects.

### Pivot to pytest (PAA-007, PAA-008)

Rewrote test suite as pytest. Expanded from 7 to 13 test cases:
- `test_correlation.py` — 7 tests: TP (git), TP (mtime), TN (no signal), pathless, synthetic object_id, git priority, empty source_path
- `test_idempotency.py` — 6 tests: no action → appears, git correlation → excluded, mtime → excluded, non-correlation action → still appears, failed cycle → excluded, partial correlation across items

All 13 pass in 0.03s. Zero API cost (deterministic mode only).

**Artifacts:**
- `evals/ao_predicates.py` — extracted AO decision logic
- `evals/conftest.py` — test DB fixture
- `evals/test_correlation.py` — classify_item tests
- `evals/test_idempotency.py` — idempotency predicate tests
- `evals/requirements.txt` — pytest==8.3.5 (previously pydantic-evals)
- `design/action-plan.md`, `design/tasks.md`, `design/action-plan-summary.md`
- `progress/eval-results/2026-03-16-814ace6b.jsonl` — pydantic-evals spike results (historical)

**Remaining:** PAA-009 (signal assembly tests), PAA-010 (retrospective).

**Compound reflection:** The falsifiable checkpoint (spec §5.2) worked exactly as designed — it prevented adopting a 25-dependency framework for a 13-test suite. This is the second instance of "measure before adopting" working in this project (first: commodity code inventory in §2.2). The pattern: set a concrete pass/fail rule before the experiment, run the experiment, apply the rule mechanically. Both times the answer was "don't adopt." The Ceremony Budget Principle is earning its keep.

**Model routing:** All work on Opus. Subagent used for AO code exploration (Explore type). No Sonnet delegation.

**Phase:** TASK. Next: PAA-009 (signal assembly tests).

### PAA-009: Signal assembly tests

Added `test_signal_assembly.py` with 18 tests across three classes:
- **Tier 1 tag validation** (9 tests): valid domain/action_class pass through, invalid fall back to 'software'/'review' with warnings, both-invalid produces two warnings, all 8 canonical domains accepted, all 6 canonical action_classes accepted, empty string falls back, case-sensitive matching
- **Tier 2 urgency enforcement** (7 tests): no prior → accept new, no new → None, upgrade allowed, same level allowed, downgrade blocked with warning, critical→medium blocked, medium→critical allowed
- **Urgency rank** (2 tests): ordering correctness, unknown returns 0

Extracted predicates added to `ao_predicates.py`: `validate_tags()`, `enforce_urgency()`, `urgency_rank()`.

### PAA-010: Retrospective

**Adoption outcome:** pydantic-evals NO-GO. pytest adopted instead. The falsifiable checkpoint worked — 25-dep framework wasn't justified for 31 deterministic tests.

**Actual effort vs estimate:**
- Spec estimated 2-3 days. Actual: ~1 hour for full suite (spike + pivot + all datasets)
- The estimate assumed pydantic-evals would pass the checkpoint and require YAML dataset files + custom evaluator framework. Pytest shortcut eliminated that overhead.
- Extraction was easier than anticipated — the Bash→Python port was mechanical, no coupling issues

**Final test suite:**
- 31 tests across 3 files, all deterministic, 0.04s total runtime, zero API cost
- `test_correlation.py` — 7 tests (classify_item decision tree)
- `test_idempotency.py` — 6 tests (NOT EXISTS query, idempotency guarantee)
- `test_signal_assembly.py` — 18 tests (tag validation, urgency enforcement)

**Dependencies:** pytest only (1 package vs pydantic-evals' 25)

**What the tests cover vs don't cover:**
- Covered: Python reimplementations of decision logic — correct behavior of the algorithms
- Not covered: Bash-specific bugs (date parsing, IFS, sed escaping), end-to-end SQLite integration from Bash, token budget truncation (context management, not a pure function)

**Compound reflection:** This project validated two principles in rapid succession. (1) The Ceremony Budget Principle blocked a 25-dep adoption for a 31-test suite — measure-before-adopting worked twice (commodity code inventory + checkpoint). (2) Bash→Python extraction was surprisingly clean because the AO code already separated concerns well (SQL queries are logic, Bash is glue). Well-structured Bash is as extractable as well-structured Python.

**Phase:** All tasks DONE. Project ready for close.
