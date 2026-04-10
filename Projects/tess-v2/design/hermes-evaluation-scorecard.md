---
type: evaluation
status: active
domain: software
created: 2026-03-28
updated: 2026-03-28
project: tess-v2
task: TV2-006
skill_origin: manual
---

# Hermes Agent Evaluation Scorecard

**Version evaluated:** Hermes v0.4.0
**Model under test:** Qwen3.5 27B Q4_K_M via llama-server (llama.cpp build 8572)
**Hardware:** Mac Studio M3 Ultra, 96GB unified memory
**Date:** 2026-03-28

## Methodology

Each criterion scored 1–5 using evidence from:
- **Direct testing** (D): hands-on validation during TV2-005 or this evaluation
- **Config/architecture review** (C): reading config.yaml, .env, plists, source structure
- **Log analysis** (L): gateway.log, llama-server-stderr.log, errors.log
- **Baseline data** (B): TV2-004 quality battery results (21 prompts, Qwen3.5 27B Q4_K_M)

Evidence type noted per criterion. Criteria scored from config/architecture are flagged — interactive validation during TV2-007 soak test will confirm or revise.

## Scorecard

| # | Criterion | Score | Evidence |
|---|-----------|-------|----------|
| 1 | Installation & setup on macOS | 5 | D |
| 2 | Telegram reliability | 4 | D, L |
| 3 | Model switching | 3 | C, D |
| 4 | Tool calling reliability (with chosen model) | 3 | D, B |
| 5 | Memory persistence across sessions | 3 | C |
| 6 | Skill generation | 4 | C |
| 7 | Cron scheduling with Telegram delivery | 4 | C, D |
| 8 | Subagent delegation | 4 | C |
| 9 | Vault integration | 3 | C |
| 10 | Stability | 4 | L, C |
| 11 | Ralph loop support | 2 | C |

**Average: 3.55/5** (passes ≥3.5 threshold)
**Minimum (raw): 2/5** (criterion 11)
**Criterion 11 reclassified:** see §Criterion 11 Reclassification below

## Detailed Assessments

### 1. Installation & Setup on macOS — 5/5

**Test methodology:** Direct installation and configuration (TV2-005).

- Python 3.11 venv via `uv` — clean, isolated install at `~/.hermes/`
- 95 bundled skills across 25 categories, ready out of the box
- LaunchAgent plists created cleanly for both gateway and llama-server
- Both services running as persistent LaunchAgents with KeepAlive
- `hermes status`, `hermes doctor`, `hermes setup` — full diagnostic CLI
- Config: single well-documented `config.yaml` + `.env` for secrets
- SOUL.md personality injection — straightforward file drop

**No issues.** Best-in-class for a Python-based agent framework on macOS.

### 2. Telegram Reliability — 4/5

**Test methodology:** Direct Telegram interaction (TV2-005 A1/A7 validation) + gateway log analysis.

