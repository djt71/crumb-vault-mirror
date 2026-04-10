---
type: specification
domain: software
skill_origin: systems-analyst
status: active
created: 2026-04-04
updated: 2026-04-04
tags:
  - compound-engineering
  - code-review
  - system-enhancement
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Compound Engineering Enhancements — Specification

Three targeted enhancements to Crumb's compound engineering and code review systems,
adapted from patterns in the EveryInc compound-engineering-plugin. These are amendments
to existing artifacts (design spec §4.4, code-review SKILL.md, solution doc schema),
not a new project.

## Problem Statement

Compound engineering outputs in `_system/docs/solutions/` use freeform body structure,
making them hard to filter by insight type. The code-review skill dispatches a fixed
prompt regardless of what changed, producing noise on irrelevant criteria. Review
findings are synthesized individually even when multiple findings share a common root
cause, leading to symptom-level action items instead of systemic fixes.

## Facts

- 17 existing solution docs with inconsistent structure — some have `type: solution`,
  others `type: pattern` or `type: problem-pattern`
- Code-review skill uses a fixed 9-criteria evaluation prompt for all diffs (SKILL.md Step 5)
- Code-review synthesis (Step 7) groups by consensus/unique/contradictions, not by theme
- Upstream plugin ships track-based schemas, conditional reviewer personas, and cluster
  analysis gated at 3+ findings — all production-validated
- Our two-reviewer panel (Opus + Codex) is fixed; we're not adding reviewer agents

## Assumptions

- Three tracks (bug, pattern, convention) map well to our existing 17 docs (validate during migration)
- Diff-signal detection via keyword/path matching is sufficient for conditional routing — no AST parsing needed
- Thematic grouping of findings by file-path proximity + issue-type similarity is sufficient for clustering — no embedding-based analysis needed

## Unknowns

- Whether any downstream skill reads solution doc body structure (not just frontmatter) in a way that would break on schema changes — verify before migration

---

## Enhancement 1: Track-Based Learning Schema

### What Changes

Add a `track` field to solution doc frontmatter and standardize body sections per track.

**Frontmatter addition:**

```yaml
track: bug | pattern | convention
```

**Body schema per track:**

#### Track: `bug`

```markdown
## Symptoms
[What was observed — error messages, failing behavior, user-visible impact]

## Root Cause
[Why it happened — the actual underlying issue]

## Resolution
[What fixed it — the specific change or approach]

## Resolution Type
[Category: config | code-fix | architecture | process | dependency | workaround]

## Evidence
[Concrete instance(s) with project/task references]

## Counterexample
[When this pattern does NOT apply]
```

#### Track: `pattern`

```markdown
## Applies When
[Trigger conditions — what situation activates this pattern]

## Guidance
[What to do — the actionable decision rule]

## Why It Matters
[Impact of ignoring — what breaks or degrades]

## Evidence
[Concrete instance(s) with project/task references]

## Counterexample
[When this pattern does NOT apply]
```

#### Track: `convention`

```markdown
## Scope
[Where this applies — which projects, domains, file types, or skills]

## Rule
[The convention itself — stated as a directive]

## Rationale
[Why this convention exists — the decision or incident that established it]

## Evidence
[Concrete instance(s) with project/task references]
```

Conventions don't require a Counterexample section — they're policy decisions, not
inferential patterns.

### What Gets Modified

1. **Design spec §4.4** — Add track-based schema to the "Pattern document minimum fields"
   section. The existing 5 fields (Pattern Title, Trigger Context, Decision Rule,
   Evidence, Counterexample) become the `pattern` track default. Add `bug` and
   `convention` track schemas. Add `track` to required frontmatter for solution docs.

2. **`_system/docs/file-conventions.md`** — Add `track` to the optional fields list
   for non-project docs under `_system/docs/solutions/`.

3. **Compound step procedure (§4.4, Step 3)** — When routing to `_system/docs/solutions/`,
   classify the insight by track before writing. Add classification heuristic:
   - Something broke → `bug`
   - Reusable decision framework → `pattern`
   - Process/policy record → `convention`

