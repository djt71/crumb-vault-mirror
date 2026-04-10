---
type: design
project: feed-intel-framework
domain: software
status: active
created: 2026-02-26
updated: 2026-02-26
tags:
  - rss
  - feed-intel
---

# RSS Feed List — FIF-030 Phase 0 Validation

## Summary

15 feeds validated across 7 categories. 12 confirmed working, 3 failed (Anthropic, Reuters, History Today — replaced with alternatives). Parser: `rss-parser@3.13.0`. Sample normalization to UnifiedContent passed on 8/8 items across 4 feeds.

## Validated Feed List

| # | Name | URL | Format | Category | Tier | Content | Frequency | Status |
|---|------|-----|--------|----------|------|---------|-----------|--------|
| 1 | Simon Willison | `simonwillison.net/atom/everything/` | Atom | Tech blog | standard | Full text in `summary` | Daily | OK |
| 2 | Julia Evans | `jvns.ca/atom.xml` | Atom | Tech blog | standard | Full text in `content` (11K+ chars) | Weekly | OK |
| 3 | Hugging Face Blog | `huggingface.co/blog/feed.xml` | RSS | AI/Agentic | lightweight | Summary-only (740 items!) | Daily | OK |
| 4 | arxiv cs.AI | `rss.arxiv.org/rss/cs.AI` | RSS | LLM research | lightweight | Abstracts only (222 items/day) | Daily | OK |
| 5 | Ars Technica | `feeds.arstechnica.com/.../technology-lab` | RSS | Industry news | standard | Full text via `content:encoded` | Daily | OK |
| 6 | HN Frontpage | `hnrss.org/frontpage` | RSS | Tech news | lightweight | Links + HN metadata | Daily | OK |
| 7 | History Extra | `historyextra.com/feed/` | RSS | History | standard | Full text via `content:encoded` | Daily | OK |
| 8 | Daily Nous | `dailynous.com/feed/` | RSS | Philosophy | standard | Full text via `content:encoded` | Daily | OK |
| 9 | Aeon Magazine | `aeon.co/feed` | RSS | Philosophy | lightweight | Summary-only | Daily | OK |
| 10 | Hackaday | `hackaday.com/feed/` | RSS | Maker | standard | Full text via `content:encoded` | Daily | OK |
| 11 | Raspberry Pi | `raspberrypi.com/news/feed/` | RSS | Maker | standard | Full text via `content:encoded` | Weekly | OK |
| 12 | BBC World | `feeds.bbci.co.uk/news/world/rss.xml` | RSS | Global news | lightweight | Summary-only (125 chars) | Daily | OK |
| 13 | NPR News | `feeds.npr.org/1001/rss.xml` | RSS | Global news | standard | Has content | Daily | OK |
| 14 | ESPN Top Headlines | `espn.com/espn/rss/news` | RSS | Sports | lightweight | Summary-only | Daily | OK |

### Failed Candidates (Replaced)

| Name | URL Tested | Issue | Replacement |
|------|-----------|-------|-------------|
| Anthropic Research | anthropic.com/rss.xml, /feed.xml, /blog/rss, /news/rss | All 404 — no public RSS feed | Follow via X adapter |
| Reuters | reutersagency.com/feed/ | 404 | NPR News |
| History Today | historytoday.com/feed/rss.xml | Returns HTML, not RSS | History Extra |

### Additional Candidates Tested

| Name | URL | Result | Decision |
|------|-----|--------|----------|
| Smithsonian History | smithsonianmag.com/rss/history/ | OK (1 item) | Skip — low volume |
| Philosophy Now | philosophynow.org/rss | OK (30 items, summary) | Skip — Daily Nous + Aeon covers philosophy |
| Stanford Phil Encyclopedia | plato.stanford.edu/rss/sep.xml | OK (15 items, summary) | Skip — reference material, not news |

## Parser Library Selection

**Selected: `rss-parser@3.13.0`**

| Criterion | Assessment |
|-----------|------------|
| RSS 2.0 support | Confirmed — Hackaday, BBC, ESPN, etc. |
| Atom support | Confirmed — Simon Willison, Julia Evans |
| TypeScript support | Full generic typing with custom field support |
| Custom fields | `content:encoded`, `dc:creator` extracted via `customFields` config |
| Date normalization | `isoDate` field normalizes across both RSS pubDate and Atom published |
| Error handling | Timeout support, graceful failure on parse errors |
| Size/deps | 5 packages added, minimal footprint |

### Field Mapping Reference

| UnifiedContent Field | RSS 2.0 Source | Atom Source |
|---------------------|----------------|-------------|
| `content.title` | `item.title` | `entry.title` |
| `content.full_text` | `contentEncoded` or `content` (>500 chars) | `content` or `summary` (>500 chars) |
| `content.excerpt` | `contentSnippet` (plain text) | `contentSnippet` |
| `metadata.created_at` | `isoDate` | `isoDate` |
| `author.display_name` | `creator` / `dcCreator` | (often absent) |
| `metadata.platform_url` | `item.link` | `entry.link` |
| `canonical_id` | `rss:sha256(canonicalizeUrl(link))[:16]` | same |
| `content.url_hash` | `sha256(canonicalizeUrl(link))[:16]` | same |

## Tier Assignment Rationale

**Standard tier** (full article text available for triage):
- Julia Evans, Hackaday, Raspberry Pi, Daily Nous, Ars Technica, History Extra, NPR News, Simon Willison

**Lightweight tier** (title + excerpt only):
- BBC World, ESPN, HN Frontpage, Hugging Face, arxiv cs.AI, Aeon Magazine

Tier is applied per-item at normalization time: feeds with `content:encoded` or substantial `content` get `effective_tier: null` (inherit manifest default of standard); summary-only items get `effective_tier: 'lightweight'`.

## Volume Estimate

| Category | Feeds | Est. items/day | Tier |
|----------|-------|----------------|------|
| Tech blogs | 2 | 3–5 | standard |
| AI/Agentic | 1 | 5–10 | lightweight |
| LLM research | 1 | 50–200+ | lightweight |
| Industry news | 2 | 20–30 | mixed |
| History | 1 | 3–5 | standard |
| Philosophy | 2 | 3–5 | mixed |
| Maker | 2 | 5–10 | standard |
| Global news | 2 | 20–40 | mostly lightweight |
| Sports | 1 | 15–25 | lightweight |
| **Total** | **14** | **~125–330** | |

arxiv cs.AI is the high-volume outlier at 200+ items/day. The `max_items_per_feed: 50` cap in config limits intake to a manageable level.

## Cost Projection

RSS has no API costs. Triage-only costs at ~$0.002/item (lightweight) to ~$0.005/item (standard):
- Conservative: 100 items/day × $0.003 avg × 30 days = **$9.00/month**
- With caps: 150 items/cycle cap → **~$5-8/month** realistic
- Spending cap set at $0.50/month as initial guard — will need adjustment based on actual volume

**Note:** The $0.50 spending cap in the manifest is intentionally conservative for Phase 0. Will adjust upward in FIF-031 based on actual triage costs observed during testing.
