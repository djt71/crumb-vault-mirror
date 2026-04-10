---
project: agent-to-agent-communication
type: design-note
domain: software
status: draft
created: 2026-03-04
updated: 2026-03-04
tags:
  - architecture
  - skills
  - orchestration
---

# Design Note: Skill Plugin Architecture

**Context:** The agent-to-agent communication spec must not hardcode workflows to specific skills. Skills should operate as plugins — when a new skill comes online, it participates in workflows without rewiring orchestration logic.

**Audience:** Systems analyst producing the formal specification. Incorporate this as an architectural requirement.

---

## 1. Problem

The input spec (§12 Build Order) ties workflows to specific skills by name: Workflow 2 depends on "researcher-skill M5 complete," Workflow 3 depends on "researcher-skill" for external research. When researcher-skill completed earlier than expected, the build order had to be manually re-sequenced. This is a symptom of a deeper issue: workflows are defined in terms of required capabilities.

This coupling creates three problems:

1. **Fragile build ordering.** Completing a skill earlier (or later) than expected requires manually rewriting the phase plan.
2. **No substitution.** If a better research skill is built, or a lightweight alternative is needed for cost reasons, every workflow that names `researcher` must be updated.
3. **No extensibility.** A new skill (e.g., a competitive-analysis specialist, a draft-writer, a customer-outreach planner) can't participate in existing workflows without modifying the orchestration logic.

---

## 2. Design: Capability-Based Skill Registration

### 2.1 Skill Manifest

Every skill declares a **capability manifest** in its SKILL.md frontmatter. This extends the existing frontmatter (name, description, model_tier) with structured metadata that Tess can query at dispatch time.

```yaml
---
name: researcher
description: >
  Execute a stage-separated research pipeline...
model_tier: reasoning

# --- Capability manifest (new) ---
capabilities:
  - id: external-research
    description: "Evidence-grounded research with citation integrity"
    accepts:
      schema: research-brief       # references a known brief schema
      required_fields: [question, deliverable_format]
      optional_fields: [rigor, convergence_overrides, max_stages, max_wall_time]
    produces:
      artifacts: [research-note, knowledge-note]
      includes_provenance: true
      includes_telemetry: true
    cost_profile:
      model_tier: reasoning
      typical_tokens: 30000-80000  # range for standard rigor
      typical_stages: 6-10
    requires:
      tools: [WebSearch, WebFetch, Read, Write, Grep, Glob]
      vault_access: read-write
      dispatch_protocol: CTB-016
    quality_signals:
      convergence_score: true      # output includes convergence metric
      citation_verification: true  # output includes verification pass
      writing_validation: true     # output includes validation pass
---
```

Key design choices:

- **`capabilities` is a list.** A single skill can declare multiple capabilities. The peer-review skill could declare both `structured-review` and `diff-review`. The feed-pipeline skill could declare `feed-triage` and `signal-promotion`.
- **`accepts.schema` references a named schema**, not a skill-specific structure. Multiple skills offering the same capability type use the same brief schema. This is what makes substitution possible.
- **`cost_profile` is informational, not enforced.** The dispatch protocol's budget enforcement (CTB-016 §5) remains the enforcement mechanism. The manifest gives Tess enough information to make cost-aware routing decisions before dispatching. **Learning log supersedes manifest:** once the dispatch learning log (§8.4) has ≥3 data points for a capability, Tess uses observed costs. Manifest is the cold-start fallback for new/untested skills.
- **`quality_signals` declares what structural quality checks the skill's output supports.** Tess uses this to determine which quality gate checks (§11.1) are applicable to a given skill's output.

### 2.2 Capability Resolution

Tess doesn't dispatch to skills by name. She dispatches to capabilities. The resolution chain:

```
Need identified (e.g., "research this topic")
  → Capability required: external-research
    → Query registered skills for capability match
      → Candidate skills: [researcher]  (today)
      → Candidate skills: [researcher, lightweight-researcher, competitive-analyst]  (future)
        → Select based on: cost_profile vs. budget, quality_signals vs. requirements, model_tier
          → Dispatch to selected skill
```

**Resolution rules:**

1. **Exact capability match required.** The skill must declare the capability ID that the workflow needs. No fuzzy matching.
2. **Single skill selected per dispatch.** If multiple skills offer the same capability, Tess selects one. Selection criteria (in priority order): (a) dispatch learning log patterns for this brief type, (b) cost fit within budget, (c) quality signal coverage, (d) model tier appropriateness.
3. **Fallback is escalation, not guessing.** If zero skills match a required capability, Tess escalates to Danny rather than attempting a workaround. This is the "fail closed" principle from the dispatch protocol.
4. **Registration is passive.** Skills don't register at runtime — Tess discovers capabilities by reading SKILL.md frontmatter from `.claude/skills/*/SKILL.md` at orchestration decision time. No registry service, no startup handshake.

**Granularity heuristic (substitution test):** A capability is correctly scoped when you can name a plausible second skill that would offer it. If you can't imagine a substitute, it's too narrow. If every skill qualifies, it's too broad.

