---
type: review
review_mode: full
review_round: 2
prior_review: _system/reviews/2026-02-18-specification.md
artifact: Projects/notebooklm-pipeline/design/specification.md
artifact_type: spec
artifact_hash: 4c7465e3
prompt_hash: f757c52f
base_ref: null
project: notebooklm-pipeline
domain: learning
skill_origin: peer-review
created: 2026-02-18
updated: 2026-02-18
reviewers:
  - openai/gpt-5.2
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192 (openai, google), 65536 (perplexity)
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 43176
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-18-specification-r2-openai.json
  google:
    http_status: 503
    latency_ms: null
    attempts: 3
    error: "503 on attempt 1, timeout on attempt 2, 503 on attempt 3"
    raw_json: _system/reviews/raw/2026-02-18-specification-r2-google.json
  perplexity:
    http_status: 200
    latency_ms: 10378
    attempts: 1
    error: "Search returned irrelevant results (generic multi-agent articles). No useful review produced."
    raw_json: _system/reviews/raw/2026-02-18-specification-r2-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review Round 2: NotebookLM-to-Crumb Knowledge Pipeline Specification

**Artifact:** Projects/notebooklm-pipeline/design/specification.md
**Mode:** full (large-diff escape hatch — changes touched foundational schema and task decomposition)
**Reviewed:** 2026-02-18
**Reviewers:** OpenAI GPT-5.2 (1/3 — Gemini down, Perplexity search miss)
**Prior review:** _system/reviews/2026-02-18-specification.md (round 1)
**Review prompt:** Round 2 structured review with context on all 9 incorporated changes from round 1. Focused on internal consistency, remaining gaps, over-engineering, and feasibility.

**Reviewer availability note:** Gemini 3 Pro Preview returned 503/timeout on all 3 attempts. Perplexity Sonar Reasoning Pro returned 200 but its search engine returned irrelevant results (generic multi-agent system articles) and could not verify any dependencies or produce a substantive review. Synthesis is based solely on OpenAI's review.

---

## OpenAI (GPT-5.2)

- [F1]
  - [Severity]: STRENGTH
  - [Finding]: Sentinel-based deterministic detection cleanly resolves the earlier "guessing" problem and makes the pipeline composable with the existing inbox-processor.
  - [Why]: Eliminates an entire class of brittle heuristics and makes fixture-based parsing achievable.

- [F2]
  - [Severity]: SIGNIFICANT
  - [Finding]: Sentinel marker relies on HTML comments, but extensions may sanitize/strip HTML comments during export.
  - [Why]: If the extension strips comments, detection fails and everything falls back to generic inbox path.
  - [Fix]: Dual sentinel strategy: primary HTML comment + secondary plain-text line (e.g., `crumb:nlm-export v1 template:book-digest-v1`) in the first N lines. Parser accepts either.

- [F3]
  - [Severity]: SIGNIFICANT
  - [Finding]: source_id generation underspecified for collisions, non-book sources, unknown authors, and editions.
  - [Why]: Dedup, routing, and multi-note linking depend on stability.
  - [Fix]: Explicit algorithm: `kebab(creator-lastname + short-title)`, optional `-YYYY` disambiguator, collision policy with short hash suffix. Add `source.canonical_url` field.

- [F4]
  - [Severity]: SIGNIFICANT
  - [Finding]: scope format too open-ended — freeform strings will cause near-duplicate notes or dedup failures.
  - [Fix]: Define scope as structured: `scope_type` + `scope_slug` with canonicalization rules.

- [F5]
  - [Severity]: SIGNIFICANT
  - [Finding]: note_type enum includes concept-map, argument-map, data-table but only digest and extract have body templates defined. Schema/template mismatch.
  - [Fix]: Restrict v1 enum to `digest | extract` and add others in v2, or define minimal body templates for all types now.

- [F6]
  - [Severity]: MINOR
  - [Finding]: Folder mapping table referenced but not shown in the condensed review prompt.
  - [Note]: This table IS present in the full spec (D2). Non-issue — artifact was condensed for the review prompt.

- [F7]
  - [Severity]: SIGNIFICANT
  - [Finding]: Quality gate only triggers by source_type, but courses and "other" may also be low-citation. Gate should be based on evidence characteristics.
  - [Fix]: Add `source.citation_density: low | medium | high` or base gate on source characteristics rather than type alone.

