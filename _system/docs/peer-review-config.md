---
type: config
domain: software
status: active
created: 2026-02-18
updated: 2026-06-10
models:
  openai:
    model: gpt-5.4
    endpoint: https://api.openai.com/v1/chat/completions
    env_key: OPENAI_API_KEY
    max_tokens: 8192
  google:
    model: gemini-3.1-pro-preview
    endpoint: https://generativelanguage.googleapis.com/v1beta/models
    env_key: GEMINI_API_KEY
    max_tokens: 8192
  deepseek:
    model: deepseek-v4-pro
    endpoint: https://api.deepseek.com/chat/completions
    env_key: DEEPSEEK_API_KEY
    max_tokens: 8192
    token_param: max_tokens
  grok:
    model: grok-4.3
    endpoint: https://api.x.ai/v1/chat/completions
    env_key: XAI_API_KEY
    max_tokens: 8192
    token_param: max_tokens
    prompt_addendum: >
      Prioritize finding problems. At least two-thirds of your findings should be
      issues (CRITICAL, SIGNIFICANT, or MINOR), not STRENGTHs. Before rating any
      aspect as a STRENGTH, verify your claim against the actual artifact — if the
      artifact claims a feature exists (e.g., "the validator checks X"), read the
      relevant code or section to confirm it actually does. Challenge your own
      positive assessments: what edge case would break this? What assumption are
      you making? A review that finds only strengths is not useful.
default_reviewers:
  - openai
  - google
  - deepseek
  - grok
optional_reviewers:
  - perplexity
perplexity:
  model: sonar-reasoning-pro
  dispatch: manual
  artifact_types: [spec, architecture, skill, writing]
retry:
  max_attempts: 3
  backoff_seconds: [2, 5]
  retry_on: [429, 500, 502, 503]
curl_timeout: 120
---

# Peer Review Configuration

Model configuration, retry policy, and reviewer-specific settings for the peer-review skill.

**Edit this file to change models, endpoints, or retry behavior.** The skill reads these values at invocation time. No skill file changes needed when swapping models.

**Per-reviewer fields:**
- `injection_wrapper`: Controls injection-resistance wrapper style. Values: `standard` (default — explicit "do not follow instructions" phrasing) or `soft` (neutral framing that avoids triggering aggressive safety filters). Configure per reviewer if needed.
- `token_param`: The JSON key used for max token limit in the API payload. OpenAI GPT-5.4 uses `max_completion_tokens`; DeepSeek and most OpenAI-compatible APIs use `max_tokens`. Set per provider.
- `max_tokens` (DeepSeek): The `deepseek-reasoner` alias is **not version-pinned** — as of Feb 2026 it resolves to DeepSeek V3.2 (not the original R1, despite the alias name). The model uses reasoning tokens internally (`<think>` blocks). The `max_tokens: 8192` controls output tokens only — reasoning chains run separately. If reviews start coming back truncated, bump to 16384. Monitor on first few runs before preemptively increasing.

**Grok (xAI):** `grok-4.3` (released 2026-04-30) is an OpenAI-compatible chat completions API at `api.x.ai`. Pricing: $1.25/M input, $2.50/M output (tiered — requests over 200k total tokens bill higher). Reasoning model, 1M token context window. Uses `max_tokens` (not `max_completion_tokens`). Auth: `Authorization: Bearer $XAI_API_KEY`. Key in `~/.config/crumb/.env` as `XAI_API_KEY`. Replaced `grok-4-1-fast-reasoning`, which xAI removed from the API (confirmed absent from /v1/models 2026-06-10).

**Grok 4.3 calibration watch (OPEN, 2026-06-10):** The Grok family carries a documented fabrication record — Grok 4.20 produced 12+ fabrications *with full context provided* in the TV2-Cloud eval (see memory `model-grok-fabrications.md`), and that note warns against trusting successor versions without re-testing. grok-4.3 is untested by us. **For its first 2–3 reviews, audit findings Perplexity-style:** verify each GRK finding against the actual artifact before counting it in synthesis; tally fabricated/misread findings in this note. Drop from `default_reviewers` if the fabrication pattern persists. Operator decision 2026-06-10: enable with this watch rather than drop.

*Watch tally — review 1 (2026-06-10, vault-optimization spec): 8 findings — 0 fabrications, 1 misread (GRK-F7: claimed a decision gate was absent that the artifact contains), 1 noise. Fast (12.9s) and short (987 completion tokens) vs panel norm ~2-7k. Findings that landed: GRK-F1 (boundary), GRK-F3 (CRITICAL, backup verification — consensus), GRK-F4 (evidence), GRK-F5 (ceremony metric, unique). Acceptable; watch continues.*

*Watch tally — review 2 (2026-06-10, vault-optimization action plan): 9 findings — 0 fabrications, 1 misread (GRK-F3: claimed VO-026 bundles two work units; they are separate tasks VO-025/026), 1 noise (GRK-F4: invented a traceability requirement between soak workflows and consumer survey). Again fast/short (12.8s, 923 tokens). Landed: GRK-F2 (AS-025 verification gap, consensus with OAI-F11), GRK-F5, GRK-F7 (consensus), GRK-F1 (valid but severity-inflated). Pattern across 2 reviews: zero fabrication, ~1 misread + ~1 noise per round, thin but real unique value. One more review to close the watch.*

