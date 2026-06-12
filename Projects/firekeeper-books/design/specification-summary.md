---
project: firekeeper-books
domain: creative
type: specification-summary
skill_origin: null
created: 2026-03-17
updated: 2026-06-12
source_updated: 2026-06-12
---

# Firekeeper Books — Phase 1 Specification Summary

**Mission:** Premium illustrated digital editions of public domain texts — fiction, drama, poetry, philosophy. Illustrations are the moat. Revenue validates reach.

**Phase 1 scope:** Ebook only. Fiction-first: Frankenstein (Title #1, 1818 text). The Odyssey (Title #2) is **gated on the Frankenstein M0 outcome** — the Nolan-film pre-release window has passed; any Odyssey edition targets the film's long tail. Audiobook (Phase 2) and multilingual (Phase 3) deferred.

## Current State (2026-06-12)

- **Editorial pipeline complete** for Frankenstein: clean 1818 text, structural outline, edition comparison, readability assessment, front matter, assembled manuscript, EPUB guide (`title-01-frankenstein/`).
- **Zero illustrations accepted.** The Midjourney spike (April) failed the operator's quality bar — retroactive M-1 verdict: Stop on cloud tools.
- **M-1B local pipeline spike is the sole critical path:** Draw Things on the Mac Studio (M3 Ultra/96GB), batch panels + style LoRA workflow, 3-session budget, hard go/iterate/stop gate, written decision in `design/spike-findings.md`.
- Competitive purchases completed and reviewed: existing competition genuinely bad — gap thesis confirmed.

## Key Decisions

- **Series name:** Firekeeper Books. Domain registered. USPTO clear.
- **Fiction-first:** Illustrations are the moat, fiction maximizes it. Meditations deferred (Stoicism shelf saturated).
- **Distribution:** Wide from day one. Direct (Payhip ~$7.06) > Google Play ($5.59) > Apple (~$3.60) > KDP ($2.80) > Kobo ($1.60, presence only). PD-specific royalties verified April 2026.
- **Pricing:** $7.99. Blended per-sale ~$3.90 at target mix.
- **KDP royalty: 35%, permanently.** The 70% election is closed for primarily-PD titles — USCO-registration escape hatch rejected (honest "primarily PD" reading + AI-illustration registrability doubts). Open item G closed; USCO registration dropped.
- **AI tooling: local pipeline** (Draw Things primary, ComfyUI escalation) on owned hardware. Style LoRA for series consistency. Model license check mandatory at selection.
- **AI disclosure: open posture.** Public front-matter disclosure (sustained human art direction) + confidential KDP disclosure. "Commissioned" language removed. Build-in-public is the aligned marketing channel; avoid leading into AI-hostile communities without the disclosure.
- **Illustration count (Title #1): 23** — cover, frontispiece, title-page vignette, 20 section openers.
- **M0 remains the hard gate**; human-illustrator fallback acknowledged as a different business shape, not a drop-in fallback.

## Milestones (revised)

| Milestone | Gate | Status |
|-----------|------|--------|
| M-1: Cloud tool spike | Coherent illustrations? | **Stop** (retroactive, 2026-06-12) — purchases/review done, Midjourney failed bar |
| M-1B: Local pipeline spike | Operator quality bar at acceptable time cost; 3 logged sessions; go/iterate/stop in writing | **Next** |
| M0: Design prototype | Meaningfully better than existing editions — hard gate | Gated on M-1B |
| M1: Frankenstein production | Complete edition ready | Gated on M0 |
| M2: Frankenstein published | Live on all platforms, 60-day timer | — |
| OD-Pre/OD-M1/OD-M2: Odyssey | **All gated on M0 + hour data** | Frozen |
| M3: Validation | 30–40 sales = viable, <10 = kill (with marketing-confound check) | 60–90 days post-publish |

## Validation

30–40 unit sales at $7.99 in 60–90 days = minimum viable. <10 sales + no reviews = kill — but verify a discovery channel actually delivered impressions before reading it as product failure (marketing confound, §3). Go/no-go after 2 titles + data.

## Critical Path

(1) M-1B local illustration spike — everything else is gated on it. (2) Time-log discipline from spike session 1 — per-title hours decide whether a 10–20 title catalog is viable. (3) M0 hard gate vs. Coulthart/Wrightson benchmarks.

## Risk

Very low conflict-safety risk (9/10), PIIA Exhibit B carve-out. LLC deferred to post-M3. AI-art backlash managed via open disclosure. AI illustrations have thin copyright protection — brand and curation are the moat, not image IP.

## Source

Full spec: [[specification]]
Research: [[side-hustle-v7-public-domain-wisdom-library]], `title-01-frankenstein/01-competitive-intelligence.md`
