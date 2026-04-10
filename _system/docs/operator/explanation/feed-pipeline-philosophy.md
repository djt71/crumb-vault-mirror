---
type: explanation
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Feed Pipeline Philosophy

The feed-intel pipeline isn't a news aggregator. It's a content intelligence system designed to surface signal from noise and route it to where it compounds. This explains the design rationale.

**Architecture source:** [[03-runtime-views]] §Feed Pipeline, [[skills-reference]] §feed-pipeline

---

## The Problem It Solves

Information arrives constantly — X threads, RSS feeds, YouTube videos, Hacker News posts, arXiv papers. Most of it is noise. Some of it is genuinely valuable. The valuable pieces are useless if they sit in a feed reader — they need to land in the vault where they connect to existing knowledge, inform active projects, and compound over time.

The pipeline exists to make that routing automatic for high-confidence items and low-friction for everything else.

---

## Promote / Skip / Delete

Every item in the pipeline eventually gets one of three dispositions:

| Action | Meaning | Vault Effect |
|--------|---------|-------------|
| **Promote** | This is durable knowledge worth preserving | Signal-note created in `Sources/signals/`, tagged, linked to MOC |
| **Skip** | Not relevant now, not worth preserving | Removed from queue, no vault trace |
| **Delete** | Noise, spam, or duplicate | Purged from pipeline |

The three-action model is intentionally simple. There's no "save for later" or "maybe" — those categories accumulate and never get resolved. Every item moves forward or gets dismissed.

---

## The Tier System

The FIF triage (upstream of Crumb) classifies items into tiers:

**Tier 1 — Capture candidates.** High priority, high confidence, recommended action is "capture." These are the items most likely to become durable vault knowledge. The feed-pipeline skill evaluates permanence (durable vs. timely?) and tag mapping before promoting.

**Tier 2 — Action items.** The content isn't knowledge to preserve — it's a specific action to take (test something, add to a spec, investigate further). These get extracted as one-line actions and routed to active projects.

**Tier 3 — Background signal.** Low priority or low confidence. Not processed individually — logged for calibration only. The aggregate pattern of Tier 3 items tells you whether the upstream classifier is calibrated correctly.

The tier system means the operator's attention goes to Tier 1 and 2. Tier 3 is invisible by default.

---

## Why Permanence Matters

Not every high-priority item deserves a vault note. The permanence evaluation asks four questions:

1. **Durable or timely?** A reusable pattern or framework is durable. A product launch announcement is timely. Timely items skip unless they represent a lasting shift.

2. **Canonical `#kb/` tag?** If the item can't be mapped to the existing tag taxonomy, it either doesn't fit the vault's knowledge structure or the taxonomy needs extending. Both are worth flagging.

3. **Vault dedup?** If the vault already covers this ground, a duplicate note adds noise without signal.

4. **Project applicability?** If the item is directly relevant to an active project, it might be better as a run-log cross-post than a standalone signal-note.

These questions filter the items that look valuable at first glance but don't actually compound in the vault.

---

## The Circuit Breaker

If more than 10 Tier 1 items arrive in a single batch, the pipeline stops auto-promoting and routes everything to the review queue. This is the circuit breaker.

The rationale: a sudden spike in high-priority items usually means the upstream classifier is drifting (being too generous with "high confidence"), not that 10+ genuinely durable knowledge items arrived simultaneously. The operator reviews the batch and recalibrates.

---

## Connection to Attention Management

The feed pipeline doesn't exist in isolation. It's one input to the broader attention management system:

- **Feed pipeline** captures external knowledge → `Sources/signals/`
- **Attention manager** synthesizes priorities from goals, projects, and captured knowledge → daily focus plans
- **AKM** surfaces relevant vault knowledge during Crumb sessions → compound connections

Signal-notes from the feed pipeline become AKM candidates. A security article captured today might surface during a project session next week because AKM detects the cross-domain relevance. The pipeline's value isn't just in what it captures — it's in what that capture enables downstream.

---

## Why Not Full Automation?

The pipeline could theoretically run end-to-end without human involvement: capture → classify → evaluate permanence → promote → tag → register in MOC. The technology supports it.

It doesn't, for two reasons:

**False positive cost is high.** A bad signal-note pollutes the knowledge base. It gets surfaced by AKM, referenced in compound evaluations, and linked by MOCs. Removing it later means chasing down all those connections. Prevention (human review of borderline items) is cheaper than cleanup.

**Calibration requires feedback.** The operator's skip/promote decisions are implicit feedback on the upstream classifier. Without human-in-the-loop at the promotion step, classifier drift goes undetected until the knowledge base is visibly degraded.

The feed-pipeline's design reflects a broader Crumb principle: automate the mechanical parts, keep humans in the loop for judgment calls, and build feedback loops that improve the system over time.
