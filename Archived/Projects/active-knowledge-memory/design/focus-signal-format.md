---
type: design
project: active-knowledge-memory
domain: software
status: active
created: 2026-03-02
updated: 2026-03-02
tags:
  - akm
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Focus Signal Format

The active focus signal is a structured representation of the operator's current
context — active projects, priorities, and relevant knowledge domains. It is the
input to `knowledge-retrieve.sh`, which uses it to construct QMD queries and
rank results.

## Schema (D2)

```yaml
focus:
  projects:                          # all active projects from project-state.yaml
    - name: <project-name>
      phase: <phase>
      domain: <domain>
      next_action: "<text>"
  keywords: ["<derived from projects + next_action text>"]
  tags: ["kb/<relevant>"]            # kb/ tags from active project tags
  trigger: session-start | skill-activation | new-content
  trigger_context: null              # populated by skill-activation and new-content triggers
```

### Field Definitions

**`projects`** — Populated automatically from all `project-state.yaml` files where
phase is not DONE or ARCHIVED. Each entry captures the project's name, current phase,
domain, and immediate next action. This is the primary signal source — what the
operator is actively working on determines what knowledge is relevant.

**`keywords`** — Derived at runtime by extracting significant terms from project names
and `next_action` text. Simple extraction: split on spaces, drop stop words, deduplicate.
No NLP required — these become QMD query terms combined with `tags`.

**`tags`** — Aggregated from active project `tags` fields, filtered to `kb/*` entries
only. These scope the knowledge domain for retrieval. When multiple projects share a
tag, it appears once (deduplicated).

**`trigger`** — Which retrieval trigger invoked this signal:
- `session-start`: Full project scan, broadest query. Budget: 5 items.
- `skill-activation`: Scoped to current task context. Budget: 3 items.
- `new-content`: Scoped to the new item's content/tags. Budget: 5 items.

**`trigger_context`** — Additional context for non-session-start triggers:
- `skill-activation`: skill name, task description, project name
- `new-content`: promoted note path, tags, first paragraph

### Priority Derivation

The original schema included a `priorities` field sourced from `operator_priorities.md`.
This file does not exist — operator priorities are distributed across project states.
Rather than create a new file with maintenance burden, priorities are derived:

1. **Phase urgency**: IMPLEMENT > TASK > PLAN > SPECIFY > ACT (software); ACT is
   highest for knowledge-work domains
2. **Recency**: `updated` timestamp in project-state.yaml
3. **Keyword weighting**: Projects in higher-urgency phases contribute more keywords

This derivation runs at signal construction time inside `knowledge-retrieve.sh`.

## Construction Rules

1. Read all `Projects/*/project-state.yaml` files
2. Filter to active projects (phase not DONE, not ARCHIVED, directory not in `Archived/`)
3. For each active project: extract name, phase, domain, next_action
4. Collect all `kb/*` tags from active project tags fields
5. Extract keywords from project names + next_action text
6. Set trigger and trigger_context based on invocation mode
7. Serialize as YAML (internal) or pass as structured arguments to QMD query builder

## Worked Examples

### Example 1: Session Start — Mixed Software + Knowledge Work

Real vault state: 10 active projects, operator starting a fresh session.