4. **Existing 17 solution docs** — Migrate to track schema. Proposed classification:

   | Doc | Proposed Track |
   |-----|---------------|
   | `claude-print-cwd-sensitivity.md` | bug |
   | `security-verification-circularity.md` | bug |
   | `haiku-soul-behavior-injection.md` | bug |
   | `claude-print-automation-patterns.md` | pattern |
   | `gate-evaluation-pattern.md` | pattern |
   | `behavioral-vs-automated-triggers.md` | pattern |
   | `memory-stratification-pattern.md` | pattern |
   | `write-read-path-verification.md` | pattern |
   | `write-only-from-ledger.md` | pattern |
   | `validation-is-convention-source.md` | pattern |
   | `solutions-linkage-proposal.md` | pattern |
   | `archive-conventions.md` | convention |
   | `lucidchart-policy-compliance.md` | convention |
   | `html-rendering-bookmark.md` | convention |
   | `code-review-patterns.md` | convention |
   | `reasoning-token-budget.md` (peer-review-patterns/) | pattern |
   | `ai-telltale-anti-patterns.md` (writing-patterns/) | convention |

5. **vault-check.sh** — Add validation: files in `_system/docs/solutions/` must have
   `track` in frontmatter. Warn (not error) during migration period; enforce after
   migration complete.

### Acceptance Criteria

- [ ] All 17 existing solution docs have `track` field in frontmatter
- [ ] All 17 docs have body sections matching their track schema
- [ ] Compound step procedure in spec §4.4 includes track classification heuristic
- [ ] `file-conventions.md` documents the `track` field
- [ ] vault-check validates `track` presence on solution docs
- [ ] No downstream skill breaks from the migration (verify by reading skill `required_context` references)

---

## Enhancement 2: Conditional Review Routing

### What Changes

Add a diff-signal analysis step to the code-review skill that tailors the review
prompt based on what actually changed. Same two reviewers, sharper prompts.

**New Step 4b: Analyze Diff Signals** (inserted between current Steps 4 and 5)

Scan the diff for signals and activate relevant review lenses:

| Signal | Detection | Lens Added to Prompt |
|--------|-----------|---------------------|
| **Security** | Files matching `*auth*`, `*crypto*`, `*secret*`, `*token*`, `*session*`, `*permission*`; or diff contains `password`, `api_key`, `bearer`, `jwt`, `hash`, `encrypt`, `sanitize` | Emphasize: input validation, secret handling, injection risks, auth bypass. Add: "Flag any hardcoded credentials or secrets." |
| **Data/Schema** | Files matching `*migration*`, `*schema*`, `*model*`; or diff contains `CREATE TABLE`, `ALTER`, `addColumn`, `removeColumn`, `.schema` | Emphasize: backward compatibility, rollback safety, data loss risk, index impact. Add: "Flag breaking schema changes without migration path." |
| **API Contract** | Files matching `*route*`, `*handler*`, `*controller*`, `*endpoint*`; or diff contains `app.get`, `app.post`, `router.`, `@api`, `openapi` | Emphasize: breaking changes, versioning, response shape stability. Add: "Flag public API signature changes." |
| **Config/Infra** | Files matching `*.env*`, `*.yaml`, `*.toml`, `*plist*`, `Dockerfile`, `*.tf`; or diff contains `process.env`, `os.environ` | Emphasize: secret exposure, environment parity, deployment impact. Add: "Flag config that differs between environments." |
| **Shell/Automation** | Files matching `*.sh`, `*.bash`; or diff contains `set -e`, `launchctl`, `cron` | Emphasize: error handling under `set -e`, quoting, path assumptions, idempotency. Add: "Flag unquoted variables and missing error handling." |

**Prompt modification logic:**

- **0 signals detected:** Use the existing generic 9-criteria prompt unchanged
- **1-2 signals detected:** Keep all 9 criteria but reorder — move signal-relevant
  criteria to positions 1-3 and append lens-specific additions
- **3+ signals detected:** Keep all 9 criteria, append all matched lens additions as
  a "Priority areas" section

The base prompt is never reduced — lenses add emphasis, not remove coverage.

### What Gets Modified

1. **Code-review SKILL.md** — Insert Step 4b between Steps 4 and 5. Modify Step 5
   to use signal-aware prompt assembly.

2. **Run-log format** — Add `signals_detected` field to the code review log entry:
   ```markdown
   - Signals: security, shell-automation (2 detected)
   ```

### Acceptance Criteria

- [ ] Step 4b implemented in code-review SKILL.md
- [ ] Step 5 prompt assembly incorporates detected signals
- [ ] 0-signal case produces identical output to current behavior
- [ ] Run-log format includes signals detected
- [ ] Signal detection is keyword/path based (no external dependencies)

---

## Enhancement 3: Finding Cluster Analysis

### What Changes

Add a clustering sub-step to code-review synthesis (Step 7) that groups findings by
common root cause before generating action items.

**New Step 7b: Cluster Analysis** (inserted after current deduplication, before action items)

After normalizing severity and deduplicating consensus findings:

