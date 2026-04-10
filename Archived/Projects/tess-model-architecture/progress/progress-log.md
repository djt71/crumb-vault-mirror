---
type: progress-log
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-23
---

# Tess Model Architecture — Progress Log

## 2026-02-22

- Project created, entering SPECIFY phase
- Research thread relocated from openclaw-colocation (2 rounds peer review, 5 models)
- Prior art: model comparison, personality-first tiering, design contracts, risk register
- Design Revision 1 (local-first) proposed and withdrawn; cost analysis completed
- Design Revision 2 restores cloud-primary; Limited Mode elevated to design requirement
- Routing research: two-agent split (`tess-voice` + `tess-mechanic`) identified as recommended implementation
- Prompt caching research: cache mechanics documented, heartbeat TTL problem solved by two-agent split
- Specification written (22 facts, 7 assumptions, 13 unknowns, 14 risks, 12 tasks)
- Specification summary written
- SPECIFY phase deliverables complete; peer review on hold per operator request
- Peer review completed: 5 reviewers (4 automated + 1 operator-conducted Perplexity)
- 6 must-fix findings applied as surgical edits (delegation fallback, state sync, TMA-010 split, MC-6 hardening, vendor dependency, architecture invalidation gate)
- 7 should-fix + 9 deferred items logged for PLAN phase consideration
- SPECIFY → PLAN phase transition completed
- Action plan written: 3 milestones, 13 tasks, dual critical path converging on TMA-008
- Peer review completed: 5 reviewers (4 automated + 1 operator-conducted Perplexity)
- 8 must-fix + 6 should-fix findings applied (TMA-010a parallelized, TMA-002 AC tightened, TMA-006 thresholds defined, Milestone 1 gate expanded to 5 conditions, TMA-007 split into build/execute, Milestone 2 exit gate added)
- Task count: 14 (TMA-001 through TMA-012, TMA-007 split into 007a/007b). 7 immediate starts.
- PLAN → TASK phase transition completed
- TASK phase: 4 writing tasks completed (TMA-001 routing spec, TMA-003 design contracts, TMA-004 Limited Mode protocol, TMA-012 environment pinning)
- Routing spec: 28 pass/fail scenarios, 9-dimension criteria table, test execution protocol
- Limited Mode: 5-layer defense-in-depth enforcement, tool allowlist, auto-recovery
- Design contracts: self-contained evaluation framework for future model swaps
- Environment pinning: Ollama not yet installed, baseline openclaw.json snapshot pending
- 4/14 tasks done. Remaining immediate starts require Ollama installation.
- Ollama installed (0.16.3), qwen3-coder:30b pulled (18GB, Q4_K_M)
- Baseline openclaw.json snapshot captured (SHA-256: 6fd1afa3...c864f25)
- TMA-002 (routing PoC) completed: 30 scenarios tested, two-agent split confirmed
- Critical finding: `model.fallbacks` does NOT trigger cross-provider failover for provider-down (connection refused). Retries same provider 4x then fails. Invalidates TMA-004 §3.1 automatic failover assumption.
- Limited Mode mechanism verdicts: conditional append (4a), per-agent tools.byProvider (4b), external health-check cron (4c)
- Inter-agent delegation unavailable in v2026.2.17 — direct Ollama call is delegation mechanism
- Operator decision: voice model Sonnet 4.5 (not Haiku). Cost ~$22.50/mo with caching.
- Ollama provider needs `apiKey: "not-needed"` for auth resolution
- Test config deployed and operational — Tess runs on Sonnet (voice) + Ollama (mechanic)
- 5/14 tasks done. Next: TMA-005 (memory budget), TMA-006 (persona eval), TMA-010a (API probe).
- TMA-005 (memory budget) completed: 21.3 GB peak RSS at 64K context, 51+ GB available, zero swap. q4_0/q8_0 identical. 80B viable (~21 GB headroom). No thermal throttling.
- TMA-010a (API caching probe) completed: `cache_control` passthrough fully supported natively (pi-ai v0.53.0). Default 5-min TTL with API key auth, no config needed. Cost model validated.
- Spec updated: A5, A7 confirmed; U2, U13 resolved; R14 eliminated.
- 7/14 tasks done. Next: TMA-006 (persona eval), TMA-007a (harness build).
- TMA-006 (persona eval) completed: 24 test cases per model, 48 total responses scored.
- Key finding: Haiku 4.5 outperforms Sonnet 4.5 on ambiguity handling (PC-3: 100% vs 71%). Voice fidelity, tone-shift, and second register equivalent (100% both models).
- Operator decision: voice model switched from Sonnet to Haiku. $22.50→$8.70/mo. Reverses TMA-002 decision based on evidence.
- Spec A2 confirmed. Routing spec, design contracts updated.
- 8/14 tasks done. Next: TMA-007a (harness build), TMA-011 (prompt optimization, unblocked by 006).
- TMA-007a (harness build) completed: 10 tool-call tasks, 3 long-context tasks, 4 MC-6 adversarial tests. Single-file Python harness, stdlib only. Validated: all definitions, generators, Ollama connectivity, smoke test.
- TMA-007b (harness execution) completed on Q4_K_M: MC-1/MC-2/MC-3 10/10, long-context 3/3, MC-6 2/4.
- MC-6 finding: model complies with format constraints (exact echo) but fails reasoning constraints (reuses expired tokens, self-generates tokens when none provided). Confirms bridge enforcement is mandatory.
- Thinking mode finding: qwen3-coder's reasoning mode exhausts generation budget on analytical tasks over large JSON. Added `/no_think` to mechanic system prompt.
- Q5_K unavailable on Ollama registry — only Q4_K_M published for full 30B. Deferred.
- Model family: `qwen3moe` (Mixture of Experts, 30.5B total params).
- Sustained 30-min thermal run: 4,234 iterations, 100% success, 299–347ms latency, no throttling (+39ms drift).
- 10/14 tasks done. Next: TMA-011 (prompt optimization). TMA-008 blocked by 011.
- TMA-011 (prompt optimization) completed: SOUL.md + IDENTITY.md compressed from ~3,000 to 1,090 tokens (64% reduction, API-measured).
- Zero degradation: PC-1 11/11, PC-2 8/8, PC-3 7/7, PT-4 3/3 — all match uncompressed baseline on Haiku 4.5.
- tess-mechanic minimal identity: ~190 tokens, MC-6 embedded, `/no_think` appended.
- Removed: calibration anchors, config sliders, redundant IDENTITY.md sections, extended metaphors. Preserved: all Core Truths, Boundaries, Voice, Response Patterns, Serious Mode.
- 11/14 tasks done. TMA-008 (production config) now fully unblocked. TMA-009 blocked by 008. TMA-010b blocked by 009.
- TMA-008 (production config) completed: two-agent config deployed and smoke-tested.
- Custom model `tess-mechanic:30b` created (Modelfile: `num_ctx 65536`, base `qwen3-coder:30b`).
- Voice → Haiku 4.5 confirmed in production (2 Telegram messages, 1.6–2.0s latency, no errors).
- Limited Mode tool restriction: `tools.byProvider.ollama.profile: "minimal"` on voice agent.
- Env vars: `OLLAMA_KEEP_ALIVE=-1`, `OLLAMA_KV_CACHE_TYPE=q4_0`.
- Config hash: `bc490149...b821f6c`.
- 12/14 tasks done. TMA-009 (integration test) now unblocked. TMA-010b blocked by 009.
- TMA-009 (integration test) completed: 3 test suites, all AC criteria satisfied.
- Cloud latency: 25/25 OK, p95=3,823ms (PASS <10s), compressed prompt (1,090 tokens).
- Local latency: 25/25 tool calls, 100% correct tool selection, p95=834ms.
- Limited Mode: 8/8 behavioral pass, 1 tool violation (`web_search`) confirms gateway enforcement mandatory.
- Defense-in-depth confirmed: model prompt compliance is soft layer (7/8), gateway `profile: "minimal"` is hard layer.
- Cost projection from test data: ~$7.88/mo at 200 req/day (within $8.70 target).
- 13/14 tasks done. TMA-010b (24h cost measurement) now unblocked.
- TMA-010b (token cost measurement) completed: 10 synthetic requests + 25 TMA-009 cloud requests analyzed.
- Key finding: cache doesn't activate on direct API calls — compressed prompt (1,090 tokens) below Haiku 4.5's 4,096-token minimum. Production system prompt (~6,590 tokens with tools) exceeds minimum.
- Key finding: original spec's cost model wrong about mechanism (assumed 135 req/day on API with 100% cache reads). Production: 39 req/day (heartbeats on Ollama), realistic cache hit rates. Dollar amount coincidentally matches.
- Revised projection: $8.40/mo at 50% cache hit rate (within ±20% of $8.70 target). Uncached: $10.77/mo.
- 1-hour cache TTL available as optimization ($6.09/mo at 75% hit rate).
- Spec updated: cost model revised with evidence.
- 14/14 tasks done. All TASK phase work complete.

## 2026-02-23

- Health-check cron built (`_system/scripts/tess-health-check.sh`): external state machine for Limited Mode entry/exit. Pings Anthropic API every 5 min, swaps config + SOUL.md + restarts gateway on 3 consecutive failures. Recovery reverses swap. Telegram notifications on entry/exit. 4-hour escalation. Launchd plist + env template created.
- Compressed voice prompt deployed to production: SOUL.md (1,090 tokens) replaced uncompressed version (3,000 tokens) in OpenClaw workspace. IDENTITY.md emptied (content merged into SOUL.md). Gateway restarted, port 18789 confirmed listening.
- Maintenance runbook written: routine ops, model swap procedure, config rollback, health-check setup/teardown, identity doc updates, cost monitoring, 8 deferred items catalogued.
- Milestone 3 exit gate passed: all 8 criteria satisfied.
- Project phase: TASK → DONE. All deliverables complete.