### 2.3 Brief Schema Registry

For capability-based dispatch to work, brief schemas must be shared artifacts rather than skill-internal definitions. A brief schema defines the contract between "what the orchestrator provides" and "what the skill accepts."

Location: `_system/schemas/briefs/`

```
_system/schemas/briefs/
  research-brief.yaml        # used by: researcher, future research-capable skills
  review-brief.yaml          # used by: peer-review, critic, future review skills
  vault-query-brief.yaml     # used by: any skill needing vault reads
  writing-brief.yaml         # used by: writing-coach, future writing skills
```

Each schema defines **required fields only** — the minimum contract. Optional fields are genuinely optional; established skills handle more of them, lightweight alternatives ignore them. This keeps the bar low for new implementations while giving Tess enough structure to formulate valid briefs.

**New schemas emerge from practice, not speculation.** Don't pre-create schemas for capabilities that don't exist yet. When a second skill needs the same brief type as an existing one, extract the schema at that point. The researcher-skill's current brief structure becomes the first `research-brief.yaml`.

---

## 3. Impact on Workflows

### 3.1 Workflow Definitions Become Capability Chains

Instead of:

```
Workflow 2: Tess dispatches to researcher-skill → quality gate → deliver
```

The spec should express:

```
Workflow 2:
  needs: [external-research]
  flow: Tess formulates brief → dispatch to (external-research) → quality gate → deliver
```

The workflow is buildable when at least one skill is registered with each required capability. This replaces the static "after researcher-skill M5" dependency with a checkable condition: "a skill declaring `external-research` capability exists and passes a smoke test."

**Exception: Workflow 1 (Compound Insights) does not use capability-based dispatch.** Its Crumb dispatch is a simple template-write that doesn't benefit from capability abstraction. The plugin model applies to dispatches where substitution is plausible.

### 3.2 SE Account Prep (Workflow 3) Becomes a Composition

```
Workflow 3 (SE Account Prep):
  needs: [vault-query, external-research]
  dispatch_group:
    branch_a: dispatch to (vault-query) with account-query brief
    branch_b: dispatch to (external-research) with light-rigor research brief
    join: merge per join contract
```

### 3.3 Build Order Becomes Condition-Based

Replace phase headers like "Phase 2: after researcher-skill M5" with:

```
Phase 2 prerequisites:
  - capability: external-research (registered, smoke-tested)
  - infrastructure: tess-context.md (operational)
  - infrastructure: escalation auto-resolution (implemented)
```

---

## 4. Impact on Existing Skills

Existing skills need a lightweight frontmatter addition — the capability manifest. This is additive; nothing in the current SKILL.md structure breaks. Suggested rollout:

1. **Researcher** — declares `external-research`. Brief schema extracted to `_system/schemas/briefs/research-brief.yaml`.
2. **Peer-review** — declares `structured-review`, `diff-review`. Brief schema extracted.
3. **Feed-pipeline** — declares `feed-triage`, `signal-promotion`.
4. **Systems-analyst** — declares `specification-authoring`.
5. **Critic** (when built) — declares `adversarial-review`. Accepts the same `review-brief` schema as peer-review, enabling Tess to choose between peer-review (multi-model external) and critic (single-model adversarial) based on the situation.

Skills only invoked directly by the operator (startup, checkpoint, sync) don't need capability manifests — they're not dispatch targets.

---

## 5. Impact on Dispatch Protocol

**Option A (selected): Resolve before dispatch.** Tess resolves capability → skill name before creating the dispatch request. The runner stays simple — lifecycle, budget, governance. Resolution lives in Tess's orchestration layer.

```yaml
# Dispatch request (amended)
skill: researcher              # resolved skill name
capability: external-research  # originating capability (for audit)
brief:
  schema: research-brief
  question: "..."
  rigor: standard
```

---

## 6. What This Does NOT Include

- **Runtime skill installation.** Skills are files in `.claude/skills/`. No hot-reload, no marketplace.
- **Capability negotiation.** Skills don't bid on work. Tess selects; skills execute.
- **Automatic schema evolution.** Add versioning when a breaking change happens, not before.
- **Cross-capability composition within a single dispatch.** One capability per dispatch. Multi-capability workflows use dispatch groups.

---

## 7. Analysis Resolutions

These gaps were identified during systems analysis and resolved with Danny:

1. **Workflow 1 capability mapping:** Workflow 1 is exempt — its dispatch is a simple template-write, not complex enough for capability abstraction. The plugin model applies to research, review, and similar dispatches where substitution is plausible.
2. **Cost profile staleness:** Learning log supersedes manifest once ≥3 data points exist. Manifest is cold-start only.
3. **Capability granularity:** Substitution test heuristic — "can you name a plausible second skill?" If not, too narrow. If every skill qualifies, too broad.
4. **Brief schema tightness:** Required fields only. Optional fields are genuinely optional. Low bar for new implementations.
5. **Quality signals:** Quality gate checks are adaptive — only run checks the skill's manifest declares it supports.