1. **Group findings by theme.** For each finding, extract:
   - File path (directory-level grouping)
   - Issue type (from the 9 evaluation criteria: correctness, security, etc.)
   - Description keywords

2. **Detect clusters.** A cluster forms when 3+ findings share:
   - Same issue type AND same directory, OR
   - Same issue type AND similar description (>50% keyword overlap)

3. **Promote clusters.** When a cluster is detected:
   - Create a **systemic finding** that names the root cause pattern
   - List the individual findings as instances under the systemic finding
   - Generate one systemic action item (address the pattern) instead of N individual items
   - Individual items are preserved as sub-items for traceability

4. **Gate:** If fewer than 3 findings share a theme, skip clustering — individual
   findings are fine at low counts.

**Synthesis structure change:**

Current Step 7 sections:
1. Consensus Findings
2. Unique Findings
3. Contradictions
4. Action Items
5. Considered and Declined

Enhanced Step 7 sections:
1. **Systemic Findings** (new — only present when clusters detected)
2. Consensus Findings
3. Unique Findings
4. Contradictions
5. Action Items (systemic actions first, then individual)
6. Considered and Declined

**Compound feedback loop:** When a systemic finding is identified, evaluate whether
it meets compound step trigger criteria. If the same systemic pattern appears across
2+ reviews, promote to `_system/docs/solutions/` as a `bug` or `pattern` track doc.

### What Gets Modified

1. **Code-review SKILL.md Step 7** — Add clustering sub-step after deduplication.
   Add Systemic Findings section to synthesis structure.

2. **Run-log format** — Add cluster count:
   ```markdown
   - Clusters: 1 systemic (5 instances) | 0 systemic
   ```

3. **Code-review compound behavior section** — Add: "When systemic findings recur
   across 2+ reviews, promote the pattern to `_system/docs/solutions/` with
   appropriate track classification."

### Acceptance Criteria

- [ ] Clustering sub-step in code-review SKILL.md Step 7
- [ ] Systemic Findings section in synthesis output (only when clusters exist)
- [ ] 3-finding threshold enforced (no spurious clusters from 2 similar findings)
- [ ] Individual findings preserved as sub-items under systemic findings
- [ ] Run-log format includes cluster count
- [ ] Compound feedback loop documented for cross-review pattern promotion

---

## System Map

**Components:**
- Design spec §4.4 (compound step protocol) — track schema, classification heuristic
- Code-review SKILL.md — conditional routing, cluster analysis
- `_system/docs/solutions/*.md` — migration targets for track schema
- `_system/docs/file-conventions.md` — track field documentation
- `_system/scripts/vault-check.sh` — track validation rule
- Run-log format — signals and cluster fields

**Dependencies:**
- Enhancement 1 (track schema) is independent — can ship alone
- Enhancement 2 (conditional routing) is independent — can ship alone
- Enhancement 3 (cluster analysis) benefits from Enhancement 1 (compound feedback
  loop uses track classification) but can ship without it

**Risk Assessment:**
- Enhancement 1: **Medium** — modifies 17 existing files + spec + vault-check.
  Mitigated by verifying no downstream breakage before migration.
- Enhancement 2: **Low** — additive change to prompt assembly; 0-signal case is
  identical to current behavior.
- Enhancement 3: **Low** — additive section in synthesis; no change when <3 similar
  findings.

## Task Decomposition

| ID | Description | Risk | Depends On |
|----|-------------|------|------------|
| CE-001 | Amend design spec §4.4 with track-based schema | low | — |
| CE-002 | Update `file-conventions.md` with `track` field | low | CE-001 |
| CE-003 | Migrate 17 existing solution docs to track schema | medium | CE-001 |
| CE-004 | Add `track` validation to vault-check.sh | low | CE-001 |
| CE-005 | Verify no downstream skill breakage from migration | low | CE-003 |
| CE-006 | Add Step 4b (diff signal analysis) to code-review SKILL.md | low | — |
| CE-007 | Modify Step 5 (prompt assembly) for signal-aware routing | low | CE-006 |
| CE-008 | Add Step 7b (cluster analysis) to code-review SKILL.md | low | — |
| CE-009 | Update run-log format in code-review SKILL.md | low | CE-006, CE-008 |
| CE-010 | Update compound behavior section for cross-review promotion | low | CE-008, CE-001 |

## Domain Classification

- **Domain:** software
- **Workflow:** No formal project — these are spec amendments and skill updates
- **Execution:** Serial within a session; track schema first (broadest change),
  then conditional routing, then cluster analysis
