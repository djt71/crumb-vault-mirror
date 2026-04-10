---
type: change-spec
domain: software
project: x-feed-intel
status: integrated
created: 2026-02-25
updated: 2026-02-25
---

# Amendment: Compound Insight Routing from Research Outputs

**Scope:** Wire research output compound insights into the vault's compound engineering system so they don't dead-end in `_openclaw/feeds/research/`.

**Motivation:** Research outputs contain a `## Assessment` section with compound insights — cross-cutting patterns, architecture validations, and actionable signals that should route into `_system/docs/`, project design docs, or architecture decision records. Currently these insights accumulate in Tess-owned territory (`_openclaw/feeds/research/`) outside the compound engineering surface. The operator must manually notice and relay them to Crumb. This doesn't scale.

Two independent research outputs from the same session both converged on "document Crumb's execution model as an ADR" — a signal that should have triggered action, not sat in separate files.

**Relationship to existing spec:**
- §4.4 (Compound Step Protocol): Defines the routing taxonomy (conventions, system gaps, patterns, durable knowledge, one-time findings). This amendment connects research outputs to those routes.
- §5.8.1 (Research Command: Context Enrichment): The enrichment pipeline prepares context; this amendment structures the *output* side.
- Bridge dispatch prompt (bridge-request.ts): The `args` field tells Crumb what to produce. Adding compound insight instructions here is the injection point.
- Session startup protocol: The startup scan is the consumption point — where unrouted insights get surfaced.

---

## Design

### 1. Structured Compound Output (Tess-side: bridge dispatch prompt)

Add to the bridge dispatch `args` instruction:

```
If this research reveals a cross-cutting pattern, architecture validation,
or actionable insight beyond the specific post, add a compound_insight
block to the YAML frontmatter:

compound_insight:
  pattern: "<1-sentence description of the reusable insight>"
  scope: "<one of: architecture-decision-record | pattern-document | convention-update | project-specific>"
  target: "<vault path where this should be routed, e.g. _system/docs/ or Projects/x-feed-intel/design/>"
  confidence: "<low | medium | high>"
  durability: "<permanent | perishable>"
  valid_as_of: "<YYYY-MM-DD>"  # required when durability is perishable
  related_research: []  # populated later if convergence detected

Omit compound_insight entirely if the research is informational only
with no actionable cross-cutting signal.
```

**Schema fields:**
- `pattern`: The insight itself — concise enough to evaluate at a glance during startup scan
- `scope`: Maps directly to the compound step routing taxonomy in §4.4:
  - `architecture-decision-record` → `_system/docs/`
  - `pattern-document` → `_system/docs/solutions/`
  - `convention-update` → existing doc (CLAUDE.md, file-conventions, etc.)
  - `project-specific` → relevant project's design/ directory
- `target`: Specific vault path for routing. Crumb proposes; operator confirms.
- `confidence`: Follows the existing compound confidence tagging (low = log only, medium = propose to operator, high = route with notification)
- `durability`: Distinguishes insights by shelf life:
  - `permanent` — architecture patterns, design principles, domain knowledge. Valid indefinitely. Example: "CLI-as-interface + sandbox-as-tool = Crumb execution model"
  - `perishable` — model-dependent, tool-version-specific, or time-bound observations. Requires `valid_as_of` date. Example: "Sonnet handles inbox-processor sentinel detection without quality loss" (true for current Sonnet, may not hold after next model release)
- `valid_as_of`: Required when `durability: perishable`. The date the observation was verified. The startup scan flags perishable insights past a configurable review threshold (default: 90 days) for re-evaluation.
- `related_research`: Empty at creation time. Populated by convergence detection (Phase 2) when multiple research files reference the same pattern.

**Why frontmatter, not a markdown section:** Machine-readable. The startup scan can extract and evaluate `compound_insight` fields without parsing prose. Grep for `compound_insight:` across research files gives an instant inventory.

### 2. Session Startup Scan (Crumb-side: startup protocol)

Add a research compound check to the session startup sequence, after the staleness scan:

```
Research compound scan:
1. Glob _openclaw/feeds/research/*.md
2. For each file with compound_insight in frontmatter:
   a. Skip if routed_at or dismissed is present
   b. If unrouted: add to pending_insights list
   c. If durability=perishable and valid_as_of is >90 days old:
      add to stale_insights list
3. Report:
   - "N unrouted compound insights from research"
   - "N perishable insights past review threshold"
4. During session: present pending insights to operator for routing
   decision (route / defer / dismiss)
5. For stale perishable insights: operator decides revalidate / dismiss
```

