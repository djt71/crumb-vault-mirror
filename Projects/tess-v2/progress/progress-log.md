---
project: tess-v2
type: progress-log
created: 2026-03-28
updated: 2026-04-01
---

# tess-v2 — Progress Log

## 2026-03-28 — Project Created
- Research spike reviewed by Crumb, 7 findings incorporated
- 2 architectural decisions recorded (vault authority, parallel operation)
- Entering SPECIFY phase

## 2026-03-28 — SPECIFY → PLAN
- Specification complete at r2: 9 ADs, 18 sections, 20 tasks across 4 phases
- Two peer review rounds (9 external reviewers), all must-fix applied
- Key design inputs: conversation analysis (contract execution, Ralph loops), local model eval protocol (benchmark harness)
- 9 Tier-2 items from peer review carry forward to PLAN

## 2026-03-28 — PLAN Phase Complete
- Action plan r2: 46 tasks across 7 milestones (foundation, platform eval, LLM eval, integration gate, architecture, implementation+migration, cutover)
- Automated peer review (4 reviewers): 8 must-fix + 10 should-fix applied
- External peer review (5 reviewers): 18 items applied across 3 tiers
- Key structural additions: integration test bridge, scaffold→implementation expansion (TV2-031a-d), TV2-021 split for parallelism, scenario walkthroughs, branch-specific success criteria, runtime failover design
- Ready for PLAN→TASK transition

## 2026-03-28 — PLAN → TASK
- Operator approved action plan r2, phase advanced to TASK
- Entry points: TV2-001 (migration inventory), TV2-002 (build llama.cpp) — independent, can run in parallel

## 2026-03-28 — Phase 0 Complete
- TV2-001: 28 services inventoried, 2 new migration tasks added (TV2-043 Scout, TV2-044 brainstorm → 48 total)
- TV2-002: llama.cpp built from source (Metal GPU, M3 Ultra), Qwen3.5 27B Q4_K_M verified with tool-calling
- TV2-003: Benchmark harness operational (throughput + quality + SQLite scorecard)
- TV2-004: 21 prompts authored, validated end-to-end. Key finding: guardrail scores 0/3 on Qwen3.5 Q4_K_M — model executes dangerous requests
- 5 remaining GGUF downloads pending for Phase 2 benchmarks
- Ready for Phase 1 (Hermes) + Phase 2 (LLM eval) in parallel

## 2026-03-28 — Phase 1 Entry: TV2-005
- Hermes Agent v0.4.0 installed, Telegram + local LLM connected
- A1 (local LLM connectivity) validated, A7 (personality transfer) partially validated
- Both services persistent as LaunchAgents (llama-server + hermes gateway)
- Next: TV2-006 (11-criteria Hermes evaluation)

## 2026-03-28 — Phase 1+2 Complete
- TV2-006: Hermes evaluation 3.55/5 (passes ≥3.5 threshold). Criterion 11 (Ralph loops) reclassified — external by design
- TV2-010/011: All 6 model candidates benchmarked. Guardrails 0/3 across all models (scale-class limitation)
- TV2-015: Single model decision — Nemotron Cascade 2 30B-A3B Q4_K_M
- TV2-016: Conditional GO — Nemotron Tier 1+2, cloud escalation for Tier 3

## 2026-03-30 — Pre-Phase 3 Integration
- TV2-041: Joint Hermes + Nemotron integration test PASS
- Bridge PoC: `claude --print` dispatch pattern validated ($0.10-0.15/dispatch)
- Hermes v0.4.0 → v0.6.0 upgrade (cron persistence fix, provider chains, MCP server mode)

## 2026-03-31 — Nemotron GO + Kimi Soak Restart
- TV2-007: Nemotron soak 71h PASS (100% load success, memory plateauing 31.4/96GB)
- Kimi K2.5 soak restarted on v0.6.0 (cron persistence, think-block, vault-check fixes)

## 2026-04-01 — Hermes GO + Phase 3 Complete
- TV2-008: Hermes GO — operator approved ("Hermes is a wholehearted GO")
- Think-block fix PR submitted (NousResearch/hermes-agent#4467)
- Phase 3 Architecture Design: 16/16 tasks done across 2 sessions
- 16 design artifacts, 3 peer-reviewed (contract-schema, staging-promotion, ralph-loop)
- 15 must-fix items applied, 26 should-fix logged for implementation follow-up
- 9 architectural decisions total (AD-001 through AD-012)

## 2026-04-01 — TASK → IMPLEMENT
- Phase transition gate executed
- Phase 3 outputs: 16 design docs covering contract lifecycle, escalation, staging, observability, credentials, cost, fairness, and operational policies
- Entry points: TV2-031a (external repo init), then TV2-031b/c/d (contract runner, staging engine, dispatch validator)

## 2026-04-01 — Scaffold + Live Tests
- TV2-031a-d complete: external repo (GitHub: djt71/tess-v2), contract runner, staging engine, dispatch validator
- Code review: 3 segments × 2 reviewers, 24 fixes applied (security: shell injection, path traversal, GLOB injection)
- 3 executors: ShellExecutor (Tier 0, mechanical), NemotronExecutor (Tier 1), ClaudeCodeExecutor (Tier 3)
- CLI: `python -m tess run <contract.yaml>`
- 5 production contracts, 4/5 live-tested STAGED on iteration 1
- 326 tests passing
- Next: LaunchAgent scheduling + 48h parallel run (TV2-032/033)