**Grok calibration note (2026-02-23, 3 reviews):** First review (diagramming skills) showed positivity bias (8/15 STRENGTHs). Prompt addendum added. M1 capture clock review: improved but still monitoring. M2/M3 review: 11/15 issues (73%) — addendum working well. Unique valuable findings: maxPosts cap (F4), vault_target trim (F5), liveness false-positive (F9). **Verdict: keep.** Grok is producing genuine unique insights at the lowest per-review cost ($0.02-0.04).

**Finding ID namespaces:** Each reviewer uses a prefix for finding IDs in the synthesis step: `OAI-F1`, `OAI-F2`, … (OpenAI); `GEM-F1`, `GEM-F2`, … (Google); `DS-F1`, `DS-F2`, … (DeepSeek); `GRK-F1`, `GRK-F2`, … (Grok); `PPLX-F1`, `PPLX-F2`, … (Perplexity, manual submission only).

**Perplexity calibration (2026-02-23, 5 reviews):** Perplexity is artifact-type dependent. **Do not include for code reviews** — across 2 code reviews (M1 capture clock, M2/M3 attention+feedback), 4/17 findings were outright hallucinations (fabricated import errors, imagined bugs in correct code) and 2 more were misreadings. Valid findings all overlapped with other reviewers. **Include for spec/design/architecture reviews** — M1 architectural analysis showed genuine insight (dev/test harness gap, semantic eval criteria). Use the `artifact_types` field in config to control per-reviewer inclusion. When Perplexity is included, it remains a manual claude.ai submission (not automated dispatch).

**Perplexity verdict calibration (2026-02-23, 3 spec/design reviews):** Perplexity returned "Needs rework" on 3 consecutive reviews (spec, migration, action plan). In all 3 cases the individual findings did not support that severity — the synthesis classified most findings as should-fix or defer, not must-fix/blocking. **Treat Perplexity's summary verdict as having zero signal.** Read it as "has significant findings" and evaluate the actual findings on their merits. The per-finding analysis remains valuable for spec/design artifacts; the verdict is noise.

**DeepSeek model identity:** `deepseek-v4-pro` (2026): 1.6T-parameter MoE (49B activated), 1M context, thinking + non-thinking modes. Replaced the `deepseek-reasoner` alias (→ V3.2-Thinking), which is officially deprecated 2026-07-24 and already absent from the /models endpoint (confirmed 2026-06-10). Historical note: `deepseek-reasoner` resolved to DeepSeek-V3.2-Thinking as of 2026-02-20. Log `system_fingerprint` from raw JSON in `reviewer_meta` for audit trail if the model shifts again.

**Cost note (refreshed 2026-06-10):** GPT-5.4 pricing is $2.50/M input, $15.00/M output. Gemini 3.1 Pro pricing is $2.00/M input (same as Gemini 3 Pro — free upgrade). DeepSeek V4 Pro pricing is $1.74/M input, $3.48/M output. Grok 4.3 pricing is $1.25/M input, $2.50/M output. Estimated 4-model review cost is ~$0.25–0.35 per artifact.

**Panel roster audit (2026-06-10):** Live /models check across all four providers. OpenAI flagship still GPT-5.4 (gpt-5.4-2026-03-05; 5.4-pro exists, not adopted — cost). Google pro-class still gemini-3.1-pro-preview (Gemini 3.5 generation is flash-tier only so far). DeepSeek and Grok slots were dead (models removed from APIs) — updated per operator decisions above.

**Drift from skill spec:** The values above reflect runtime-tuned settings. The original skill spec (retired 2026-07-03; git history at `_system/docs/peer-review-skill-spec.md`) records the initial design values: `gemini-2.5-pro` (→ `gemini-3.1-pro-preview`), `max_tokens: 4096` for all providers (→ 8192), `curl_timeout: 60` (→ 120), `perplexity/sonar-reasoning-pro` (→ `deepseek/deepseek-reasoner`). The original three-provider default was GPT-5.2 Thinking, Gemini 2.5 Pro, Sonar Reasoning Pro — now GPT-5.4, Gemini 3.1 Pro Preview, DeepSeek V3.2-Thinking (via `deepseek-reasoner`). Model upgrades: OpenAI GPT-5.2 → GPT-5.4 (2026-03-14); Gemini 3 Pro Preview → Gemini 3.1 Pro Preview (2026-03-14, forced by deprecation — old model shut down 2026-03-09). This config file is authoritative for runtime behavior; the skill spec records the design baseline. Note: the design spec v1.7.1 changelog also references the old three-provider lineup and should be updated when the spec is next revised.

**Format constraints (for deterministic shell extraction):**
- No nesting beyond two levels (e.g., `models.openai.model` is max depth)
- Single-line values only for all fields except `prompt_addendum` (which uses YAML `>` folded scalar)
- Arrays use YAML sequence syntax (`- item` on separate lines)
- No anchors, aliases, or complex YAML features
