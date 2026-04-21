---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Research Pipeline

Covers the three skills that take a question from raw research through validation to polished prose. Each can be used standalone; together they form a quality-gated pipeline.

## Skills in This Workflow

### /researcher
**Invoke:** "research [topic/question]", "deep research on", "what does the evidence say about"
**Inputs:** Research question + deliverable format (`research-note` or `knowledge-note`); optionally rigor (`light` / `standard` / `deep`) and project name
**Outputs:** Deliverable at `Projects/[project]/research/deliverable-[dispatch].md` (research-note) or `Sources/[type]/[slug].md` (knowledge-note); fact ledger, source files, synthesis doc, telemetry

**Internal stages (each runs as an isolated subagent):**
1. **Scoping** — validates brief, queries vault for existing coverage, sets scope inclusions/exclusions, initializes fact ledger
2. **Planning** — decomposes question into ≥2 sub-questions, generates testable hypotheses, sets convergence thresholds and search strategy
3. **Research Loop** (iterates) — runs WebSearch/WebFetch, classifies sources by tier (A/B/C), populates fact ledger, evaluates convergence per sub-question; repeats until all sub-questions covered or max iterations reached
4. **Synthesis** — cross-references ledger by claim key, evaluates hypotheses, identifies contradictions, computes overall confidence score, writes synthesis doc
5. **Citation Verification** — checks quote snippets against stored source content, detects over-confidence, applies supersede corrections to the ledger
6. **Writing** — drafts deliverable using only `[^FL-NNN]` ledger citations, runs 4 validation checks (coverage, resolution, source chain, ad-hoc detection), retries up to 2× on failure

---

### /peer-review
**Invoke:** "peer review [artifact]", "get review on this", "cross-model review"
**Inputs:** Artifact file path (or inline content); optionally custom focus questions
**Outputs:** Review note at `Projects/[project]/reviews/` or `_system/reviews/`; raw JSON responses per reviewer; synthesized findings with action items

**What happens:**
- Dispatches artifact to external LLMs via a subagent; auto-detects diff vs. full mode if a prior review exists
- Synthesizes responses into consensus findings, unique findings, contradictions, and a classified action-item list (must-fix / should-fix / defer)
- Presents summary in conversation; asks before applying findings to the artifact

---

### /writing-coach
**Invoke:** "improve this", "review my writing", "edit for tone", "make this clearer"
**Inputs:** The text to improve; audience and purpose (stated or inferred)
**Outputs:** Revised text in-conversation with per-change explanations; optionally new patterns logged to `_system/docs/solutions/` (track: pattern)

**What happens:**
- Establishes audience, purpose, and tone before editing
- Scores on three dimensions: audience fit, structure, brevity; iterates up to 2× on any failing dimension
- Loads `ai-telltale-anti-patterns.md` automatically for external-audience content

---

## How They Compose

Typical pipeline: `/researcher` produces a sourced draft → `/peer-review` validates the draft for correctness, gaps, and structural issues → `/writing-coach` polishes for audience fit and brevity.

Each skill is also useful standalone: `/peer-review` on any spec or design doc, `/writing-coach` on any draft, `/researcher` when you need sourced evidence without an immediate writing step.
