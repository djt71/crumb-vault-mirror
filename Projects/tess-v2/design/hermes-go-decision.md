---
type: decision
status: active
domain: software
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
task: TV2-008
skill_origin: manual
---

# TV2-008: Hermes GO Decision

**Decision: GO** — operator approved 2026-04-01.

## Evidence Summary

### Platform Evaluation (TV2-006, v0.4.0 → v0.6.0)

| Criterion | Score | Notes |
|-----------|-------|-------|
| 1. Installation & setup | 5 | Clean install, CLI tooling |
| 2. Telegram reliability | 4 | Polling stable, 1 network blip recovered |
| 3. Model switching | 3 | Config-based, display bug resolved |
| 4. Tool calling (with model) | 3 | Works via gateway, model-dependent quality |
| 5. Memory persistence | 3 | Session memory functional, capacity limits noted |
| 6. Skill generation | 4 | 95 bundled skills, custom creation works |
| 7. Cron scheduling | 4 | v0.6.0 cron expressions fixed persistence bug |
| 8. Subagent delegation | 4 | Functional |
| 9. Vault integration | 3 | CWD fix applied, file reads confirmed working |
| 10. Stability | 4 | Zero unplanned restarts in 48h+ soak |
| 11. Ralph loop support | N/A | External by design (AD, operator override) |

**Average (10 criteria): 3.70/5** — passes ≥3.5 threshold.
**Minimum: 3/5** — passes ≥3 floor.

### Soak Test (TV2-007)

**Nemotron soak (71h):** 100% load test success, zero unplanned restarts, memory
plateauing at 31.4/96 GB. GO per AD-012.

**Kimi K2.5 soak (48h on v0.6.0):**
- Heartbeat: consistent delivery, clean responses
- Vault-check: correct file reads and analysis on every run
- Deep-check: structured self-assessment with grounded data
- Cron persistence: all jobs running on schedule (`Repeat: ∞`)
- Think-block issue: identified, root-caused, patched, PR submitted (#4467)
- Streaming stall: 1 occurrence in 48h, non-blocking edge case
- Zero gateway errors, zero unplanned restarts

### Cloud Model Evaluation (TV2-Cloud, supplementary)

- Kimi K2.5: 89/95 weighted score, zero fabrications, only model passing all thresholds
- Qwen 3.5 397B: 83/95 after retest, designated failover (AD-011)
- Two-tier architecture confirmed: Kimi orchestrates, Nemotron executes (AD-009, AD-010)

### v0.6.0 Upgrade Findings

- Cron persistence fixed (expressions vs. repeat counts)
- Tool-call formatting fixed (`.ls` degenerate loop was gateway bug, not Kimi)
- Fallback provider chain now platform-native (#3813)
- MCP Server mode available for future Crumb↔Tess bridge (#3795)

## Operator Assessment

> "Hermes is a wholehearted GO. So much more stable than OpenClaw."

Key factors cited: platform stability, clean cron scheduling, Telegram reliability,
model flexibility via OpenRouter. The v0.4.0 → v0.6.0 upgrade during soak demonstrated
the project's development velocity (95 PRs in one release).

## Conditions and Caveats

1. **Think-block handling required.** Kimi K2.5 returns all responses in
   `reasoning_content` field — this is default model behavior, not an edge case.
   Hermes patch (#4467) is required infrastructure. See `hermes-patch-tracking.md`.

2. **OpenRouter streaming stalls.** One 12+ minute stall observed on a heavy
   analytical prompt. Mitigation: prefer smaller sequential prompts over multi-file
   single-pass analysis for cron jobs.

3. **Hermes memory capacity.** Kimi self-reported 89-96% memory utilization.
   Monitor for context loss in longer sessions. Compaction may be needed.

4. **Ralph loops are external.** Contract runner (TV2-031b) is a Crumb-side
   component, not a Hermes extension. This is architecturally sound — cleaner
   separation than having Hermes own the execution loop.

## What This Unlocks

Phase 3 executor-side design is fully unblocked:
- TV2-017: Contract schema / state machine design
- TV2-018: Confidence-aware escalation (three-gate hybrid)
- TV2-019: Ralph loop implementation design
- TV2-021b: Service interface finalization
- TV2-023: System prompt architecture
- TV2-024: Credential management design
- TV2-031a-d: External repo + contract runner + staging engine + dispatch validator
- TV2-041: Joint Hermes + local model integration test

## Architectural Decisions (cumulative)

| AD | Decision |
|----|----------|
| AD-001 | Crumb vault is authoritative source of truth |
| AD-002 | OpenClaw runs in parallel until parity demonstrated |
| AD-003 | Spec+eval integration — contracts formalize phase gates |
| AD-004 | Each task runs as a Ralph loop — one contract per session |
| AD-005 | Two-tier architecture: cloud orchestrator + local executor |
| AD-008 | Kimi K2.5 is the cloud orchestration model |
| AD-009 | Risk-based escalation gate (deterministic for sensitive ops) |
| AD-010 | Route by verifiability, not by difficulty |
| AD-011 | Qwen 3.5 397B is the cloud-to-cloud failover |
| AD-012 | Nemotron Cascade 2 approved as local executor |
