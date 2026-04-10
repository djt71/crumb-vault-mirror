---
type: review
artifact: Projects/agent-to-agent-communication/design/action-plan.md
artifact_type: action-plan
project: agent-to-agent-communication
domain: software
reviewer: perplexity-sonar-reasoning-pro
review_mode: full
status: active
created: 2026-03-04
updated: 2026-03-04
---

# Peer Review: Action Plan — Perplexity Sonar Reasoning Pro

**Source:** Perplexity with file upload (Danny-submitted)

## Findings

### 1. Milestones, dependencies, hidden blockers

**1.1 [SIGNIFICANT]:** M1 exit criteria need stability thresholds — delivery errors for N days, context refresh count, feedback schema stability.

**1.2 [SIGNIFICANT]:** M3 depends on M2 gate — stricter than needed. Schema work can start earlier.

**1.3 [CRITICAL]:** Hidden dependency: manifest validation. No explicit validation step between schema definition (A2A-006) and resolution logic (A2A-008). Need A2A-006.5 manifest validation script.

### 2. Task decomposition and acceptance criteria

**2.1 [SIGNIFICANT]:** A2A-001/002/003 still too big for single sessions. Suggest sub-task splits.

**2.2 [SIGNIFICANT]:** A2A-004.3 overloaded — suggest dry-run/live split.

**2.3 [SIGNIFICANT]:** Acceptance criteria often non-testable. Add test harness per milestone.

### 3. Implementation approach: SOUL.md vs code

**3.1 [CRITICAL]:** SOUL.md as primary orchestration engine is the biggest structural risk. Proposes minimal code helper layer for deterministic operations (envelope generation, ledger appends, schema validation, correlation ID generation).

**3.2 [SIGNIFICANT]:** Capability resolution entirely in SOUL.md. At minimum, pre-compute skill→capabilities mapping as JSON/YAML.

**3.3 [SIGNIFICANT]:** Escalation + quality gates via prompts — hard limits (re-dispatch counts) should be stored in state, not just instructed.

### 4. Code location map friction points

**4.1 [MINOR]:** Delivery-config is state not schema — move schema definitions to `_system/schemas/a2a/`.

**4.2 [MINOR]:** Manifest validation code location unspecified.

### 5. Risk coverage

**5.1 [SIGNIFICANT]:** Feedback cold-start underplayed — cold-start capabilities should be restricted from high-rigor auto-selection.

**5.2 [CRITICAL]:** SOUL.md orchestration fragility not listed as a risk.

**5.3 [MINOR]:** Iteration budget not tied to concrete failure modes.

### 6. Phase 2-4 sketches

**6.1 [SIGNIFICANT]:** M5 dependency too loose — should require M2 gate + learning log schema.

**6.2 [MINOR]:** M6 deadline-awareness needs runtime statistics from dispatch-learning.yaml.

**6.3 [MINOR]:** M8 data quality metric needed (<X% malformed entries).

### 7. Missing items

**7.1 [SIGNIFICANT]:** Test strategy — suggest offline scenario runner.

**7.2 [SIGNIFICANT]:** Prompt/schema versioning — `tess_orchestration_version` field.

**7.3 [SIGNIFICANT]:** Failure handling for partial deployments — feature flags for workflow disable.