**Confirmed working:**
- Bot connected, polling for updates at ~10s intervals
- Message delivery: 157-char and 1182-char responses delivered successfully
- DoH DNS fallback for Telegram API IPs (resilient to DNS issues)
- Session interrupt handling works (new message while agent processing → interrupt)
- `sendChatAction` typing indicator before responses
- Allowlist enforcement (Danny's user ID `7754252365`)
- STT configured (whisper-1) for voice message transcription

**Deductions:**
- Voice memo transcription not tested end-to-end (architecture present, whisper-1 configured)
- Latency not measured systematically (would need TV2-007 soak data)
- No evidence of long-message handling (>4096 chars) or message splitting behavior

### 3. Model Switching — 3/5

**Test methodology:** Config review + `hermes model` + `hermes status` output.

**Confirmed:**
- Current: Qwen3.5 27B Q4_K_M via custom endpoint (llama-server port 8080)
- `hermes model` command exists for provider/model selection
- Config supports: custom (local), OpenRouter, Nous Portal, Codex OAuth, Z.AI, Kimi, MiniMax
- OpenRouter API key present in .env
- Smart model routing available (cheap model for simple turns, disabled by default)
- Codex OAuth: logged in and authenticated

**Issues found:**
- `hermes status` reports most API keys as "not set" despite being in `.env` — detection mismatch. OpenRouter, Z.AI, Kimi, MiniMax, FAL, Firecrawl, Browserbase, Tinker, WandB all show `✗ (not set)`. Only OpenAI shows `✓`. This suggests `.env` loading may be inconsistent between gateway process and CLI status check, OR the key names don't match what status checks for.
- Runtime model switching not tested — unknown whether switching from local to OpenRouter mid-conversation works smoothly or requires gateway restart
- No evidence of automatic failover (local model down → OpenRouter fallback) without manual intervention

**This needs investigation.** If the .env keys aren't being read correctly, OpenRouter fallback may not work. The §6.5 runtime failover design (added in peer review r2) depends on model switching working reliably.

### 4. Tool Calling Reliability (with chosen model) — 3/5

**Test methodology:** Direct validation (TV2-005) + quality battery baseline (TV2-004, 21 prompts).

**Confirmed:**
- Tool-call formatting: 4/5 (0.80) — model produces parseable tool calls. `schedule_task` missed on tc-04.
- Structured output: 5/5 (1.00) — perfect JSON/YAML/table generation
- `finish_reason: "tool_calls"` correctly signaled, function dispatch structured

**Issues:**
- Routing decisions: 2/5 (0.40) — model defaults to `vault_search` when uncertain instead of selecting correct executor
- Guardrails: 0/3 (0.00) — model executes dangerous requests (unauthorized email, destructive deletion, credential exposure) without refusal. **Critical finding.**
- Name hallucination: "Dan Turner" instead of "Danny" on first interaction — model fabricates missing details
- Multi-step planning: 0.32 — model calls tools instead of generating text plans (scorer mismatch, but indicates model prefers action over analysis)

**Assessment:** Tool *formatting* works. Tool *judgment* is weak. The guardrail failure is the most concerning — Tess orchestration requires reliable escalation/refusal for out-of-scope requests. This is a Qwen3.5 model issue, not a Hermes issue, but the criterion says "with chosen model."

Note: Guardrail pass threshold in §13.2 is 1.0 (non-negotiable). Current score: 0.0. This model fails the benchmark harness quality gate on guardrails alone.

### 5. Memory Persistence Across Sessions — 3/5

**Test methodology:** Config review + file system inspection.

**Architecture present:**
- MEMORY.md (agent notes, 2200 char limit ~800 tokens) + USER.md (user profile, 1375 char limit ~500 tokens)
- Session reset: 24h idle OR 4AM daily → memory flush before wipe
- Memory flush triggers on exit/reset if ≥6 user turns
- Nudge interval: every 10 turns reminds agent to save memories
- Honcho integration available (cross-session user modeling, API key configured)
- Session search tool available (FTS5 + summarization for recalling past conversations)

**Issues:**
- Neither MEMORY.md nor USER.md exist yet — memory system hasn't been exercised
- Cross-session persistence not empirically validated (would need: save memory → reset → verify recall)
- Character limits are tight (800 tokens for agent notes) — may be insufficient for Tess operational context
- AD-001 constraint: vault is authoritative, Hermes memory is convenience only. The bounded memory design is correct for this constraint, but the boundary hasn't been tested.

**Score reflects:** Feature exists and is well-designed, but zero empirical evidence of actual persistence behavior.

### 6. Skill Generation — 4/5

**Test methodology:** Config review + skills directory inspection.

**Confirmed:**
- 95 bundled skills across 25 categories (apple, email, feeds, github, research, social-media, software-development, etc.)
- Skills creation nudge every 15 tool-calling iterations
- `hermes skills` CLI for management (search, install, configure)
- Skills Hub for online registry search/install
- Platform-specific skill availability (CLI vs Telegram toolsets)
- `skill_view` and `skills_list` tools available in agent context

**Not tested:**
- Auto-generation of a new skill from task completion
- Quality of generated skill procedures
- Whether generated skills persist correctly and load on next session

**Score reflects:** Rich bundled library + creation infrastructure, but auto-generation not exercised.

### 7. Cron Scheduling with Telegram Delivery — 4/5

**Test methodology:** `hermes cron` CLI + gateway log analysis + config review.

**Confirmed:**
- `hermes cron` subcommand: create, list, edit, pause, resume, run, remove, status, tick
- Cron ticker running in gateway process (60s interval, visible in gateway.log)
- `cronjob` tool available in Telegram toolset — agent can create/manage cron from chat
- `hermes cron create` CLI for non-interactive setup
- Currently 0 jobs (fresh install)

**Not tested:**
- End-to-end: create cron job → wait for trigger → verify Telegram delivery
- Cron expression parsing reliability
- Behavior when gateway restarts mid-cron-cycle (job persistence)
- Stagger support (known OpenClaw limitation: `--stagger` requires `--cron`, not `--every`)

**Score reflects:** Full cron infrastructure present and integrated with gateway. Awaiting soak test for delivery validation.

### 8. Subagent Delegation — 4/5

**Test methodology:** Config review.

**Confirmed:**
- `delegate_task` tool configured
- Max iterations per child: 50
- Batch mode: up to 3 parallel subagents
- Default toolsets for subagents: terminal, file, web
- Model/provider override for subagents (inherit parent by default)
- Provider-aware credential resolution for subagent model routing

**Not tested:**
- Actual parallel dispatch + report-back
- Subagent failure handling (what happens when 1 of 3 parallel subagents fails?)
- Token cost of delegation overhead
- Quality of subagent work with local Qwen3.5 model (given routing weakness noted in criterion 4)

**Score reflects:** Feature architecture is complete and configurable. No empirical data on execution quality.

### 9. Vault Integration (Read/Write Obsidian Markdown) — 3/5

**Test methodology:** Config review + plist analysis.

**Architecture:**
- File tools: `read_file`, `write_file`, `patch`, `search` — available in Telegram toolset
- Terminal tool: can run arbitrary commands (git, obsidian-cli, etc.)
- Gateway WorkingDirectory: `/Users/tess/.hermes/hermes-agent` (NOT the vault)
- Terminal CWD: `"."` (resolves to hermes-agent directory in gateway context)
- MESSAGING_CWD: commented out in .env

**Issues:**
- **CWD mismatch:** Gateway operates from hermes-agent directory, not vault root. File tools using relative paths won't reach vault. Terminal commands need absolute paths or explicit `cd`.
- **No native Obsidian integration:** No obsidian-cli awareness, no MCP server for vault metadata. Would need terminal commands for indexed queries (tags, backlinks, properties).
- **AD-008 compliance:** Spec requires staging → promotion write model. Hermes has no concept of staged writes — `write_file` goes direct. Vault authority (AD-001) means Hermes writes need governance that doesn't exist yet.
- **YAML frontmatter:** Hermes won't know vault frontmatter conventions without explicit instruction in SOUL.md or a skill.

**What works:** Hermes *can* read/write any file via absolute paths. The terminal tool *can* run obsidian-cli commands. But the integration is raw — no vault-aware abstractions, no frontmatter awareness, no staging.

**Score reflects:** Capability exists at the tool level but requires significant configuration (CWD fix, vault skills, frontmatter instructions) before it's operationally useful.

### 10. Stability — 4/5 (provisional)

**Test methodology:** Log analysis + LaunchAgent config review.

**Positive indicators:**
- Gateway error log: empty (zero errors since install)
- Gateway log: clean startup → connection → polling cycle, no warnings except DNS fallback (expected)
- llama-server: stable context checkpointing, consistent ~25 tok/s generation, ~260 tok/s prompt processing
- LaunchAgent KeepAlive configured (auto-restart on crash)
- llama-server: context checkpoint system working (restore/create visible in logs)
- Session interrupt handled cleanly (no crash on concurrent message)

**Unknown:**
- Long-running behavior (memory growth over hours/days)
- Behavior under sustained load (multiple concurrent conversations, cron jobs firing)
- Recovery from llama-server OOM or GPU thermal throttle
- Gateway behavior when llama-server is temporarily unavailable

**Score reflects:** Zero errors in observation window, clean architecture for resilience. Provisional — TV2-007 (72-hour soak) is the definitive test.

### 11. Ralph Loop Support — 2/5

**Test methodology:** Config review + architecture analysis.

**What Hermes provides:**
- `max_turns: 60` — global iteration limit (not per-contract)
- Subagent `max_iterations: 50` — per-child limit (closest to iteration budget)
- Session management (reset, continue, resume)
- Skills system (can load procedure documents)

**What Ralph loops require (from spec §9):**
1. **Strict iteration budgets** — Hermes has global max_turns and per-subagent max_iterations, but no per-task contract budget. Partially available via subagent delegation (spawn a subagent with max_iterations as the budget).
2. **Failure context injection between iterations** — Not native. Hermes doesn't accumulate structured failure feedback across loop iterations. Each retry would need manual context assembly.
3. **Mechanical hard stops on contract satisfaction** — Not native. No concept of "evaluate output against acceptance criteria and stop if satisfied." The agent runs until it decides it's done or hits max_turns.
4. **Fresh context per iteration** — Partially available via `/new` or session reset, but not automated.

**Assessment:** Ralph loops cannot run natively within Hermes. They would need to be implemented as **external scripts** that:
1. Invoke `hermes chat --print` (or the API) with a contract prompt
2. Evaluate the output against acceptance criteria
3. Inject failure context into the next invocation
4. Hard-stop when contract is satisfied or budget exhausted

This is the answer to criterion 11's question: "must Ralph loops be implemented as external scripts that Hermes triggers?" → **Yes, external scripts that invoke Hermes, not the reverse.**

This is a significant architectural finding for Phase 3. The contract runner (TV2-031b) must be built as an external orchestration layer, not a Hermes plugin.

## Criterion 11 Reclassification

**Operator decision (2026-03-28):** Score override — reclassify criterion 11 as "answered, not failed."

**Rationale:** The spec's criterion 11 explicitly frames a binary question: "Can Hermes natively support strict iteration budgets, failure context injection between iterations, and mechanical hard stops based on contract satisfaction? Or must Ralph loops be implemented as external scripts that Hermes triggers?" The answer is: external. This is a **design input**, not a platform deficiency.

The external orchestration path is architecturally sound — arguably better than native support:
- The spec already separates Tess (orchestrator) from the platform (messaging/scheduling/model routing)
- Hermes does what it's good at: Telegram, cron scheduling, model access, memory
- The contract runner does what must be mechanically enforced: iteration budgets, hard stops, failure classification, staging writes
- Cleaner separation of concerns than having Hermes own the execution loop

**Implementation path:** Contract runner (TV2-031b) is a script or small service under the tess account. Reads contracts from queue, invokes executor (through Hermes for model access or directly to llama.cpp/OpenRouter), checks termination conditions, manages staging, reports back. Hermes is the interface layer and scheduler, not the execution engine.

**For TV2-008 GO/NO-GO calculation:** Criterion 11 scored 2/5 on native support. External orchestration is the confirmed architecture. Score overridden — not counted toward the ≥3 floor check. Remaining 10 criteria: average 3.70/5, minimum 3/5. Both pass.

## Summary

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Average (all 11) | 3.55 | ≥3.5 | PASS |
| Average (10 criteria, C11 reclassified) | 3.70 | ≥3.5 | PASS |
| Minimum (10 criteria, C11 reclassified) | 3 | ≥3 | PASS |
| A1 (local LLM connectivity) | Confirmed | Required | PASS |
| A7 (SOUL.md personality) | Partially confirmed | Required | PASS (with caveat) |
| Criterion 11 | 2/5 raw, reclassified | N/A | Design input |

### Risk Items for TV2-008 Decision

1. **Guardrail failure (0/3)** — Model-specific, not Hermes-specific. Must be addressed by model selection (Phase 2) and/or prompt engineering (TV2-023). If no local model passes guardrails, escalation-to-cloud becomes mandatory for sensitive operations. Reinforces that Gate 3 (risk-based policy escalation) is essential — certain task classes must never be handled by the local model regardless of confidence.
2. **Model switching / API key issue** — `hermes status` reports most API keys as "not set" despite being in `.env`. If this is a real loading issue (not just a display bug), OpenRouter failover (§6.5) is compromised. Must investigate and resolve before soak test.
3. **Vault CWD mismatch** — Gateway WorkingDirectory is hermes-agent dir, not vault. Fix before soak test to avoid contaminated results.

### Pre-Soak Fixes Required

1. **Fix vault CWD** — Set `terminal.cwd` to `/Users/tess/crumb-vault` in config.yaml
2. **Investigate .env key detection** — Determine if display bug or real loading failure. Test OpenRouter failover.
3. Both must be resolved before TV2-007 begins.
