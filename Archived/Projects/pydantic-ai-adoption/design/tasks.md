---
type: tasks
domain: software
status: active
project: pydantic-ai-adoption
skill_origin: action-architect
created: 2026-03-16
updated: 2026-03-16
---

# Tasks — pydantic-ai-adoption

## M1: Empirical Spike

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| PAA-001 | V2 release gate check | DONE | — | low | Pydantic AI release page checked; V2 status documented; version decision recorded (adopt V2 or pin V1) |
| PAA-002 | Environment setup — venv, directory structure, requirements.txt | DONE | PAA-001 | low | `evals/` directory created per spec §3.1; venv created; pydantic-evals installed; `pip audit` shows no critical vulnerabilities |
| PAA-003 | Extract AO idempotency predicate as importable Python callable | DONE | PAA-002 | high | Idempotency predicate importable from `evals/` with fixture inputs; accepts structured input, returns structured output; no dependency on Crumb session context |
| PAA-004 | Write first test case — idempotency true-positive, deterministic mode | DONE | PAA-003 | medium | One test case written and passing via pydantic-evals; structured output verified |
| PAA-005 | Spike retrospective — record findings | DONE | PAA-004 | low | Run-log entry documents: elapsed setup time, LOC written, blockers encountered, extraction difficulty assessment; 1-day stop condition evaluated |

## M2: Adoption Checkpoint

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| PAA-006 | Adoption checkpoint — pydantic-evals vs pytest comparison | DONE | PAA-005 | medium | 30-minute timeboxed comparison completed; LOC comparison documented; capability matrix documented; explicit no-go decision — pivot to pytest |

## M3: Pytest Test Suite (pivoted from pydantic-evals)

*PAA-006 outcome: no-go on pydantic-evals. Pytest is simpler for this scale.*

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| PAA-007 | Idempotency test suite — full confusion matrix + edge cases | DONE | PAA-006 | low | 6 tests in `test_idempotency.py` covering: item appears when no action, excluded after git/mtime correlation, non-correlation action doesn't exclude, failed cycles excluded, partial correlation across multiple items |
| PAA-008 | Correlation classification test suite — decision tree coverage | DONE | PAA-006 | low | 7 tests in `test_correlation.py` covering: TP (git), TP (mtime), TN (no signal), pathless uncorrelated, synthetic object_id, git priority over mtime, empty source_path |
| PAA-009 | Signal assembly test suite — tiered approach coverage | DONE | PAA-008 | low | 18 tests in `test_signal_assembly.py`: Tier 1 (9 tests — valid/invalid domain + action_class, all canonical values, empty, case sensitivity), Tier 2 (7 tests — urgency enforcement: upgrade/downgrade/same/missing), rank ordering (2 tests) |
| PAA-010 | Retrospective — costs, effort, estimate comparison | DONE | PAA-009 | low | Run-log entry documents: adoption outcome, actual effort vs estimate, pytest vs pydantic-evals decision rationale |
