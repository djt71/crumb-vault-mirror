---
type: analysis
project: tess-model-architecture
domain: software
status: active
created: 2026-02-22
updated: 2026-02-22
source: claude-ai-session
tags:
  - cost-analysis
  - haiku
  - tess
  - tiering
---

# Haiku 4.5 Cost Analysis for Tess — All Interactions

## Pricing

- **Input:** $1.00 / 1M tokens
- **Output:** $5.00 / 1M tokens
- **Prompt caching (read):** $0.10 / 1M tokens (90% savings on cached input)
- **Batch API:** 50% discount (not applicable — Tess needs real-time responses)

## Token Estimation Per Interaction Type

Estimating tokens per interaction based on Tess's workload from the research thread.

### System prompt overhead (every request)

Tess loads: SOUL.md, IDENTITY.md, tool definitions, conversation history.

| Component | Est. tokens |
|-----------|------------|
| SOUL.md + IDENTITY.md | ~3,000 |
| OpenClaw tool definitions (~40 tools) | ~4,000 |
| System instructions / routing context | ~1,500 |
| **System prompt total** | **~8,500** |

With prompt caching, this drops to ~$0.00085 per request instead of ~$0.0085.
**Caching is a 10x reduction on the fixed overhead — essential.**

### Interaction types and volumes

| Type | Input tokens (ex. system) | Output tokens | Frequency | Daily count |
|------|--------------------------|---------------|-----------|-------------|
| Heartbeat / cron check | ~200 | ~100 | Every 15 min | 96 |
| Quick capture ("add X to inbox") | ~300 | ~150 | Ad hoc | ~10 |
| Message triage / response | ~500 | ~400 | Ad hoc | ~15 |
| Status query ("what's on today") | ~400 | ~600 | Ad hoc | ~5 |
| Daily briefing | ~800 | ~1,500 | 1x/day | 1 |
| Directive execution (multi-step) | ~1,000 | ~800 | Ad hoc | ~3 |
| Vault lookup + summary | ~600 | ~500 | Ad hoc | ~5 |

## Daily Cost Calculation

### Without prompt caching

| Type | Count | Input tokens/req | Output tokens/req | Daily input | Daily output |
|------|-------|-------------------|--------------------|----|---|
| System prompt (per req) | 135 | 8,500 | 0 | 1,147,500 | 0 |
| Heartbeat | 96 | 200 | 100 | 19,200 | 9,600 |
| Quick capture | 10 | 300 | 150 | 3,000 | 1,500 |
| Message triage | 15 | 500 | 400 | 7,500 | 6,000 |
| Status query | 5 | 400 | 600 | 2,000 | 3,000 |
| Daily briefing | 1 | 800 | 1,500 | 800 | 1,500 |
| Directive execution | 3 | 1,000 | 800 | 3,000 | 2,400 |
| Vault lookup | 5 | 600 | 500 | 3,000 | 2,500 |
| **Totals** | **135** | | | **1,186,000** | **26,500** |

**Daily cost (no caching):** ($1.186 × $1.00) + ($0.0265 × $5.00) = **$1.32/day**
**Monthly (no caching):** ~**$39.60/month**

### With prompt caching

System prompt cached at $0.10/M instead of $1.00/M:
- Cached system prompt cost: 1,147,500 tokens × $0.10/M = $0.115/day
- Non-cached input: 38,500 tokens × $1.00/M = $0.039/day
- Output: 26,500 tokens × $5.00/M = $0.133/day

**Daily cost (with caching):** $0.115 + $0.039 + $0.133 = **$0.29/day**
**Monthly (with caching):** ~**$8.70/month**

## Sensitivity Analysis

### Light usage (weekday only, fewer ad-hoc interactions)

- 96 heartbeats + ~15 manual interactions/day × 22 workdays
- Monthly with caching: ~**$5-6/month**

### Heavy usage (more directives, longer conversations, weekends)

- 96 heartbeats + ~60 manual interactions/day × 30 days
- Monthly with caching: ~**$15-20/month**

### If Sonnet 4.5 were used instead (for comparison)

- Input: $3.00/M, Output: $15.00/M
- Daily with caching: ~$0.75/day → ~**$22.50/month**
- Without caching: ~$3.70/day → ~**$111/month**

## Key Observations

1. **The system prompt dominates input costs.** 8,500 tokens × 135 requests = 1.15M tokens/day just in system prompt repetition. Prompt caching is not optional — it's a 4.5x cost reduction.

2. **Output tokens cost 5x input.** Even though output volume is small (~26K tokens/day), it's roughly half the total cost. This is because Haiku's output pricing is $5/M vs $1/M input.

3. **Heartbeats are the volume driver.** 96/day × 365 = 35,040 heartbeats/year. If each costs ~$0.001 (cached), that's ~$35/year just for heartbeats. If the heartbeat interval could go from 15 min to 30 min, that halves to ~$17.50.

4. **At $8.70/month with caching, this is cheap.** For context, a Claude Pro subscription is $20/month. Running Tess on Haiku API with caching costs less than half that for an always-on agent.

5. **The real cost of local is electricity + hardware depreciation, not $0.** The Mac Studio draws ~50-80W under sustained inference load. At Michigan residential rates (~$0.18/kWh), that's ~$6.50-10.40/month in electricity for continuous inference. Plus wear on the SSD and thermal cycling. The delta between "free local" and "$8.70/month Haiku" is smaller than it appears.
