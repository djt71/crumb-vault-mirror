---
type: config
domain: software
status: active
created: 2026-02-24
updated: 2026-02-26
models:
  anthropic:
    model: claude-opus-4-6
    endpoint: https://api.anthropic.com/v1/messages
    env_key: ANTHROPIC_API_KEY
    max_tokens: 8192
    api_format: anthropic
    namespace: ANT
    prompt_addendum: >
      You are reviewing code written by a solo developer learning software engineering
      through hands-on projects. Prioritize findings that prevent bugs and improve
      maintainability. Flag patterns that would cause problems at scale, but don't
      over-engineer suggestions for a personal project context.
  codex:
    model: gpt-5.3-codex
    execution: cli
    sandbox: read-only
    namespace: CDX
    prompt_addendum: >
      Run the project's type checker and test suite before reviewing.
      Ground your findings in actual tooling output — cite compiler errors,
      test failures, or linter violations when they support a finding.
      Verify that functions referenced in the diff exist and have the
      expected signatures. Reference specific tool output in your findings.
    codex_flags:
      - "--sandbox"
      - "read-only"
      - "--json"
      - "--ephemeral"
    codex_timeout: 180
default_reviewers:
  - anthropic
  - codex
diff_thresholds:
  chunk_lines: 800
  max_lines: 2500
budget_warning_tokens: 100000
retry:
  max_attempts: 3
  backoff_seconds: [2, 5]
  retry_on: [429, 500, 502, 503]
curl_timeout: 120
---

# Code Review Configuration

Model configuration for the code-review skill's review panel. Two reviewers:
Claude Opus (API dispatch) and Codex (CLI dispatch).

**Edit this file to change models, endpoints, or panel composition.**
The skill reads these values at invocation time.

## Panel

**Anthropic (Claude Opus 4.6):** Architectural reasoning, contract analysis,
security design, intent comprehension. Dispatched via raw Anthropic Messages API.
Zero false positives in calibration. Strongest unique findings.

**Codex (GPT-5.3-Codex):** Tool-grounded review. Runs inside the repo with
read-only sandbox — executes type-checker, test suite, and linter. Findings cite
actual compiler/test output. Dispatched via `codex exec` CLI.

**Finding ID namespaces:** `ANT-F1` (Anthropic), `CDX-F1` (Codex).

## Codex CLI Requirements

Codex CLI must be installed on the host machine:
```bash
npm i -g @openai/codex
```

Authentication: ChatGPT login (`codex login`, cached at `~/.codex/auth.json`)
is the primary path — included with ChatGPT Plus subscription. If `OPENAI_API_KEY`
is set in `~/.config/crumb/.env`, the dispatch agent sets `CODEX_API_KEY` as an
override for API-key auth (pay-as-you-go fallback when subscription quota is exhausted).

**Sandbox:** `read-only` is the default for `codex exec`. Codex can read all
files and run commands (type-checker, tests, linters) but cannot modify files.
This is sufficient for review.

**AGENTS.md:** For best results, ensure the target repo has an `AGENTS.md` at
its root with project conventions, test runner, and language/framework info.
Codex loads this automatically before processing the prompt.

## Cost

- **Claude Opus:** Standard Anthropic API pricing. Typical review: ~3k input,
  ~3k output tokens. Verify at https://www.anthropic.com/pricing.
- **Codex:** Authenticated via ChatGPT Plus ($20/mo subscription), included in
  30-150 local messages per 5-hour window. If `OPENAI_API_KEY` is set in `.env`,
  API-key auth is used instead (pay-as-you-go at standard OpenAI rates — useful
  as overflow). Typical review: 30-90 seconds including tool execution.

**Budget gate:** `budget_warning_tokens: 100000` — if estimated total input
tokens exceeds this, the SKILL coordinator prompts for confirmation.

## Calibration Notes

### Anthropic (Claude Opus 4.6)
Based on crumb-tess-bridge review (107-line Python diff, 2026-02-24):
- **Latency:** ~30s | **Tokens:** 3,203 in / 3,124 out
- **Findings:** 9 | **False positives:** 0 | **S/N:** 100%
- **Strengths:** Architectural reasoning, contract analysis (caught `validate_schema`
  mutation that other reviewers missed), security design concerns, zero noise.
- **Profile:** Best for architectural and contract-level analysis.

### Codex (GPT-5.3-Codex)
Smoke test data (2026-02-26, Codex v0.105.0):
- **x-feed-intel:** `tsc --noEmit` clean, 16 test files found, 1,844 tokens, <1s tool execution
- **feed-intel-framework:** `tsc --noEmit` clean, correctly diagnosed test runner issue
  (TS files need `npx tsx --test`, not `node --test` — pinpointed ESM loader root cause)
- **Profile:** Tool execution is fast and diagnostic output is precise. Correctly identifies
  root causes rather than just reporting failures.
- **Calibrate after ~5 reviews:** Track unique findings, false positive rate, tool usage patterns.

## Relationship to Peer Review Config

This config is separate from `_system/docs/peer-review-config.md`. Peer review
handles prose artifacts (specs, designs, architecture docs). This config handles
code review. The two share the dispatch pattern and safety gate but have different
panels, prompts, and evaluation criteria.