```yaml
focus:
  projects:
    - name: active-knowledge-memory
      phase: TASK
      domain: software
      next_action: "begin WP-1 foundation docs (AKM-001, AKM-002, AKM-003)"
    - name: feed-intel-framework
      phase: TASK
      domain: software
      next_action: "FIF-033 cross-source collision detection + weekly aggregate"
    - name: researcher-skill
      phase: IMPLEMENT
      domain: software
      next_action: "RS-013 Synthesis stage, RS-014 Writing stage"
    - name: customer-intelligence
      phase: ACT
      domain: career
      next_action: "comms strategies for Steelcase + BorgWarner"
    - name: batch-book-pipeline
      phase: ACT
      domain: learning
      next_action: "BBP-006 batch results + quality review + MOC baselines"
    - name: book-scout
      phase: IMPLEMENT
      domain: software
      next_action: "commit credential-file change, transition to DONE"
    - name: tess-operations
      phase: TASK
      domain: software
      next_action: "M1 gate eval day 3 + TOP-046 overnight research"
    - name: x-feed-intel
      phase: IMPLEMENT
      domain: software
      next_action: "Route 4 pending compound insights, gateway restart"
    - name: knowledge-navigation
      phase: ACT
      domain: learning
      next_action: "Phase 4 automation integration or archival"
    - name: agent-to-agent-communication
      phase: SPECIFY
      domain: software
      next_action: "Systems analysis of input spec"
  keywords:
    - knowledge
    - retrieval
    - memory
    - feed
    - intel
    - collision
    - synthesis
    - writing
    - customer
    - comms
    - book
    - pipeline
    - research
    - agent
    - communication
  tags:
    - kb/software-dev
    - kb/customer-engagement
    - kb/business
    - kb/history
  trigger: session-start
  trigger_context: null
```

**Expected query behavior:** QMD receives keywords weighted by phase urgency.
IMPLEMENT projects (researcher-skill, book-scout, x-feed-intel) contribute strongest
keyword signal. Session-start budget of 5 items means post-filter selects the 5 most
relevant KB items across all domains, with diversity constraint (max 2 per tag cluster).

### Example 2: Skill Activation — Systems Analyst on AKM

Operator invokes systems-analyst skill for the agent-to-agent-communication project.

```yaml
focus:
  projects:
    - name: agent-to-agent-communication
      phase: SPECIFY
      domain: software
      next_action: "Systems analysis of input spec"
  keywords:
    - agent
    - communication
    - protocol
    - message
    - dispatch
  tags:
    - kb/software-dev
  trigger: skill-activation
  trigger_context:
    skill: systems-analyst
    task: "Analyze agent-to-agent communication patterns for multi-agent orchestration"
    project: agent-to-agent-communication
```

**Expected query behavior:** Narrow scope — only the triggering project contributes
to the signal. Keywords include task-specific terms from trigger_context. Budget of
3 items. Should surface: message protocol patterns, distributed systems concepts,
orchestration designs from KB sources.

### Example 3: New Content — Book Digest Promoted

Feed-pipeline promotes a new book digest about negotiation strategy.

```yaml
focus:
  projects:
    - name: customer-intelligence
      phase: ACT
      domain: career
      next_action: "comms strategies for Steelcase + BorgWarner"
    - name: batch-book-pipeline
      phase: ACT
      domain: learning
      next_action: "BBP-006 batch results + quality review"
  keywords:
    - negotiation
    - strategy
    - persuasion
    - customer
    - engagement
  tags:
    - kb/business
    - kb/customer-engagement
    - kb/psychology
  trigger: new-content
  trigger_context:
    note_path: "Sources/books/voss-never-split-the-difference-digest.md"
    note_tags:
      - kb/business
      - kb/psychology
    first_paragraph: "Negotiation is not a battle of arguments but a process of discovery..."
```

**Expected query behavior:** Signal combines the new note's content with active
projects sharing relevant tags. Keywords from the note's first paragraph drive the
query. Cross-domain flag activates when results span multiple tag clusters (e.g.,
a philosophy note about rhetoric surfaces alongside business negotiation). Budget
of 5 items. Brief written to `_openclaw/tess_scratch/kb-brief-latest.md`.

## Implementation Notes

- Signal construction is a pure function: vault state in → YAML out
- No persistent state between invocations — rebuilt fresh each time
- The `projects` list may be large (10+ active projects). Keyword extraction should
  cap at ~20 terms to avoid diluting QMD queries
- For `skill-activation` trigger, only the triggering project's context matters —
  other active projects are excluded to keep the query focused
- For `new-content` trigger, include projects that share tags with the new note
  (cross-pollination) but not unrelated projects
