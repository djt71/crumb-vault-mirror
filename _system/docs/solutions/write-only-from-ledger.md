---
type: solution
domain: software
status: active
track: pattern
created: 2026-03-05
updated: 2026-04-04
skill_origin: compound
confidence: high
tags:
  - kb/software-dev
  - research
  - citation-integrity
topics:
  - moc-crumb-operations
---

# Write-Only-From-Ledger

## Problem

LLM-generated research deliverables routinely contain hallucinated citations — claims attributed to sources that don't support them, references to papers that don't exist, or ad-hoc inline URLs injected during writing. Standard prompting ("cite your sources") produces compliant-looking output with no mechanical guarantee that citations are real.

## Pattern

Separate evidence collection from writing, and enforce that the writing stage can only reference entries in a verified evidence store (the "ledger"). The citation chain is:

```
deliverable claim → [^FL-NNN] → ledger entry → source_id → scored source with provenance
```

### Key constraints

1. **Append-only during research.** The research loop adds entries to the ledger. It never modifies or removes existing entries.
2. **Supersede-only during verification.** Citation verification creates new entries that supersede originals (confidence downgrade, quote correction). Deprecated entries are preserved for audit trail.
3. **Write-only-from-ledger during writing.** The writing stage may only cite `[^FL-NNN]` entries that exist in the ledger with `status: active`. No ad-hoc citations of any format.
4. **Mechanical validation.** Four checks run after writing:
   - Coverage: every factual claim has a citation
   - Resolution: every `[^FL-NNN]` resolves to an active ledger entry
   - Source chain: every cited entry traces to a scored source
   - Ad-hoc detection: no bare URLs, numbered references, or author-date citations

### Why it works

The pattern converts citation integrity from a compliance problem (hoping the LLM follows instructions) to a structural problem (the writing stage literally cannot reference anything outside the ledger). The LLM still applies judgment about which claims to include and how to synthesize — but every factual claim must trace to a mechanically verifiable source chain.

## Evidence

Validated across two end-to-end research dispatches:

| Metric | E2E #1 (well-studied topic) | E2E #2 (niche topic) |
|---|---|---|
| Ledger entries | 15 | 44 (41 active, 3 deprecated) |
| Citations in deliverable | 15 | 68 |
| Validation pass | Attempt 1 | Attempt 1 |
| Ad-hoc citations detected | 0 | 0 |
| Deprecated entries cited | 0 | 0 |
| Supersede operations | 0 | 3 |

E2E #2 exercised the supersede mechanism (3 entries downgraded from `verified` to `supported` during citation verification for paraphrased quotes) and confirmed the writing stage correctly cited superseding entries instead of deprecated originals.

## When to use

- Any LLM pipeline that produces sourced deliverables (research notes, knowledge notes, reports)
- Multi-stage pipelines where evidence collection and writing are separated
- Contexts where citation hallucination is a known failure mode

## When not to use

- Quick factual lookups that don't need formal citation chains
- Creative or opinion writing where source backing isn't the goal
- Single-turn interactions where a ledger would be ceremony without benefit

## Relationship to other patterns

- Extends **write-read path verification** — the ledger is the write path; citation validation is the read path check
- The append-with-supersede audit model preserves full provenance without allowing destructive edits to the evidence base

## Origin

Researcher skill (`/.claude/skills/researcher/SKILL.md`), compound evaluation across two dispatches (da3dea3f, 046d97b3). The pattern was identified during skill design as the architectural centerpiece and confirmed effective through production use.
