---
type: research
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-22
source: claude-ai-session
tags:
  - prompt-caching
  - cost-optimization
  - soul-md
  - system-prompt
  - tess
---

# Prompt Caching & System Prompt Optimization — Research Note

**Date:** 2026-02-22
**Context:** The cost analysis assumes prompt caching is in place. This note documents how caching works, why it matters for Tess's cost model, and identifies system prompt optimization as a follow-on task.

## 1. How Prompt Caching Works

The Claude API is stateless. Every request sends the full prompt from scratch — system instructions, tool definitions, conversation history, user message. For an always-on agent like Tess, this means SOUL.md, IDENTITY.md, and ~40 tool definitions are resent on every single interaction.

Prompt caching lets you mark a prefix of the prompt as cacheable:

- **Cache write (first request):** 1.25x base input price (25% premium) for default 5-minute TTL, or 2x base input price for 1-hour TTL
- **Cache read (subsequent requests):** 0.1x base input price (90% discount)
- **Cache TTL:** 5 minutes default, refreshed on every hit. 1-hour option available at higher write cost.
- **Cache matching:** Exact prefix match required. Any change to the cached content invalidates it.
- **Up to 4 cache breakpoints** per request
- **No effect on output:** Cached prompts produce identical responses to uncached. The optimization is purely computational.

## 2. Why This Is Critical for Tess

### The system prompt dominates input costs

Estimated system prompt composition for `tess-voice`:

| Component | Est. tokens | Changes how often |
|-----------|------------|-------------------|
| SOUL.md | ~2,000–3,000 | Rarely (design artifact) |
| IDENTITY.md | ~500–1,000 | Rarely |
| Tool definitions (~40 tools) | ~4,000 | On OpenClaw updates |
| Routing/system instructions | ~1,500 | On config changes |
| **Total static prefix** | **~8,000–9,500** | **Stable across requests** |

At 135 requests/day, the static prefix accounts for ~1.15M tokens/day of input. Without caching, that's $1.15/day on Haiku ($1/M). With caching at 0.1x, it's $0.115/day. That's the difference between ~$35/month and ~$3.50/month on system prompt alone.

### The 5-minute TTL creates a heartbeat problem

Default cache TTL is 5 minutes, refreshed on each hit. Heartbeats at 15- or 30-minute intervals mean the cache expires between every heartbeat. Each heartbeat pays the full cache write cost instead of a cache read.

At 96 heartbeats/day, every one paying a cache write instead of a read wastes the caching benefit on the highest-volume request type.

**Mitigation options:**

| Option | Trade-off |
|--------|-----------|
| 1-hour cache TTL | Higher write cost (2x instead of 1.25x), but reads stay at 0.1x. Cache survives 30-min heartbeat intervals. Net cheaper if heartbeat frequency < 1/hour. |
| Reduce heartbeat interval to ≤5 min | Keeps default cache warm but increases total request count and API costs. Counterproductive. |
| Separate heartbeat model (local) | `tess-mechanic` handles heartbeats locally — no API cost at all. Cache only needs to stay warm for user-facing interactions, which cluster in active-use periods. **This is the strongest argument for the two-agent split from a caching perspective.** |

### The two-agent split optimizes caching naturally

With `tess-voice` (cloud) and `tess-mechanic` (local):

- `tess-voice` only fires on user-initiated interactions, which tend to cluster (multiple messages in a conversation). The 5-minute default TTL is likely sufficient during active use — messages come faster than every 5 minutes when you're in a conversation.
- `tess-mechanic` runs heartbeats locally — zero API cost, no cache concern.
- Between active-use periods, the cache expires naturally. The next conversation pays one cache write, then reads for the rest of the session.

This makes the 1-hour TTL unnecessary in most usage patterns, saving the 2x write premium.

## 3. System Prompt Optimization

### The case for compressing SOUL.md and IDENTITY.md

Every token in the system prompt is multiplied by every request. The cost and context window impact is linear:

