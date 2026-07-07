---
type: reference
domain: null
status: active
skill_origin: null
created: 2026-07-05
updated: 2026-07-05
tags:
  - cowork
  - feed-intel
  - handoff
---

# Feed Intel Framework → Cowork Handoff

**Origin:** `Archived/Projects/feed-intel-framework/` (archived 2026-07-05, operator
decision: another good-idea-poor-execution move to Claude Cowork, following
opportunity-scout and attention-manager). The project itself *completed* — Phase 1
(M1–M5) gate-passed 2026-03-26 — but its delivery mechanism died. Repos deleted at
archival (their independent git history destroyed, accepted per scout precedent); this
note plus the vault design docs are the durable extract. Pattern:
[[handoff-note-at-archival]].

> **Reboot built 2026-07-06:** [[cowork-feed-instructions]] is the canonical source for
> the Cowork "Feed Intel" project — interactive on-demand block plus a twice-weekly
> (Mon/Thu) Gmail-digest scheduled prompt (Class 0 outside-in delivery; the push survives,
> the room changes). Gated on verifying that connectors reach Cowork scheduled runs.
> X bookmarks source **dropped** (operator, 2026-07-06) — OAuth revocation proceeds with
> nothing depending on it.

**Governing frame:** feed intelligence is a discovery surface under Directive v3
Principle 5 — browse freely, no conversion obligation — on rented runtime (Principle 6).
Intake stays deliberately open; filtering belongs downstream (`feedback-feed-intel-stays-open`
memory — do not engineer strategic-fit filters at the source).

## Why the first execution failed

1. **Machinery class, same as scout:** five source adapters, a SQLite registry
   (`pipeline.db`), launchd scheduling across two service generations, Telegram
   delivery + feedback listener — all infrastructure a Cowork scheduled run replaces
   natively (fetch → curate → deliver, no state).
2. **Delivery-consumption mismatch:** Telegram digests stopped being read (operator,
   2026-05-28: "no longer useful"). The channel imposed a push cadence the operator
   didn't want to consume there.
3. **Routing to a doomed target:** the auto-capture bar routed high/high items to
   `_openclaw/inbox/`, whose 158-item backlog sat unprocessed and was discarded
   wholesale on 2026-06-11 when that inbox was consolidated away. Capture without a
   consuming practice is just deferred deletion.

## What survives (validated design — reuse it)

### The source roster
`Archived/Projects/feed-intel-framework/design/rss-feed-list.md` — 14 validated feeds
across 7 categories (tech blogs, AI/agentic, LLM research, industry news,
history/philosophy, maker, global news/sports), each with format, content tier, and
frequency. **Verified current against the operational config at archival (2026-07-05 —
zero drift).** Failed-candidate notes included (Anthropic has no public RSS; Reuters
and History Today dead). Non-RSS sources the pipeline also captured: X bookmarks
(needs X OAuth — being revoked, a Cowork reboot must re-solve or drop this source),
YouTube, HN front page, arXiv cs.AI; Reddit adapter was built but never credentialed.

### The triage rubric (extracted from the tuned production prompt)
This was the pipeline's real intelligence — months of calibration. Core elements,
verbatim where possible:

- **Identity:** "a personal intelligence curator… surface the most impactful, diverse,
  and actionable content — the kind that would change how Danny thinks, builds, works,
  or lives."
- **Budget:** ~25 items/day total across all sources; if >15% of a batch is HIGH, the
  bar is too low.
- **The impact test:** before marking HIGH — "Would Danny regret missing this? Would
  it change a decision, teach something new, or inspire action?" Tutorials for
  daily-use tools, restatements of vault-known patterns, and generic overviews are
  NOT high. Novelty AND actionability, both.
- **Domain diversity rule:** interests span software, career, learning, health,
  creative, spiritual/philosophical, financial. The best daily set is diverse — if one
  domain dominates a batch, raise its bar and look for value elsewhere.
- **Priority calibration:** high = top-25-today, ruthlessly selective · medium =
  default for solid-but-not-exceptional · low = noise, be aggressive ("a focused
  digest is more valuable than a comprehensive one").
- **Confidence gate:** only high-priority + high-confidence + capture-class action
  auto-routes to the vault; medium confidence goes to digest for manual review.
- **Semantic dedup:** one signal per pattern — mark the best version HIGH, downgrade
  same-pattern duplicates to MEDIUM.
- **Adaptation notes for Cowork:** the tag vocabulary mostly maps to `#kb/` Level 2
  tags now (drop the dead `tess-operations` tag); the routing target is `_inbox/`
  (universal intake), NOT the defunct `_openclaw/inbox/`; priorities should be read
  from `_system/docs/personal-context.md` §Strategic Priorities at run time using the
  three-tier model (`feedback-priority-tiers-not-binary`) — never hardcoded.

### Delivery discipline
Threshold delivery — suppress the digest below a minimum item count, never send an
empty one; per-source cadence (daily/weekly); overflow capping on high-volume sources
(arXiv was capped at 50 items/cycle). The anti-firehose lesson is shared with scout:
the failure mode is a digest the operator learns to ignore.

### Routing thinking
`design/manual-intake-adapter-decision.md` and `design/research-promotion-path.md` —
how feed items become knowledge, worth rereading before designing the Cowork digest's
promotion path.

## Reboot constraints (from the current architecture)

- **Surface:** Cowork scheduled run (rented runtime). Fetches sources directly from
  the roster via web — no adapters, no database, no local state.
- **Write boundary:** digest is a stateful consumable → `_system/daily/` drop zone or
  outside-in delivery (push/Gmail); knowledge candidates → `_inbox/` with
  operator-pulled promotion (`adr-vault-write-boundary.md`). **Do not auto-capture
  without a consuming practice** — that's failure #3 above.
- **Intake stays open** at the source-selection level; the triage rubric is the
  downstream filter.
- **No new primitives** until real usage pulls one (ceremony budget principle).
- **Retired at archival** (git-history-only in the vault repo; external repos
  destroyed): both repos (`feed-intel-framework`, predecessor `x-feed-intel`),
  the `pipeline.db` corpus (static since 2026-05-28, digested value already
  extracted), `~/.config/fif/` credentials. X OAuth revocation = operator to-do
  (rotate-credentials revocation-candidates list).
