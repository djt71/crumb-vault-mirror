---
type: findings
project: researcher-skill
domain: software
status: active
created: 2026-02-22
updated: 2026-02-22
source: claude-ai-session
affects:
  - peer-review skill
  - researcher-skill
tags:
  - peer-review
  - researcher-skill
  - citation-verification
  - hallucination
routed_from: _inbox/
resolution_notes: |
  Rec 1 (prompt flagging) implemented 2026-02-22 in peer-review SKILL.md.
  Recs 2-4 remain open as SPECIFY-phase inputs for researcher-skill.
---

# Citation Verification Gap — Peer Review + Researcher Skill

## Problem

The peer review skill dispatches to 4 reasoning models that evaluate
analysis quality, structural soundness, and security concerns. None of
them can verify grounded factual claims: GitHub issue numbers, software
version references, paper titles, URLs, or specific statistics attributed
to external sources.

This was surfaced during the Phase 2 live deployment when Crumb peer-reviewed
`_inbox/tess-local-llm-research-thread-FINAL.md`. The review caught 8
corrections including "2 fabricated citations" — but the original document
itself contains additional unverified references that the peer reviewers
passed silently.

## Evidence

Three specific references in `tess-local-llm-research-thread-FINAL.md`:

1. **"GitHub #4567"** (line 310) — Grok cited this as source for an 85%
   JSON validity claim for qwen3-coder:30b. The R1 synthesis already flagged
   this as unverifiable. Good catch — but it was caught by cross-referencing
   reviewer claims, not by grounded verification.

2. **"GitHub #5123"** (line 390) — Referenced as an unresolved OpenClaw issue
   about dynamic task-type routing. Classic fabrication pattern: plausible
   issue number attached to a real technical question. No reviewer flagged this.

3. **"OpenClaw v1.2"** (lines 383, 390) — Referenced multiple times as having
   patch notes and docs. Whether this version exists and whether those specific
   docs say what's claimed is unverified. No reviewer flagged this.

The pattern: peer reviewers evaluate whether the *analysis* is sound given
the cited facts, but they cannot verify whether the cited facts are real.
Models reviewing models creates a closed loop with no grounding.

## Prior Art (Already in Vault)

`_system/reviews/2026-02-21-perplexity-deep-research.md` — the peer review
of the deep research spec — explicitly identified this gap:

- **F4 (SIGNIFICANT):** "Missing: explicit mechanisms for quote-level grounding
  and preventing citation errors. Deep research failures in practice are often
  not 'wrong answer' but 'right-ish answer with wrong citation.'" Recommended:
  every claim maps to evidence snippet IDs, writer can only cite from evidence
  store, automated citation verifier pass.

- **F13 (MINOR):** "Several citations are to vendor/press/aggregator sources;
  these are fine for orientation but weak as technical ground truth."

- **Grok (F4):** "The artifact glosses over Citation Hallucination. LLMs love
  to create real-looking citations. The review ignores the need for a Link
  Verifier step."

These findings were captured but not yet actioned — they're inputs for both
the researcher-skill and peer-review skill SPECIFY phases.

## Recommendations

### 1. Peer Review Skill — Add "Unverifiable Claims" Review Dimension

The peer review prompt should instruct reviewers to flag specific references
they cannot independently verify: GitHub issue numbers, version-specific
claims, paper citations, statistics with attributed sources. Reviewers can't
*check* these, but they can flag them as "needs grounded verification" rather
than passing them silently.

This is a prompt change to `_system/docs/peer-review-config.md` or the
review prompt template — not a new reviewer or infrastructure change.

### 2. Peer Review Skill — Citation Verification Pass (Optional 5th Reviewer)

Add a web-search-enabled verification stage that runs after the 4-model review.
This "reviewer" extracts every specific factual claim (URLs, issue numbers,
version references, paper titles, statistics with sources) and attempts
grounded verification via web search. Output: verified / unverifiable /
fabricated for each claim.

The dispatch pipeline supports this — a `claude --print` stage with web search
access could run the verification. This is a higher-effort change (new
reviewer type, web search integration) but closes the loop structurally.

### 3. Researcher Skill — Citation Verification at Source

The researcher skill should verify its own citations as part of document
production, before submission for peer review. Defense in depth: don't rely
on review to catch what the source should have verified.

Per the Perplexity review F4 recommendation: evidence store pattern where
every claim maps to a verified source, and the writer can only cite from
the store.

### 4. Both Skills — Shared Citation Taxonomy

Establish a shared vocabulary for citation confidence:
- **Verified:** URL resolves, content matches claim
- **Plausible:** Claim is consistent with known facts but source not independently checked
- **Anecdotal:** Community reports, forum posts, unverified on our hardware
- **Unverifiable:** Specific reference (issue number, version, paper) that cannot be confirmed
- **Fabricated:** Reference confirmed to not exist

The research doc already uses some of this language informally ("anecdotal",
"unverified on our hardware"). Formalizing it makes it a mechanical check
rather than a judgment call.

## Routing

- **Peer review skill fix (Rec 1):** Immediate — prompt change only, no infrastructure
- **Researcher-skill input (Recs 2-4):** SPECIFY phase input — these inform the skill's requirements
- **Dispatch protocol note:** The verification pass (Rec 2) is the first use case for a web-search-enabled dispatch stage — worth noting in the researcher-skill spec as a dependency
