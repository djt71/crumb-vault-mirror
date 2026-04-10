# Writing Validation Rules

## Purpose

This document defines the write-only-from-ledger discipline that mechanically enforces
citation integrity in research deliverables. The Writing stage (Stage 6) executes these
rules before declaring completion. No deliverable may be marked `status: done` if any
validation check fails.

## Citation Format: `[^FL-NNN]`

### Format Definition

Every factual claim in a research deliverable is cited using a footnote-style reference
to a fact ledger entry:

```
[^FL-NNN]
```

Where `NNN` is the zero-padded 3-digit entry ID from the fact ledger (e.g., `[^FL-001]`,
`[^FL-012]`, `[^FL-123]`).

### Usage Rules

1. **Inline citations:** Place `[^FL-NNN]` immediately after the factual claim it supports,
   before any sentence-ending punctuation:
   ```
   The transformer architecture relies on self-attention mechanisms[^FL-003].
   ```

2. **Multiple citations:** When a claim is supported by multiple ledger entries, list them
   in ascending order separated by commas:
   ```
   LLM scaling appears to follow power-law relationships[^FL-007],[^FL-012].
   ```

3. **Only cite active entries:** Never reference an entry with `status: deprecated`.
   Deprecated entries have been superseded — cite the superseding entry instead.

4. **Citation footnotes section:** At the end of the deliverable, include a `## Sources`
   section mapping each `[^FL-NNN]` to its source metadata:
   ```markdown
   ## Sources

   [^FL-001]: Author (Year). "Title." Venue. [Tier A — verified]
   [^FL-002]: Author (Year). "Title." Venue. [Tier B — supported]
   ```
   The bracketed suffix shows the source tier and the entry's confidence level.

5. **No ad-hoc citations:** The deliverable MUST NOT contain any citation format other
   than `[^FL-NNN]`. No inline URLs, no `[1]`-style numbered references, no Harvard-style
   author-date citations. Every factual claim traces through the ledger.

## Writing Validation: 4 Checks

The Writing stage runs all 4 checks after producing the deliverable draft. ALL checks
must pass for the stage to declare `status: done`.

### Check 1: Citation Coverage

**Question:** Does every factual claim in the deliverable have a citation?

**Procedure:**

1. Parse the deliverable text to identify all factual claims — statements that assert
   facts, statistics, findings, dates, attributions, or causal relationships.
2. For each factual claim, verify it has at least one `[^FL-NNN]` citation.
3. Exclude from checking:
   - Transitional phrases and connective text
   - The author's own synthesis or analysis (explicitly marked as such)
   - Section headings and structural text
   - Statements of scope or methodology ("This research examines...")
4. **Heuristic anchor:** When uncertain whether a statement is a factual claim, err on
   the side of requiring a citation. A claim is factual if removing it would leave the
   reader less informed about the research question's answer. This biases toward
   over-citation (safe) rather than under-citation (undermines integrity).

**Failure output:**
```yaml
check: coverage
status: fail
uncited_claims:
  - location: "paragraph N, sentence M"
    text: "The uncited factual claim..."
    suggestion: "Consider citing FL-NNN or mark as synthesis"
```

### Check 2: Citation Resolution

**Question:** Does every `[^FL-NNN]` reference resolve to an active ledger entry?

**Procedure:**

1. Extract all `[^FL-NNN]` references from the deliverable text (both inline and
   in the Sources section).
2. For each reference, look up the entry ID in the fact ledger.
3. Verify the entry exists AND has `status: active`.
4. If the entry exists but has `status: deprecated`, flag it — the citation should
   reference the superseding entry instead.

**Failure output:**
```yaml
check: resolution
status: fail
unresolved_citations:
  - citation: "[^FL-NNN]"
    reason: "entry not found in ledger"
  - citation: "[^FL-NNN]"
    reason: "entry is deprecated — superseded by FL-MMM"
```

### Check 3: Source Chain

**Question:** Does every cited ledger entry trace to a scored source?

**Procedure:**

1. For each `[^FL-NNN]` cited in the deliverable, read the ledger entry.
2. Verify the entry has a non-null `source_id`.
3. Verify that `source_id` exists in the ledger's `sources:` array.
4. Verify the source has a `tier` classification (A, B, or C).

A complete source chain is: `deliverable claim → [^FL-NNN] → ledger entry → source_id → scored source`.

**Failure output:**
```yaml
check: source_chain
status: fail
broken_chains:
  - citation: "[^FL-NNN]"
    entry_id: "FL-NNN"
    reason: "source_id is null"
  - citation: "[^FL-NNN]"
    entry_id: "FL-NNN"
    source_id: "some-source"
    reason: "source_id not found in sources array"
  - citation: "[^FL-NNN]"
    entry_id: "FL-NNN"
    source_id: "some-source"
    reason: "source missing tier classification"
```

### Check 4: Orphan Detection

**Question:** Are there any `[^FL-NNN]` references to non-existent ledger entries?

**Procedure:**

1. Extract all unique `[^FL-NNN]` patterns from the entire deliverable (regex: `\[\^FL-\d{3}\]`).
2. For each extracted reference, verify the entry ID exists in the ledger's `entries:` array.
3. Flag any reference that points to an entry ID not present in the ledger at all
   (distinct from Check 2's deprecated-entry detection — this catches IDs that were
   never created).

**Failure output:**
```yaml
check: orphan_detection
status: fail
orphan_citations:
  - citation: "[^FL-NNN]"
    reason: "no entry with this ID exists in the ledger"
```

## Validation Summary Output

After running all 4 checks, the Writing stage produces a validation summary:

```yaml
writing_validation:
  timestamp: "ISO 8601"
  checks:
    coverage:
      status: "pass | fail"
      uncited_claims: 0
      total_claims_checked: 0
    resolution_and_orphans:
      status: "pass | fail"
      unresolved_count: 0
      deprecated_references: 0
      orphan_count: 0
    source_chain:
      status: "pass | fail"
      broken_chains: 0
      total_chains_checked: 0
    ad_hoc_detection:
      status: "pass | fail"
      ad_hoc_citations_found: 0
      types_found: []
  overall: "pass | fail"
  citation_count: 0
  unique_entries_cited: 0
  unique_sources_cited: 0
  retry_count: 0
```

## Enforcement Rules

1. **Blocking:** If `overall: fail`, the Writing stage MUST output `status: "next"` with
   fix instructions describing each failure. It MUST NOT output `status: "done"`.

2. **Retry:** The orchestrator may re-invoke the Writing stage with the failure details.
   The stage should fix the identified issues and re-run validation. Maximum 2 retry
   attempts — after that, escalate to operator with the validation failures.

3. **Partial pass:** All 4 checks must pass. There is no "pass with warnings" — either
   the citation chain is mechanically sound or it is not.

4. **Synthesis exemption:** The deliverable may include clearly marked synthesis sections
   (e.g., "**Analysis:**" or "**Synthesis:**") that draw conclusions from cited evidence
   without requiring per-sentence citations. However, any factual claims within synthesis
   sections still require citations.

## Integration Points

- **Citation Verification stage** (Stage 5) runs BEFORE Writing — it ensures ledger
  entries have correct confidence levels and source-backed quotes. Writing Validation
  assumes the ledger has already been verified.
- **Fact ledger** is the single source of truth. The deliverable is a derived artifact.
- **Source chain** terminates at the scored source in the ledger — it does not re-verify
  the source content (that was done in Citation Verification).