- [F8]
  - [Severity]: SIGNIFICANT
  - [Finding]: Parser strictness not defined — what sections are mandatory vs. best-effort?
  - [Fix]: Two-tier parser contract: sentinel + at least one mandatory section = ingest; remaining sections best-effort with empty defaults.

- [F9]
  - [Severity]: MINOR
  - [Finding]: Symlinks for template lifecycle may be brittle across platforms/sync tools.
  - [Fix]: Prefer copy + version enforcement; or specify symlinks as macOS-only.

- [F10]
  - [Severity]: STRENGTH
  - [Finding]: Fixture-based acceptance criteria is a strong feasibility move.

- [F11]
  - [Severity]: SIGNIFICANT
  - [Finding]: Dedup behavior undefined — overwrite, skip, create new version, or prompt?
  - [Fix]: Default: prompt user with diff; option to update in-place or create versioned file.

- [F12]
  - [Severity]: SIGNIFICANT
  - [Finding]: Missing provenance fields: publication date, canonical URL, queried date.
  - [Fix]: Add `source.published_at`, `source.canonical_url`, `source.queried_at` to schema.

- [F13]
  - [Severity]: MINOR
  - [Finding]: No fallback if processor can't suggest a kb/ tag. Mandatory tag enforcement could deadlock intake.
  - [Fix]: Allow `#kb/unsorted` as temporary tag; require follow-up triage.

- [F14]
  - [Severity]: SIGNIFICANT
  - [Finding]: "Routing" meaning is ambiguous — everything goes to Sources/ anyway, so what does `domain:` route?
  - [Fix]: Clarify: primary storage always Sources/. domain: feeds optional backlinks in domain notes / future MOCs.

- [F15]
  - [Severity]: MINOR
  - [Finding]: No batching guidance for rate limit management.
  - [Fix]: Add ingestion session plan: default 1 template per source (digest); deeper extraction on demand.

- [F16]
  - [Severity]: SIGNIFICANT
  - [Finding]: Fixture diversity not defined — parser may pass fixtures but fail real-world variation.
  - [Fix]: Define fixture matrix: at least 1 book, 1 article, 1 podcast/video, 1 messy export, 1 very short output.

- [F17]
  - [Severity]: MINOR
  - [Finding]: Filename length not bounded for long scope slugs.
  - [Fix]: Enforce max length with hash truncation.

- [F18]
  - [Severity]: STRENGTH
  - [Finding]: Copy/paste fallback prevents total pipeline failure.

- [F19]
  - [Severity]: SIGNIFICANT
  - [Finding]: "Parser maintains backward compatibility" lacks a compatibility strategy.
  - [Fix]: Support last N template versions, deprecation process, store template_schema_version.

- [F20]
  - [Severity]: MINOR (OVER-ENGINEERING)
  - [Finding]: Combined complexity (sentinel + versioning + dedup + lifecycle + symlinks) edges toward mini-product scope for a personal OS.
  - [Fix]: Keep sentinel + versioning + fixtures; defer symlinks and full lifecycle promotion until after NLM-005 proves stability.

---

## Gemini (gemini-3-pro-preview)

*Unavailable — 503 / timeout on all 3 attempts.*

---

## Perplexity (sonar-reasoning-pro)

*Search returned irrelevant results (generic multi-agent system articles). No substantive review produced. Response acknowledged the limitation and recommended re-running with targeted search results.*

---

## Synthesis

**Note:** This synthesis is based on a single reviewer (OpenAI GPT-5.2). Consensus/contradiction analysis is not possible with one data point. Findings are evaluated on their individual merits.

### Consensus Findings

N/A — single reviewer.

### Unique Findings

**OAI-F2: Sentinel survivability** — Genuine concern. HTML comments are the most likely thing to be stripped by an extension or a paste operation. A dual sentinel (HTML comment + plain text) is low-cost insurance. Worth adding.

**OAI-F3: source_id collision handling** — Valid. The current spec says "kebab(author-surname + short-title)" but doesn't address podcasts (no author → channel name), multi-author works, or same-title collisions. Needs a concrete algorithm, but should stay simple — not a full bibliographic identifier system.

