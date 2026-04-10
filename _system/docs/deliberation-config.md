---
type: config
domain: software
status: active
created: 2026-03-22
updated: 2026-03-22
models:
  openai:
    model: gpt-5.4
    endpoint: https://api.openai.com/v1/chat/completions
    env_key: OPENAI_API_KEY
    max_tokens: 8192
    token_param: max_completion_tokens
    max_context_tokens: 128000
  google:
    model: gemini-3.1-pro-preview
    endpoint: https://generativelanguage.googleapis.com/v1beta/models
    env_key: GEMINI_API_KEY
    max_tokens: 8192
    max_context_tokens: 2000000
  deepseek:
    model: deepseek-reasoner
    endpoint: https://api.deepseek.com/chat/completions
    env_key: DEEPSEEK_API_KEY
    max_tokens: 8192
    token_param: max_tokens
    max_context_tokens: 64000
  grok:
    model: grok-4-1-fast-reasoning
    endpoint: https://api.x.ai/v1/chat/completions
    env_key: XAI_API_KEY
    max_tokens: 8192
    token_param: max_tokens
    max_context_tokens: 128000
evaluator_registry:
  business-advisor:
    provider: openai
    overlay: "_system/docs/overlays/business-advisor.md"
    companion: null
    persona_bias: "structurally optimistic about markets, skeptical about execution timelines"
    dissent_instruction: "Look for market assumptions other evaluators take for granted."
  career-coach:
    provider: google
    overlay: "_system/docs/overlays/career-coach.md"
    companion: null
    persona_bias: "structurally protective of career capital, alert to employer conflicts"
    dissent_instruction: "Look for PIIA risk or opportunity cost that other evaluators underweight."
  financial-advisor:
    provider: deepseek
    overlay: "_system/docs/overlays/financial-advisor.md"
    companion: null
    persona_bias: "structurally conservative about costs, skeptical of revenue projections"
    dissent_instruction: "Look for hidden costs, optimistic revenue assumptions, or missing risk scenarios."
  life-coach:
    provider: grok
    overlay: "_system/docs/overlays/life-coach.md"
    companion: "Domains/Spiritual/personal-philosophy.md"
    persona_bias: "structurally attentive to sustainability, values alignment, and whole-person impact"
    dissent_instruction: "Look for decisions that optimize one domain at the expense of others."
default_panel:
  - business-advisor
  - career-coach
  - financial-advisor
  - life-coach
default_depth: standard
artifact_type_verdicts:
  opportunity-candidate:
    scale:
      - strong
      - promising
      - neutral
      - cautionary
      - reject
    numeric: [4, 3, 2, 1, 0]
  signal-note:
    scale:
      - high-signal
      - useful
      - neutral
      - low-signal
      - noise
    numeric: [4, 3, 2, 1, 0]
  architectural-decision:
    scale:
      - strongly-support
      - support
      - neutral
      - concern
      - oppose
    numeric: [4, 3, 2, 1, 0]
sensitivity_defaults:
  opportunity-candidate: internal
  signal-note: internal
  architectural-decision: internal
  account-dossier: sensitive
  career-choice: sensitive
retry:
  max_attempts: 3
  backoff_seconds: [2, 5]
  retry_on: [429, 500, 502, 503]
curl_timeout: 120
prompt_size_limit_tokens: 30000
min_panel_size: 3
experimental_force_pass_2: true
---

# Deliberation Configuration

Model configuration, evaluator registry, and runtime settings for the multi-agent deliberation framework.

**Edit this file to change models, endpoints, evaluator assignments, or runtime behavior.** The deliberation skill and dispatch agent read these values at invocation time.

**Relationship to peer-review-config.md:** Same format and model lineup, different evaluator structure. Peer review uses generic reviewers; deliberation maps evaluator roles to specific models with overlays and persona biases.

**Model-role assignment rationale (from spec SS7.2):**
- GPT-5.4 -> Business Advisor: structured analysis and completeness
- Gemini 3.1 Pro -> Career Coach: integration gap identification
- DeepSeek V3.2 -> Financial Advisor: structural/logical analysis
- Grok 4.1 Fast -> Life Coach: edge cases and unconventional perspectives

These assignments are starting hypotheses evaluated in Phase 1 (H1/H2). Reshuffling based on empirical results is expected.

**Model version updates** (e.g., GPT-5.4 -> GPT-5.5) are config-level changes — update this file, not the spec. If a model is deprecated mid-experiment, update and note in the run-log.

**Verdict scale variants:** The `artifact_type_verdicts` section maps artifact types to domain-appropriate verdict labels. The numeric mapping is invariant (0-4) — split-check logic operates on numbers. If no type-specific scale is configured, `opportunity-candidate` (default) applies.

**Sensitivity classification:** `sensitivity_defaults` provides the default classification per artifact type. Danny confirms or overrides before dispatch. Sensitive artifacts require explicit opt-in.

**Experimental flags:**
- `experimental_force_pass_2`: Forces Pass 2 on all deliberations regardless of split detection. Activates in Phase 2 (H3 testing). Default: false.

**Format constraints (for deterministic shell extraction):**
- No nesting beyond two levels for model config (e.g., `models.openai.model` is max depth)
- Evaluator registry nests to two levels (e.g., `evaluator_registry.business-advisor.provider`)
- Single-line values only for all fields except persona_bias and dissent_instruction
- Arrays use YAML sequence syntax
- No anchors, aliases, or complex YAML features
