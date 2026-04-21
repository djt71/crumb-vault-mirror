---
project: null
domain: software
type: pattern
skill_origin: peer-review
status: active
track: pattern
confidence: high
created: 2026-02-18
updated: 2026-04-04
tags:
  - peer-review
  - api-integration
  - kb/software-dev
topics:
  - moc-crumb-operations
---

# Reasoning-Model Token Budget

## Problem

Models with chain-of-thought reasoning (e.g., Perplexity `sonar-reasoning-pro`) consume
the `max_tokens` budget with internal reasoning tokens (`<think>` blocks) before producing
visible output. Setting `max_tokens` to the desired output length results in truncated
responses because the reasoning overhead is invisible to the caller but counts against the
budget.

## Evidence

Discovered during OpenClaw colocation peer review (2026-02-18):

| max_tokens | Result |
|------------|--------|
| 8,192 | Severely truncated — reasoning consumed nearly all budget |
| 16,384 | Still truncated — reasoning overhead exceeded 2x |
| 65,536 | Full output — sufficient headroom for reasoning + response |

The API ceiling for `sonar-reasoning-pro` is 128k tokens. The actual review output was
~4,000 tokens, meaning reasoning consumed ~12,000+ tokens (3x the output).

## Rule

For any reasoning model with chain-of-thought (Perplexity Sonar Reasoning Pro, and
potentially others with `<think>` or similar reasoning blocks):

**Set `max_tokens` to at least 4x the expected output length.**

This accounts for reasoning overhead that varies by prompt complexity. The 4x multiplier
provides sufficient headroom without hitting API ceilings on most providers.

## Scope

Applies to any API call where:
- The model performs internal reasoning before responding
- Reasoning tokens count against `max_tokens`
- The caller cannot predict reasoning length in advance

Currently confirmed for: Perplexity `sonar-reasoning-pro`.
Potentially applies to: any model exposing chain-of-thought via token budget.

## Resolution

Updated `docs/peer-review-config.md` with `max_tokens: 65536` for Perplexity and added
inline comments explaining the reasoning-token overhead.