**OAI-F5: note_type enum mismatch** — Correct observation. The v1 enum lists 5 types but only 2 have body templates. Clean fix: restrict v1 enum to `digest | extract`, note the others as planned for v2. This also simplifies NLM-003 and NLM-004 scope.

**OAI-F11: Dedup behavior** — Genuine gap. The spec says "check for existing notes" but not what to do when found. Prompt-and-confirm is the right default for a personal system.

**OAI-F8: Parser strictness** — Valid design question. Two-tier (required sentinel + optional sections) is pragmatic and aligns with the fallback path design.

**OAI-F12: Missing provenance fields** — Partially valid. `canonical_url` and `queried_at` are useful. `published_at` is nice-to-have. These are low-cost additions to the schema.

**OAI-F14: Routing ambiguity** — Valid observation. Now that everything routes to Sources/, the `domain:` field's routing role is vestigial. Should clarify it drives future MOC/backlink generation, not physical routing.

**OAI-F20: Over-engineering risk** — Fair flag. The spec has accumulated complexity across 2 rounds. Template lifecycle promotion with symlinks is the most expendable piece for v1.

### Contradictions

N/A — single reviewer.

### Action Items

**Should-fix (before PLAN):**

- **A1** — Add dual sentinel strategy. Templates embed both HTML comment (`<!-- crumb:nlm-export ... -->`) and plain-text line (`crumb:nlm-export v1 template:book-digest-v1`) in the first 5 lines. Parser accepts either. Low cost, high insurance value. (Source: OAI-F2)

- **A2** — Restrict v1 `note_type` enum to `digest | extract`. Move concept-map, argument-map, data-table to "planned for v2" in the schema description. Simplifies NLM-003 and NLM-004 scope. (Source: OAI-F5)

- **A3** — Specify dedup behavior: when same `source_id + note_type + scope` exists, prompt user with options: update in-place, create versioned copy (`-rev2`), or skip. Default: prompt. (Source: OAI-F11)

- **A4** — Add `source.canonical_url` (optional) and `source.queried_at` fields to schema. Useful for provenance and collision disambiguation. (Source: OAI-F3, OAI-F12)

- **A5** — Clarify routing: primary storage always `Sources/[type]/`. `domain:` field drives future MOC generation and domain-summary backlinks, not physical routing. (Source: OAI-F14)

- **A6** — Define fixture diversity minimums for NLM-003: at least 1 book, 1 article, 1 podcast/video, 1 "messy" export, 1 short output. (Source: OAI-F16)

**Defer (to PLAN or IMPLEMENT):**

- **A7** — source_id collision algorithm details. Current kebab(author+title) is sufficient for spec phase. Refine during NLM-001 implementation when real examples clarify edge cases. (Source: OAI-F3)

- **A8** — Scope normalization rules. Define canonicalization during NLM-001 when the full scope syntax is worked out. (Source: OAI-F4)

- **A9** — Parser strictness contract (required vs. best-effort sections). Define during NLM-004 design when fixture samples are available. (Source: OAI-F8)

- **A10** — Quality gate based on evidence characteristics vs. source type. Current type-based gate is a reasonable v1 heuristic. Refine if podcasts/courses prove unreliable. (Source: OAI-F7)

- **A11** — Template backward compatibility strategy. Premature before v2 templates exist. Define deprecation rules when first template revision happens. (Source: OAI-F19)

- **A12** — Template promotion with symlinks. Per OAI-F20, defer full lifecycle promotion until after NLM-005. Manual move is sufficient for v1. (Source: OAI-F9, OAI-F20)

### Considered and Declined

- **OAI-F6** (folder mapping table not shown): `incorrect` — Table is present in the full specification; was condensed for the review prompt. Non-issue.

- **OAI-F13** (`#kb/unsorted` fallback tag): `overkill` — The processor prompts the user to confirm tags during step 5. If the user can't think of a tag, they can type one. A formal "unsorted" tag creates a triage burden. The prompt-and-confirm step already handles this.

- **OAI-F15** (batching guidance for rate limits): `out-of-scope` — This is workflow guidance for the user guide (NLM-006), not a spec concern. The rate limit is already noted as a constraint.

- **OAI-F17** (filename length limits): `overkill` — macOS supports 255-char filenames. Scope slugs from "ch-03" or "whole" won't approach this. Edge case at best.
