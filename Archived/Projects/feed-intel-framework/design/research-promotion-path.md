---
type: design-note
status: active
project: feed-intel-framework
domain: software
created: 2026-02-23
updated: 2026-02-25
skill_origin: null
---

# Research Promotion Path

## Context

The `research` command produces research summaries in `_openclaw/feeds/research/`. These files are part of the pipeline's operational record — compound insight routing, lineage tracking, and dedup all reference them. Research findings with genuinely useful content (actionable ops items, architecture patterns, external references, durable knowledge) need a path into the vault's knowledge base (`Sources/`).

This is a framework-level concern — any adapter's research flow has the same problem. The design is source-agnostic and carries forward from x-feed-intel into FIF.

## Resolved Design Decisions

### 1. Disposition: frontmatter lineage, not file moves

Research notes stay in `_openclaw/feeds/research/`. Promoted notes get a `promoted_to:` frontmatter field pointing to the Sources/ artifact. This preserves the operational record, keeps compound insight routing intact, and provides dedup (don't promote twice).

```yaml
promoted_to: Sources/articles/koe-multiple-interests
promoted_at: 2026-02-25
```

### 2. Trigger: dual-path (operator-initiated + automated flagging)

**Primary path — operator-initiated:** Operator reads research output and says "promote this." Crumb converts the research note into a properly frontmattered knowledge note in `Sources/` and adds the `promoted_to:` lineage field. This is the quality gate.

**Discovery path — automated flagging:** The research process evaluates findings and sets `promotion_candidate: true` in frontmatter when flagging criteria are met (see §6). The digest annotation surfaces this as a recommendation where the operator's attention already lives.

### 3. Surfacing layers (ordered by friction)

1. **Digest annotation (load-bearing):** When research completes with `promotion_candidate: true`, the next digest includes `⭐ Promotion candidate — review for KB` next to that item. This is the primary discovery mechanism — the operator reads the digest daily, so recommendations surface in the existing attention flow. Zero extra effort. If this layer works, most promotions are caught here.
2. **Telegram `save` command:** Operator replies `{ID} save` from the digest to trigger promotion directly. Collapses the gap between "I see something worth keeping" and "it's in the knowledge base" to a single reply. **Behavioral note:** `save` on a promotion candidate triggers full promotion (create index + digest in Sources/, add lineage to research note) — not a queue. The operator has already reviewed it via the digest; queuing adds nothing.
3. **Session startup scan (safety net, build last):** Glob `_openclaw/feeds/research/*.md`, check for `promotion_candidate: true` without `promoted_to:`. Same pattern as compound insight scan. Low priority — if layers 1 and 2 work well, this rarely triggers. Build only if candidates are slipping through.

### 4. Decision authority: always operator-confirmed

No auto-promotion to the knowledge base. The research process recommends (via `promotion_candidate` flag); the operator confirms. This is a quality gate that stays human.

### 4. What gets promoted

The promotion creates a standard Sources/ artifact pair:

- **Source index** (`[source-id]-index.md`, type: `source-index`) — landing page with overview, notes table, connections
- **Knowledge note** (`[source-id]-digest.md`, type: `knowledge-note`) — full digest adapted from research content into the standard schema (Core Thesis, Key Arguments, Key Concepts, Takeaways, Connections, etc.)

Both use `skill_origin: research-promotion` to distinguish from the inbox-processor pipeline. Tagged `needs_review` per convention. `#kb/` tags are drawn from the research note's existing tags (canonical tags only).

### 5. Where it lands

`Sources/[type]/` — same directory structure as the NotebookLM pipeline. Source type is inferred from the original content (article, video, paper, etc.). No new locations to manage.

### 6. Promotion candidate signals (start conservative)

Flag `promotion_candidate: true` when ALL of:
- Research confidence is high
- Content has **2+ vault cross-references** (wikilinks to existing vault artifacts)

And at least one of:
- Findings contain durable reference material or architecture patterns
- Content connects to multiple domains or projects
- Actionable items with lasting relevance (not time-bound ops fixes)

Flag `promotion_candidate: false` (or omit) when:
- Findings are purely informational with no vault connections
- Content is ephemeral (time-bound ops items, already-resolved issues)
- Negative results that confirm existing decisions without adding new knowledge
- Only 0-1 vault cross-references (insufficient signal of vault relevance)

**Calibration note:** If >30% of research outputs get flagged as promotion candidates, the threshold is too loose — the digest annotation loses its signal. Same failure mode as compound insight perishable over-indexing. Start tight, loosen only if the operator is frequently manually promoting things the system didn't flag.

## First Promotion (Reference Implementation)

**Source:** Dan Koe — "If You Have Multiple Interests, Do Not Waste the Next 2-3 Years"
**Research note:** `_openclaw/feeds/research/research-2010042119121957316-thedankoe-multiple-interests-20260225.md`
**Promoted to:** `Sources/articles/koe-multiple-interests-{index,digest}.md`
**Date:** 2026-02-25

This was operator-initiated (read research, decided to promote). The research note was not flagged as `promotion_candidate` — that field didn't exist yet when the research was dispatched.

## Origin

Surfaced during x-feed-intel digest amendment implementation (2026-02-23). First concrete case: A18 research on OpenClaw session bloat — useful ops findings with no durable capture path. Design decisions resolved 2026-02-25 during first actual promotion.