| System prompt size | Daily input (135 req, cached) | Monthly cost (Haiku) | Context available for conversation |
|-------------------|------------------------------|---------------------|------------------------------------|
| 9,500 tokens | ~1.28M tokens | ~$3.85 | 190,500 tokens |
| 6,000 tokens | ~810K tokens | ~$2.43 | 194,000 tokens |
| 3,500 tokens | ~473K tokens | ~$1.42 | 196,500 tokens |

The cost savings from compression are modest in absolute terms (~$2.40/month between 9.5K and 3.5K). The bigger win is context window preservation — a shorter system prompt leaves more room for conversation history, tool results, and vault content in multi-turn interactions.

### What to compress

Not all system prompt content is equally load-bearing. Categories:

**High-value (keep):**
- Core voice directives (tone, register, response patterns)
- Boundary definitions (what Tess does vs doesn't do)
- Safety invariants (confirmation echo, ambiguity handling)
- Tool schema definitions (required for function calling)

**Medium-value (compress):**
- Example responses (could be reduced to 1-2 instead of several)
- Philosophical framing (effective but may be achievable with less text)
- Detailed second-register guidance (may work as a shorter instruction)

**Low-value (cut or move):**
- Background/design rationale (useful for humans reading the doc, not for the model)
- Redundant instructions (same directive stated multiple ways)
- Aspirational statements that don't change model behavior

### How to validate compression

Use the persona evaluation rubric (from R2 peer review) as the test:

1. Run the existing 10+ representative interactions against the current full SOUL.md
2. Score against the rubric (second register, humor, ambiguity handling, tone calibration, etc.)
3. Create compressed version
4. Run the same interactions against the compressed version
5. Compare scores — if no meaningful degradation, the compression is safe

This should sequence **after** the persona evaluation (which determines Haiku vs Sonnet) and **before** the config draft (which locks the system prompt).

### `tess-mechanic` system prompt

The mechanical agent doesn't need SOUL.md at all. A minimal operational identity:

- Role: background task executor for Tess
- Constraints: structured output only, no user-facing text, confirmation echo compliance
- No persona, humor, tone guidance, or second register

Estimated size: 200–300 tokens. Negligible cost and context impact.

## 4. Assumptions for the Spec

The cost analysis assumes:

- **A1: Prompt caching is available and configured.** Without caching, the $8.70/month estimate balloons to ~$40/month. Caching is a prerequisite, not an optimization.
- **A2: OpenClaw either supports `cache_control` natively or can be configured to include it.** If OpenClaw's API calls to Anthropic don't include cache control headers, this needs to be added — either via OpenClaw config, a middleware layer, or a feature request.
- **A3: The two-agent split eliminates the heartbeat caching problem.** With heartbeats on local, the cloud model's cache only needs to survive between user-initiated messages, which cluster in active-use periods.

## 5. Spec Integration

This research should inform:

- **Facts:** Prompt caching pricing structure, 5-min vs 1-hour TTL, cache behavior with heartbeat intervals
- **Assumptions:** Caching available and configured (prerequisite for cost model)
- **Unknowns:** Whether OpenClaw passes `cache_control` to the Anthropic API natively
- **Cost Model (§11):** Reference caching as the mechanism that makes cloud-primary viable
- **Task list:** Add system prompt optimization task, sequenced after persona evaluation and before config draft. Add cache configuration verification task.
- **Architecture (§7):** Note that the two-agent split has a caching benefit beyond routing — it eliminates heartbeat cache pollution

## Sources

- Anthropic prompt caching docs: `platform.claude.com/docs/en/build-with-claude/prompt-caching`
- Anthropic prompt caching announcement: `anthropic.com/news/prompt-caching`
- Claude docs: `docs.claude.com/en/docs/build-with-claude/prompt-caching`
- Pricing: cache writes 1.25x (5-min) or 2x (1-hour) base input; cache reads 0.1x base input