**Routing decision by operator:**
- **Route:** Crumb creates the target artifact (ADR, pattern doc, convention update) using the research output as source material. Adds `routed_at` and `routed_to` to the research file's `compound_insight` block.
- **Defer:** No action now. Insight stays pending for next session.
- **Dismiss:** Crumb adds `dismissed: true` to the `compound_insight` block. Startup scan skips it.

**Routed state** — add to frontmatter after routing:
```yaml
compound_insight:
  pattern: "..."
  scope: "..."
  target: "..."
  confidence: "high"
  routed_at: "2026-02-26"
  routed_to: "_system/docs/crumb-execution-model-adr.md"
```

The startup scan checks for `routed_at` or `dismissed` — if present, skip. Simple presence-based logic, no separate workflow state.

### 3. Convergence Detection (deferred — Phase 2)

When the startup scan finds 2+ unrouted insights with overlapping `pattern` descriptions or identical `target` paths, flag the convergence:

```
⚡ Convergence: 2 research outputs both recommend an architecture
   decision record for Crumb's execution model
   → research-A01-karpathy-clis-...md
   → research-2021261552222158955-hwchase17-...md
   Action: route / defer / dismiss
```

This requires N > 2 research files with compound insights to be useful. Defer until the pipeline has produced enough volume.

---

## Spec Integration Points

1. **§5.8.1 (or new §5.8.2):** Add compound insight schema to research output format
2. **Bridge dispatch prompt (bridge-request.ts):** Add compound_insight instruction to `args` string
3. **Session startup protocol:** Add research compound scan step
4. **§4.4 (Compound Step Protocol):** Note that research outputs are a compound source, routed via startup scan rather than inline during a session

## Implementation

### Immediate (this session)
- Update `buildResearchRequest()` in `bridge-request.ts` to include compound insight instruction in the `args` field
- No schema changes, no new files, no config changes

### Next session (Crumb-side)
- Add research compound scan to `_system/scripts/session-startup.sh` or the startup protocol doc
- Test with the two existing research outputs that have implicit compound insights

### Deferred
- Convergence detection
- `related_research` cross-linking

## Feed-Intel-Framework Portability

The `compound_insight` schema is deliberately source-agnostic:

- **No source-specific fields.** The schema describes the *insight* (pattern, scope, target, confidence), not the post or source it came from. The source context is already in the research file's other frontmatter fields (`source_post`, `author`, `tags`).
- **Shared directory.** `_openclaw/feeds/research/` is the research output directory for both x-feed-intel and FIF. The startup scan operates on this directory regardless of which adapter produced the research.
- **Bridge dispatch is the injection point.** FIF's bridge dispatch will use the same `buildResearchRequest()` pattern (or its generalized equivalent). The compound insight instruction carries forward into the FIF dispatch prompt without modification.
- **Startup scan is vault-level, not project-level.** It scans a vault directory, not a project directory. When FIF replaces x-feed-intel as the active pipeline, the scan continues to work.

**What FIF inherits automatically:**
- `compound_insight` frontmatter schema
- Startup scan + operator routing flow
- Convergence detection (when implemented)

**What FIF may extend:**
- Cross-source convergence — two research outputs from different adapters (e.g., an X post and an RSS article) recommending the same ADR. The `related_research` field supports this by design.
- Source-weighted confidence — a pattern validated across 3 independent sources is higher confidence than one from a single source. This is a Phase 2+ concern for FIF's convergence logic.

This amendment should be cross-referenced in the FIF spec (§5.11 research promotion or a new §5.12) when FIF reaches IMPLEMENT phase.

## Operational Notes

**Perishable over-indexing (watch item, 2026-02-25):** First two compound insights both returned `durability: perishable`. One was correct (intellectronica/Bases — version-dependent Obsidian feature). The other was debatable (1337hero — "agent memory stratifies by scope" is a durable architectural principle, though the specific technology mapping is version-dependent). The model may conflate a permanent pattern with its perishable instantiation. If 80%+ of insights come back perishable after 10-15 samples, sharpen the dispatch prompt durability instruction to distinguish the architectural principle from the technologies it references. Track ratio before tuning.

## Cost Impact

Zero. The compound insight is part of the research output that Crumb already generates. The startup scan is a local file read (Glob + frontmatter parse). No API calls.
