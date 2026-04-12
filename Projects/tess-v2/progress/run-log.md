---
project: tess-v2
type: run-log
period: 2026-04 onwards
created: 2026-04-10
updated: 2026-04-10
---

# tess-v2 — Run Log

**Previous log:** run-log-2026-03.md (45 sessions, Mar 28 – Apr 10. Project creation through Phase 4 implementation. Key milestones: Hermes GO + Nemotron GO decisions, Phase 3 architecture complete, 10 services migrated with gates passed, Phase 4a vault semantic search complete, Amendment Z Phase A live. TV2-036/037 cancelled Apr 10. TV2-043 Scout in re-soak.)
**Rotated:** 2026-04-10

## 2026-04-12 — TV2-043 gate eval + TV2-045 Paperclip spike

**Context loaded:** dispatch queue (IDQ-002), TV2-043 staging artifacts (C1/C2/C3), scout pipeline logs, run-history, project-state.yaml, paperclip-relevance-check-2026-04-06.md, services-vs-roles-analysis.md, tasks.md, opportunity-scout source code (llm.js, assemble.js, digest-and-deliver.js)

### TV2-043 Gate Evaluation (Apr 12)

**Verdict: FAIL — C1 0/3 clean runs, C2 PASS, C3 PASS.**

Root cause: Nemotron `max_tokens: 8192` truncation when ranking 30 candidates in digest pipeline. Not a Tess infra issue — application bug in Opportunity Scout's LLM integration. All post-fix runs (Apr 10/11/12) dead-lettered due to "Unexpected end of JSON input" from truncated ranking output.

**Fix deployed** (commit `ef93e1a` in opportunity-scout):
- `digest-and-deliver.js`: LIMIT 30 → 10 (daily cadence doesn't need more)
- `llm.js`: Added `finish_reason === 'length'` truncation detection
- Dry-run verified: 10 candidates → clean ranking, 5-item digest with synthesis

**Re-soak:** 2-day extension (Apr 13–14), C1 focus. C2/C3 already proven. Gate eval Apr 14. IDQ-002 updated (v5), project-state updated.

Also found: Apr 10 OpenClaw 07:00 run succeeded (digest delivered, 5 items) but Tess-side runs failed on `claude -p` scoring. Apr 11-12: both OpenClaw and Tess failed on Sonnet ranking (truncated JSON). The Nemotron migration (f056e5b) replaced `claude -p` for triage but the digest ranking step hit the token limit with 30 candidates.

### TV2-045 Paperclip Integration Spike

**Verdict: DEFER. Bailed at Stage 0 checkpoint (~45 min).**

Key finding: **no generic adapter exists** in Paperclip. The Apr 6 memo and web research claimed Bash/HTTP adapters. Actual adapters in `packages/adapters/`: `claude-local`, `codex-local`, `cursor-local`, `gemini-local`, `openclaw-gateway`, `opencode-local`, `pi-local`. All runtime-specific. tess-v2's Python contract runner doesn't fit any adapter shape.

Additional findings:
- Version still `v2026.403.0` (8 days unchanged despite "weekly calver" claim)
- Dashboard is the only genuine add — everything else overlaps or conflicts with tess-v2's existing capabilities
- Peer review (4-model, all succeeded) validated plan structure but key recommendation (use Bash adapter) was based on incorrect adapter inventory

Artifacts produced:
- `design/paperclip-spike-decision-2026-04-12.md` — decision document with 5-criteria eval, collision inventory, cost/benefit matrix, patterns-worth-copying analysis
- `Projects/tess-v2/reviews/2026-04-12-paperclip-spike-plan.md` — 4-model peer review with synthesis
- Next state-check: ~2026-07-12 (90 days)

TV2-045 marked done. Project: 43/50 tasks done, 2 cancelled.

### Compound observations

1. **Staged spike design with bail checkpoints is proven effective.** 45 minutes vs. 4.5 hour budget. The peer review improved the plan (must-fix items were good), but the Stage 0 finding made all of it moot. Worth applying this pattern to future research spikes.
2. **Web research and prior memos can fabricate adapter inventories.** The "Bash adapter" appeared in the Apr 6 memo, web search results, and all 4 peer reviewers took it as given. Only direct npm inspection revealed it doesn't exist. Ground truth beats secondhand claims.
3. **Nemotron max_tokens ceiling is a production concern.** The 8192 default worked for triage (small batches) but failed for ranking (30 candidates). Local LLM token budgets need to be sized to the prompt, not left at defaults.

### Model routing

- All work done on Opus (session default). No Sonnet delegation this session.
- Peer review dispatched to GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast (all succeeded, ~$0.22 total estimated).
