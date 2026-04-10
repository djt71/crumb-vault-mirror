---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/agent-to-agent-communication/specification.md
artifact_type: specification
artifact_hash: 30b5a3c4
prompt_hash: 0163ef38
base_ref: null
project: agent-to-agent-communication
domain: software
skill_origin: peer-review
created: 2026-03-04
updated: 2026-03-04
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "Line 282: 'customer' in context of 'customer decisions' (domain term, not PII)"
    - "Line 366: 'customer' in context of 'customer role' (domain term, not PII)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 67051
    attempts: 1
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-specification-openai.json
  google:
    http_status: 200
    latency_ms: 42676
    attempts: 1
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 85865
    attempts: 2
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 48740
    attempts: 1
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Agent-to-Agent Communication Specification

**Artifact:** Projects/agent-to-agent-communication/specification.md
**Mode:** full
**Reviewed:** 2026-03-04
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning
**Review prompt:** Full specification review -- correctness, completeness, internal consistency, feasibility, clarity. Focus areas: workflow ordering, HITL authority gaps, capability dispatch detail, circular dependencies, delivery layer decoupling, scope realism.

---

## OpenAI (gpt-5.2)

## Structured Review — Agent-to-Agent Communication (Crumb/Tess)

### Summary
The spec is strong in architecture intent (delivery abstraction, HITL gating, capability-based dispatch, auditability via correlation IDs) and has a credible phased build. Main risks: (1) some contradictions / circularities in build order and prerequisites, (2) HITL enforcement boundaries are underspecified (what exactly is “external action” and how tool calls are technically prevented), (3) capability manifests and selection logic need more concrete schemas and “where this code lives” details to be implementable quickly, and (4) Mission Control scope is large and could balloon without tighter API + data-model definition early.

---

## Findings

- **[F1]**
  - **Severity:** **CRITICAL**
  - **Finding:** **Potential circular dependency: Phase 1b “Quality review schema” depends on capability manifests (#24), which includes a “peer-review skill”, but the “critic skill” (A2A-011) is only built after Workflow 2 gate.**
  - **Why:** If peer-review/critic skills don’t exist yet, requiring their manifests to implement adaptive QA can block Phase 1b, or force placeholder manifests that don’t reflect reality.
  - **Fix:** Split A2A-024 into two deliverables:
    1) **Manifests for existing skills only** (researcher-skill, feed-triage if it exists today).  
    2) **Manifests for new review skills** delivered alongside A2A-011.  
    Then change A2A-006 dependency from “#24” to “#23 + researcher manifest exists”.

- **[F2]**
  - **Severity:** **CRITICAL**
  - **Finding:** **HITL tier definitions are policy-level, but mechanical enforcement boundary is not specified (what prevents Tess from performing Tier-2/3 actions via tools?).**
  - **Why:** The spec says “mechanical enforcement” (C4), but doesn’t define enforcement mechanism: tool access control, filesystem allowlists, command denylist, approval tokens required by wrappers, etc. Without this, HITL is aspirational and can be bypassed accidentally.
  - **Fix:** Add an “Enforcement” subsection to §9:
    - Define **tooling guardrails** (e.g., wrappers that require an AID token to call “external actions”: email send, calendar write, file move/delete outside whitelisted dirs, edits to `_system/`).
    - Define **filesystem permissions / path allowlists** for auto-approved writes (e.g., only `x-feed-intel/` and non-destructive note creation).
    - Define **approval token validation**: where tokens are stored, TTL, single-use, idempotency key.

- **[F3]**
  - **Severity:** **CRITICAL**
  - **Finding:** **Correlation IDs are defined, but the spec never defines the canonical “event/dispatch envelope” that must carry them end-to-end across files, adapters, and UI.**
  - **Why:** You’ll get partial adoption: some components log correlation_id, others won’t; then auditability and learning log joins become fragile/grep-heavy.
  - **Fix:** Define a minimal shared envelope (YAML/JSON) used everywhere:
    - `correlation_id`, `dispatch_id`, `workflow`, `intent`, `created_at`, `source` (trigger), `artifact_paths[]`, `cost`, `model`, `channel_provenance[]`.
    - Require every adapter + workflow writer to read/write the envelope.

- **[F4]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **Workflow ordering is mostly sound, but Workflow 2 could be safer before Workflow 1 if “feed-intel” triage quality is still in flux (M2 9/11).**
  - **Why:** Workflow 1 relies on “high-signal detection” and dedup; if the upstream feed scoring is unstable, you’ll spend early trust capital on noisy compound insights. Meanwhile Workflow 2 leverages an already-complete researcher-skill and can be initiated by explicit Danny requests (lower noise risk).
  - **Fix:** Keep Phase 1 as written if you can enforce strict throttles + high thresholds, but consider:
    - Phase 1: Delivery + context + feedback infra, then **Workflow 2 (manual-trigger research)** gate
    - Phase 1b: Workflow 1 (compound insights) once feed scoring stabilizes  
    Or: keep Workflow 1 first but start with **1/day ceiling** + “only from Danny-starred items” during gate.

- **[F5]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **Delivery layer decoupling is stated, but content shapes likely leak Telegram constraints (4096 chars) into “present” and “approve” unless you define a channel-neutral artifact representation.**
  - **Why:** If “present” continues to be “send text blob” with truncation handling, workflow logic will still care about Telegram limits, undermining the abstraction.
  - **Fix:** Define channel-neutral deliverables:
    - `present` always writes a **vault/web artifact** first (markdown file with metadata), then adapters send **link + summary** appropriate to channel.
    - Telegram adapter never receives full artifact text unless under size limit.
    - Make “telegram truncation” solely an adapter concern.

- **[F6]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **Capability-based dispatch (§8.6) is conceptually good but underspecified for implementation: schemas, parsing, versioning, and conflict resolution (multiple candidates) need concrete rules.**
  - **Why:** Without a strict manifest schema and resolution algorithm, Tess will make inconsistent choices and debugging will be hard.
  - **Fix:** Add:
    - A JSON Schema (or YAML schema) for SKILL.md frontmatter capabilities.
    - A **capability ID namespace convention** (`external.research`, `vault.query`, etc.).
    - A deterministic selection algorithm with tie-break order and required fields (`model_tier`, `tools`, `quality_signals`, `cost_profile`).
    - Manifest versioning: `manifest_version: 1`.
    - Cache strategy: optional local cache with invalidation by file mtime/hash.

- **[F7]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **Quality review schema mixes “structural checks” with model-judgment checks but doesn’t specify how structural checks are computed (what produces “convergence score”? what is “writing validation” exactly?).**
  - **Why:** Implementers won’t know whether this is LLM-eval, heuristic linting, or a downstream tool, and costs will vary dramatically.
  - **Fix:** For each check in §11.1 specify:
    - Source of truth (worker output field vs evaluator tool vs Tess LLM call)
    - Algorithm and thresholds per rigor profile
    - Cost implications (Haiku vs non-LLM)
    - Failure modes and re-dispatch criteria

- **[F8]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **Mission Control data model is “reads from SQLite/YAML/markdown” but no canonical indexing strategy is provided (how does UI list artifacts efficiently without duplicating data?).**
  - **Why:** UI work can stall on “how do we query markdown files by date/workflow/project” and turn into ad-hoc parsing.
  - **Fix:** Introduce a lightweight **artifact index** (append-only or regenerated):
    - `_openclaw/state/artifact-index.sqlite` or `.jsonl`
    - Populated by delivery router when `present` is called (single write path)
    - UI reads index; artifact content stays in markdown

- **[F9]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **Multi-channel approval “first-response-wins” is good, but idempotency key + expiry + replay protection aren’t specified.**
  - **Why:** Without TTL and replay protection, an old approval click could trigger later, or conflicting UI states could apply after completion.
  - **Fix:** Extend approval contract:
    - `approval_id` (idempotency key), `correlation_id`, `expires_at`, `status` (pending/approved/denied/expired)
    - Adapters must check status before applying
    - Store in `_openclaw/state/approvals.yaml` (append-only) + a small “current status” file

- **[F10]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **SE Account Prep depends on “account dossier schema” but does not specify minimum viable data required to produce a brief (contacts? last meeting notes? product usage?).**
  - **Why:** Workflow 3 can’t be validated in a 3-day gate if dossiers are sparse; you’ll conflate “workflow failure” with “data missing.”
  - **Fix:** Define an MVP dossier requirement + fallback behavior:
    - If dossier missing: generate a “data acquisition plan” + minimal brief
    - A “dossier completeness score” surfaced in output

- **[F11]**
  - **Severity:** **MINOR**
  - **Finding:** **Some terminology is inconsistent: “dispatch_id” vs “correlation_id” vs “group id”; “Tier 2 HITL” vs “Approval Contract”; “present artifact” vs “deliver doc”.**
  - **Why:** Small inconsistencies cause implementation mismatches across repositories.
  - **Fix:** Add a glossary and a canonical ID taxonomy:
    - `correlation_id` (end-to-end), `dispatch_id` (single worker run), `dispatch_group_id` (multi-dispatch), `approval_id` (HITL)

- **[F12]**
  - **Severity:** **MINOR**
  - **Finding:** **Gate evaluations are specified but not the measurement method (how is “utility rate” computed? what constitutes false positive?).**
  - **Why:** Without metrics definitions, gates become subjective and hard to compare across workflows.
  - **Fix:** Define explicit formulas:
    - Utility rate = useful / (useful + not-useful) over window
    - Edited counts as useful-with-friction
    - False positive rate = not-useful / total delivered
    - Add minimum sample size or “extend gate” rule

- **[F13]**
  - **Severity:** **STRENGTH**
  - **Finding:** **Clear separation of concerns: transport (bridge), orchestration (Tess), execution (Crumb), and delivery (router + adapters).**
  - **Why:** This is the core architectural move that enables incremental channels and additional workers.
  - **Fix:** None.

- **[F14]**
  - **Severity:** **STRENGTH**
  - **Finding:** **Progressive trust via gates + feedback/learning loop is well-integrated into build order.**
  - **Why:** This is how you avoid “autonomy shock” and makes the system operable for a solo operator.
  - **Fix:** None.

- **[F15]**
  - **Severity:** **STRENGTH**
  - **Finding:** **Capability-addressed dispatch with substitution test is a good practical heuristic.**
  - **Why:** Prevents overfitting capability taxonomy early and supports future plugin growth.
  - **Fix:** None (but implement the concrete details from F6).

- **[F16]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **25-task scope is plausible, but Mission Control + multi-dispatch + approval system together are a large integration surface; risk of schedule overrun unless you intentionally de-scope UI and keep adapters thin.**
  - **Why:** Solo operator + multi-repo changes = integration and debugging time dominates.
  - **Fix:** Merge/re-scope:
    - Phase 2 UI: **read-only + feedback only**, defer status dashboards/cost dashboards until you have artifact index + cost logs stable
    - Treat “approval panel” as separate milestone with its own hardening sprint
    - Consider merging A2A-019/020/021 into one “Operational Intelligence v1” task to reduce coordination overhead

---

## Review Focus Area Responses

### 1) Workflow order (dependency & risk)
- Current order is defensible: Workflow 1 is low external risk and builds daily habit loops.
- If feed-intel scoring is not stable (M2 incomplete), consider swapping earlier introduction of Workflow 2 (manual-trigger research) because it’s initiated by explicit demand and has clearer success criteria.

### 2) HITL authority gaps / exploitability
- Biggest gap: lack of mechanical enforcement spec (F2).
- Also missing: explicit classification of “destructive vault ops” (rename? move? frontmatter rewrite?) and “external actions” (email, calendar, CRM, git pushes).
- Add tool wrappers + allowlists + approval token TTL/idempotency to close bypasses.

### 3) Capability-based dispatch implementability
- Needs concrete manifest schema, IDs, deterministic resolution, caching, versioning (F6).
- Also specify where parsing code lives (OpenClaw gateway vs bridge runner vs shared lib) and how errors surface (escalate with diagnostics).

### 4) Circular dependencies in build order
- Main one is around manifests/QA/review skills (F1).
- Another soft circularity: Mission Control wants read views across heterogeneous stores without an index (F8); you’ll likely end up building an index anyway—make it explicit earlier.

### 5) Delivery abstraction decoupling vs Telegram leakage
- At risk unless `present` is “write artifact + notify link” and adapters own truncation/formatting (F5).
- Ensure workflows never branch on channel capabilities.

### 6) Realism of 25 tasks; redundancy / merge opportunities
- Realistic if you keep Phase 2 UI minimal and avoid building dashboards before you have canonical logs.
- Merge candidates:
  - Combine A2A-003 (feedback ledger) + approval status store + artifact index as one “state stores v1”
  - Combine A2A-019/020/021 into “Operational intelligence v1”
- Split candidates (to reduce blocking):
  - Split A2A-024 as in F1.

---

## UNVERIFIABLE CLAIM findings (require grounded verification)

- **[F17]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **UNVERIFIABLE CLAIM:** “crumb-tess-bridge is DONE… CTB-016 dispatch lifecycle with state machine, crash recovery, budget enforcement.”
  - **Why:** This references internal artifacts (CTB-016) and completion status that can’t be independently confirmed here; build order relies on it.
  - **Fix:** Link to commit hashes / test evidence or a short “bridge acceptance test report” file path.

- **[F18]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **UNVERIFIABLE CLAIM:** “Researcher-skill M5 is complete. 15/15 tasks done (2026-03-04).”
  - **Why:** The spec’s Phase 1b depends on this being truly operational.
  - **Fix:** Provide a checklist of capabilities proven + example outputs + where the skill lives.

- **[F19]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **UNVERIFIABLE CLAIM:** “CTB-016 §2.3 rule 12 enforces single active dispatch.”
  - **Why:** Multi-dispatch amendment design depends on existing semantics; misremembered constraints could break runner design.
  - **Fix:** Quote the exact rule text or link to the canonical CTB-016 file/section.

- **[F20]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **UNVERIFIABLE CLAIM:** “TOP-049 (Approval Contract) … currently designed for Telegram inline UI.”
  - **Why:** Approval model is a critical dependency; if TOP-049 differs, the channel-agnostic plan may need revision.
  - **Fix:** Reference the TOP-049 spec path and summarize current request/response schema.

- **[F21]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **UNVERIFIABLE CLAIM:** “Telegram has a 4,096-char message limit.”
  - **Why:** Adapter design and truncation behavior might be tuned to this number; Telegram limits can vary by API method/entity.
  - **Fix:** Cite Telegram Bot API documentation section or empirically verify with a small test and record result.

- **[F22]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **UNVERIFIABLE CLAIM:** “Tess runs Haiku 4.5 at ~$8.40/mo.”
  - **Why:** Budget governance and Sonnet escalation planning reference this baseline cost.
  - **Fix:** Provide calculation inputs: calls/day, tokens/call, pricing table version/date.

- **[F23]**
  - **Severity:** **SIGNIFICANT**
  - **Finding:** **UNVERIFIABLE CLAIM:** “solutions/claude-print-automation-patterns.md documented patterns…”
  - **Why:** Several implementation approaches assume those patterns exist and are adopted.
  - **Fix:** Link exact file path + ensure it’s in-repo and referenced by build tasks where relevant.

---

## Highest-impact recommended edits (short list)
1. Add HITL **mechanical enforcement** spec (tool wrappers, allowlists, approval token TTL/idempotency).
2. Define a canonical **dispatch/delivery envelope** carrying IDs and metadata.
3. Tighten capability manifests with a **versioned schema** + deterministic selection algorithm.
4. Add an **artifact index** to make Mission Control feasible without data duplication.
5. Adjust build dependencies to remove the **manifest/QA/review skill** circularity.

---

## Google (gemini-3-pro-preview)

Based on the review of the provided artifact, here is the structured evaluation.

### Executive Summary
The specification is highly detailed, logically structured, and demonstrates a sophisticated understanding of agentic patterns (e.g., decoupling orchestration from execution, capability-based routing). The "Deliver Layer" abstraction and "Capability Manifest" concepts are strong architectural choices that prevent vendor lock-in and enable scalability.

However, the "Mission Control Web UI" represents a massive scope spike in Phase 2 that risks stalling the project. Additionally, the capability system relies on string matching without a defined taxonomy, introducing integration risks.

### Unverifiable Claims
*   **UC-1** [SIGNIFICANT]: "F1. crumb-tess-bridge is DONE." / "CTB-016 dispatch lifecycle." (Internal project references).
*   **UC-2** [SIGNIFICANT]: "F2. Researcher-skill M5 is complete." (Internal project milestone).
*   **UC-3** [SIGNIFICANT]: "TOP-049 (Approval Contract)... TOP-009 morning briefing." (Internal operational protocols).
*   **UC-4** [SIGNIFICANT]: "Haiku 4.5 at ~$8.40/mo." (Model Reference/Price). **Note:** There is no public "Claude 4.5 Haiku" model. This is likely a typo for 3.5 or an internal projection.
*   **UC-5** [MINOR]: "Telegram has a 4,096-char message limit." (Generally accepted, but API limits can vary by context/formatting).

### Findings

#### Critical
**[F1] [CRITICAL] [Scope Underestimation of Mission Control]**
**Finding:** Task A2A-012 "Build mission control web UI — Phase 1" is scoped as a single task in Phase 2. It requires setting up Express, SSR, Cloudflare Auth integration, data fetching from multiple sources (SQLite + YAML), and a responsive UI.
**Why:** This is a full-stack engineering project disguised as a sub-task. If this stalls, Phase 2 blocks. The complexity of rendering arbitrary artifacts ("artifact browser") is non-trivial.
**Fix:** Break A2A-012 into at least three tasks: (1) Server/Auth scaffolding, (2) Read-only API layer over existing files/DB, (3) Frontend views. Consider using a simpler stack (e.g., Streamlit or a static generator with simple auth) for the "Read" phase to reduce effort.

**[F2] [CRITICAL] [Lack of Capability Taxonomy]**
**Finding:** Section 8.6 defines how capabilities are resolved ("exact match on capability ID") but does not establish a registry or taxonomy for these IDs.
**Why:** If a workflow requests `external-research` and a new skill declares `web-research`, the exact match fails. Without a controlled vocabulary, "String Drift" will prevent skills from being discovered.
**Fix:** Add a task in Phase 1b to define a `_system/capabilities/taxonomy.yaml` or similar registry that lists valid Capability IDs and their definitions. Enforce that SKILL.md manifests must use IDs from this registry.

#### Significant
**[F3] [SIGNIFICANT] [Ambiguity in "Present" Intent for Telegram]**
**Finding:** Section 7.2 states `present` intent routes to "Web UI (primary) + chat channel notification". In Phase 1, Web UI does not exist. Section 10.1 (Workflow 1) uses `present`.
**Why:** It is unclear how a "Compound Insight" (which has frontmatter, cross-refs, etc.) renders in Telegram during Phase 1. If it renders as a raw file dump, mobile readability will be poor.
**Fix:** Explicitly define the "Degraded Mode" for the `present` intent in the Telegram adapter (e.g., "Render Summary + Link to Local File" or "Chunked Text Messages").

**[F4] [SIGNIFICANT] [Orchestration Code Duality]**
**Finding:** Workflow 1 (Compound Insights) explicitly excludes capability-based dispatch (Section 8.6), using a template-write model. Workflow 2 uses capability dispatch.
**Why:** This creates two parallel orchestration patterns in the codebase immediately. "Legacy" direct dispatch and "New" capability dispatch will compete, increasing maintenance load and confusing future development.
**Fix:** Standardize Workflow 1 to use a `compound-insight-writer` capability, even if Crumb is currently the only provider. Avoid hard-coding specific agent names in the orchestration logic from the start.

**[F5] [SIGNIFICANT] [Feedback Signal Loophole]**
**Finding:** The Feedback Ledger (8.2) records signals. However, there is no specification for how the *Orchestrator* (Tess) reads this ledger *before* dispatching. Section 8.4 mentions a "Dispatch Learning Log" consulted at brief formulation, but it's unclear if the Feedback Ledger automatically feeds into the Learning Log or if they are separate silos.
**Why:** If feedback is recorded but not indexed into the Learning Log, the system does not learn.
**Fix:** Explicitly link A2A-003 (Feedback) and A2A-008 (Learning Log). Define a cron job or event trigger that summarizes raw feedback into the `pattern_note` used in the Learning Log.

#### Minor
**[F6] [MINOR] [Inconsistent Terminology for Reviewer]**
**Finding:** Section 11.2 refers to "Critic Skill". Section 8.6 table refers to "Peer-review skill".
**Why:** Confusing naming conventions makes it harder to map dependencies.
**Fix:** Standardize on "Critic" or "Reviewer" throughout the spec.

**[F7] [MINOR] [Manual Triage of Feed Intel]**
**Finding:** Workflow 1 starts with "Pipeline captures and triages".
**Why:** It is not explicitly stated if this triage is purely algorithmic or requires Danny's input *before* Tess sees it. "High-signal items" suggests algorithmic, but worth clarifying.
**Fix:** Clarify that "triage" in step 1 is the automated scoring system from `feed-intel-framework`.

#### Strength
**[F8] [STRENGTH] [Delivery Adapter Pattern]**
**Finding:** Decoupling the "Intent" (Notify, Present, Approve) from the "Channel" (Telegram, Web) is an excellent architectural decision (Section 7.2).
**Why:** This allows the system to switch from Telegram to Discord or a custom app without rewriting a single line of business logic in the workflows.

**[F9] [STRENGTH] [Substitution Test Heuristic]**
**Finding:** The granularity heuristic for capabilities ("Can you name a plausible second skill?") is a very practical, high-value design rule.
**Why:** It prevents over-engineering abstract capabilities that will never actually be swapped out.

---

### Focus Area Responses

1.  **Workflow Ordering:**
    *   **Verdict:** Correct.
    *   **Analysis:** Starting with Compound Insights (Workflow 1) is safe because it is read-heavy and produces internal notes. Moving to Research (Workflow 2) next is logical as it introduces external calls. Account Prep (Workflow 3) is correctly placed later as it has high stakes (meeting deadlines) and requires multi-dispatch.

2.  **HITL Authority Model:**
    *   **Verdict:** Gaps exist regarding "Modification".
    *   **Analysis:** The model distinguishes between "Read" (Tier 1) and "Destructive" (Tier 2). It misses "Constructive Modification" (e.g., appending to a log, updating a status field in an existing file).
    *   **Fix:** Explicitly categorize "Append/Update" operations. Usually, these should be Tier 1 if the schema is strict, or Tier 2 if free-text.

3.  **Capability-Based Dispatch:**
    *   **Verdict:** Needs more detail (See Finding F2).
    *   **Analysis:** The concept is sound, but the implementation detail of *how* the orchestrator knows which strings are valid capabilities is missing. "Passive registration" works for discovery, but not for request formulation.

4.  **Circular Dependencies:**
    *   **Verdict:** None found.
    *   **Analysis:** The build order is linear and respects the "Infrastructure -> Workflow -> Evaluation" cycle.

5.  **Delivery Layer Abstraction:**
    *   **Verdict:** Strong, but Phase 1 Telegram implementation needs care.
    *   **Analysis:** The abstraction holds up. The main risk is that complex artifacts (like the Compound Insight) will look terrible on Telegram without a specific "Degraded" view logic.

6.  **Scope Realism:**
    *   **Verdict:** Phase 1 is realistic. Phase 2 (Mission Control) is not.
    *   **Analysis:** A solo operator building a robust orchestrator *and* a full-stack web app simultaneously is a recipe for burnout.
    *   **Recommendation:** Drastically reduce the scope of "Mission Control" in Phase 2 to a read-only HTML generator (static site) that regenerates on file changes, rather than a dynamic SSR app. Rely on Telegram for "Actions" (Approvals) longer.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of Agent-to-Agent Communication Specification**

**Overall Assessment:** A comprehensive, well-structured, and ambitious specification for a personal multi-agent orchestration system. It demonstrates strong systems thinking, clear architectural vision, and a practical, phased approach. The core ideas—channel-agnostic delivery, capability-based dispatch, and a progressive HITL model—are sound and logically derived from the stated problem. The primary risks are in implementation complexity and the potential for subtle gaps in the authority and coordination models.

---

### **Findings**

#### **CRITICAL**

**F1. Circular Dependency in Phase 1b Task Order**
- **Severity:** CRITICAL
- **Finding:** Task `A2A-025 (Implement capability resolution)` is a dependency for `A2A-009 (Build Workflow 2)`. However, `A2A-025` itself likely depends on the capability manifests created in `A2A-024`. This creates a logical loop where the resolution engine cannot be built without manifests, but the need for the engine motivates creating the manifests. The build order lists `A2A-025` after `A2A-009`, which is impossible.
- **Why:** This blocks the implementation sequence. Workflow 2 cannot be "capability-addressed" without the resolution logic.
- **Fix:** Reorder Phase 1b. `A2A-023 (Define schema)` and `A2A-024 (Add manifests)` are prerequisites. `A2A-025 (Implement resolution)` must be completed **before** `A2A-009 (Build Workflow 2)`. Update the dependency list for `A2A-009` accordingly.

**F2. Missing Escalation Path for Auto-Resolution Failures**
- **Severity:** CRITICAL
- **Finding:** Section 9.2 defines auto-resolution for scope/access escalations and mandates escalation for low-confidence outcomes. However, it does not specify what happens if Tess's *attempt* at auto-resolution fails (e.g., context is insufficient, the resolution logic throws an error). The system could hang in an undelivered state.
- **Why:** Failures in the auto-resolution logic itself are inevitable and must be handled gracefully. An unhandled error breaks the workflow and loses the user's request.
- **Fix:** Add a catch-all failure mode: "If Tess cannot execute an auto-resolution (due to error, missing data, or logic indeterminacy), treat as a 'Conflict' escalation and surface to Danny with the error details."

#### **SIGNIFICANT**

**F3. Capability-Based Dispatch Lacks Concrete Resolution Algorithm**
- **Severity:** SIGNIFICANT
- **Finding:** Section 8.6 states the *principle* of capability-addressed dispatch and lists selection criteria (learning log, cost fit, etc.), but does not provide a concrete, implementable algorithm for Tess to choose between multiple candidate skills offering the same capability. How are the criteria weighted? What is the tie-breaker?
- **Why:** This ambiguity will lead to inconsistent dispatch behavior and make the system harder to debug. An implementer (or Tess's prompt) needs a deterministic rule.
- **Fix:** Specify a simple, deterministic algorithm. For example: "1. Filter candidates by `required_tools` availability. 2. Select candidate with highest average `outcome_signal` in learning log (min 3 entries). 3. Tie-break by lower manifest `cost_profile`. 4. Final tie-break: alphabetical by skill name." Document this in `A2A-025`.

**F4. Delivery Layer Abstraction May Leak Telegram in Early Phases**
- **Severity:** SIGNIFICANT
- **Finding:** The Phase 1 implementation of the delivery layer is "Telegram-only with abstract interface." While the interface is abstract, the routing rules and `converse` intent are inherently Telegram-centric. The `present` intent will be truncated by the 4096-char limit, which is a channel-specific constraint influencing artifact design.
- **Why:** If workflows are built anticipating Telegram's limits and synchronous chat model, they may not generalize cleanly to a web UI or Discord later. The abstraction could be a thin facade over Telegram-specific logic.
- **Fix:** In Phase 1, design artifact payloads for a web-first `present` intent (full-length), with the Telegram adapter responsible for intelligent truncation + linking. Treat `converse` as a legacy pattern for Phase 1; new workflows should use `approve` and `feedback` intents instead.

**F5. Unverifiable Claims About Component States**
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** The "Facts" section (F1, F2, F3, F4, F5, F12) makes specific claims about the completion status of internal components (`crumb-tess-bridge is DONE`, `Researcher-skill M5 is complete`, references to `TOP-*` tasks). The reviewer cannot verify these project states.
- **Why:** The entire specification's feasibility and sequencing depend on the truth of these foundational claims. If they are inaccurate, the build order collapses.
- **Fix:** This is an inherent limitation of an external review. The author must ensure these facts are correct before proceeding.

**F6. Ambiguity in Multi-Channel Approval "First-Response-Wins"**
- **Severity:** SIGNIFICANT
- **Finding:** Section 7.2 and 9.1 state that for `approve` intents, the first response across any channel is authoritative. This could lead to unintended approvals if Danny interacts with a notification on one channel without fully reviewing the context on another.
- **Why:** Creates a usability risk and could reduce trust in the approval system. Danny might "mark as read" on Telegram, accidentally triggering an approval meant for deeper review on the web UI.
- **Fix:** Refine the rule. Propose: "`approve` intents are delivered to all *active* channels. The response from the channel designated *primary for approvals* (configurable, default web UI) is authoritative. Responses from other channels are logged as 'acknowledged' but do not resolve the contract unless the primary channel is inactive for a timeout period (e.g., 5 min)."

#### **MINOR**

**F7. Workflow 4 Appears Under-Specified**
- **Severity:** MINOR
- **Finding:** Workflow 4 (Vault Gardening) is described at a high level but lacks the concrete schemas, tier definitions, and action mappings that are present for Workflows 1-3. Its dependency is simply "TOP-049 operational."
- **Why:** This makes Task `A2A-018` riskier and less scoped than its peers. What *specifically* constitutes a Tier 1 auto-fix?
- **Fix:** Before `A2A-018`, add a small `SPECIFY` task to define the tier classification matrix (e.g., Tier 1: `vault-check.sh` errors with deterministic fixes like `[[404]]`).

**F8. Potential Task Redundancy**
- **Severity:** MINOR
- **Finding:** `A2A-023 (Define capability manifest schema)` and `A2A-024 (Add manifests to skills)` are tightly coupled and small. They could be merged into a single task.
- **Why:** Reduces task overhead and management. Defining the schema is trivial without implementing it in actual skills.
- **Fix:** Merge into a single task: **"A2A-023: Implement capability manifest schema and register for existing skills."**

**F9. "Solo Operator" Constraint Could Be Stressed by Mission Control Complexity**
- **Severity:** MINOR
- **Finding:** The mission control web UI (Phases 2 & 3) represents significant full-stack development work (Express, SSR, Cloudflare config, real-time UI). This may conflict with Constraint C1: "System must reduce Danny's load, not add to it."
- **Why:** Building and maintaining a secure web UI is a substantial time investment for a solo operator, potentially negating the time-saving benefits of automation.
- **Fix:** Re-emphasize the incremental approach. Phase 1 (`read + feedback`) should be extremely minimal—a simple, secure static site that reads from the ledger and dispatch logs. Defer all interactive complexity until the core agent workflows are proven to save time.

#### **STRENGTHS**

**F10. Excellent Architectural Separation and Incremental Strategy**
- **Severity:** STRENGTH
- **Finding:** The specification successfully decouples concerns: delivery layer, capability model, HITL gates, and workflows are distinct. The build order is wisely sequenced to deliver compound value early (Workflow 1) while building foundational plates (delivery, feedback) that unlock more advanced workflows.
- **Why:** This maximizes learning and value at each phase, reduces risk, and follows sound software architecture principles.

**F11. Pragmatic and Well-Defined Constraints & Levers**
- **Severity:** STRENGTH
- **Finding:** Constraints (C1-C5) are clear and realistic for a personal system. Levers (L1-L4) correctly identify the highest-impact intervention points (Delivery Layer, Feedback).
- **Why:** Provides a robust framework for making trade-off decisions during implementation. The focus on feedback as the primary learning mechanism is particularly astute.

**F12. Comprehensive Consideration of Failure Modes and Audit**
- **Severity:** STRENGTH
- **Finding:** The design consistently considers failure (re-dispatch limits, escalation paths, crash recovery), idempotency (approvals), and audit (correlation IDs, provenance, channel logging).
- **Why:** This operational rigor is often missing from speculative AI agent designs and is crucial for building a trustworthy, debuggable system.

---

### **Answers to Focus Areas**

1.  **Workflow Ordering:** The order (1. Compound Insights, 2. Research, 3. SE Prep, 4. Gardening) is logical based on dependencies and risk. Promoting Research (now 1b) is correct given the completed skill. SE Prep depends on multi-dispatch, justifying its later place. The sequence is sound.

2.  **HITL Authority Gaps:** The main gap is the missing failure mode for auto-resolution (F2). Additionally, the boundary between "destructive vault ops" (Tier 2) and "architectural decisions" (Tier 3) could be fuzzy. Is moving a note between folders architectural? A clearer rubric or examples for Tier 3 would help.

3.  **Capability Dispatch Specification:** It is well-specified in *concept* but needs the concrete resolution algorithm (F3) to be implementable. The "substitution test" heuristic and schema registry are excellent practical details.

4.  **Circular Dependencies:** Yes, one critical circular dependency exists in the Phase 1b task list (F1). The rest of the build order is logically sound.

5.  **Delivery Layer Decoupling:** The abstraction is conceptually correct and will decouple *logic* from channels. However, there is a risk of Telegram semantics (message limits, chat paradigm) influencing workflow design if not carefully guarded against in Phase 1 (F4).

6.  **25-Task Scope Realism:** For a solo operator with agent assistance, the 25-task scope over multiple phases is realistic. The phases provide natural breaks. One minor redundancy was found (F8), but the tasks are otherwise well-scoped and distinct. The most significant risk is the mission control UI scope creep (F9).

---

## Grok (grok-4-1-fast-reasoning)

- [C1]
- [Severity]: CRITICAL
- [Finding]: Build order (§19) and task decomposition (§21) have inconsistent and non-sequential numbering (e.g., Phase 1 ends at #5, Phase 1b jumps to #23/#24 then back to #6/#7, with #25 appearing late; A2A-IDs match 001-025 but table sequencing skips).
- [Why]: Creates confusion in execution order, risks misprioritization or skipped tasks, undermines the "dependency"-column claims (e.g., A2A-009 depends on #6 but #6 is listed after #23 in Phase 1b).
- [Fix]: Renumber tasks sequentially across phases (e.g., Phase 1: 1-5, Phase 1b: 6-15) and ensure table rows match A2A-ID order with explicit prereqs.

- [C2]
- [Severity]: CRITICAL
- [Finding]: No explicit handling for dispatch budget approval in HITL model (§9); Tier 2 mentions "budget above threshold" but workflows like compound insights (Workflow 1) auto-dispatch Crumb without AID-* gate, potentially exceeding daily costs without Danny's signoff.
- [Why]: Violates C2 cost ceiling and C4 HITL enforcement; solo operator could wake to surprise bills if noise ceiling wrong.
- [Fix]: Define dispatch budget as Tier 2 trigger (e.g., >$0.50/dispatch → AID-*); add to §9.1 table and Workflow 1 flow.

- [C3]
- [Severity]: CRITICAL
- [Finding]: Feedback infrastructure (§8.2) is append-only ledger with "no feedback = no signal (graceful degradation)", but dispatch learning log (§8.4) requires "outcome_signal" from feedback to update patterns — creating a chicken-egg where new workflows have zero learning data and can't improve.
- [Why]: Breaks L2 feedback leverage and adaptive routing; early workflows starve for signal, leading to persistent poor performance.
- [Fix]: Seed learning log with cold-start defaults from skill manifests; allow Tess-generated interim signals (e.g., quality gate pass/fail) as bootstrap.

- [S1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: All Facts F1-F14 (e.g., "crumb-tess-bridge is DONE", "Researcher-skill M5 is complete 15/15 tasks", "Tess runs Haiku 4.5 at ~$8.40/mo", CTB-016 §2.3 rule 12, TOP-049 design, etc.) reference internal milestones, files (e.g., `x-feed-intel/design/...`), and states without external links or excerpts.
- [Why]: Review can't assess correctness or completeness of prerequisites; risks building on sand if claims overstated (e.g., if researcher-skill not truly "full pipeline operational").
- [Fix]: Append excerpts/screenshots/hashes of key files (e.g., SKILL.md for researcher, CTB-016 spec snippet) or link to vault paths.

- [S2]
- [Severity]: SIGNIFICANT
- [Finding]: Workflow ordering prioritizes Compound Insights (1) correctly low-risk, but Workflow 2 (Research) "promoted" solely because researcher-skill "ready" (F2); ignores that it requires new infra (capability dispatch A2A-025, quality schema A2A-006) making it higher-risk than documented.
- [Why]: Mismatches "dependency and risk" rationale; Phase 1b conditionals (e.g., "smoke-tested") could stall if skill doesn't declare capabilities cleanly.
- [Fix]: Demote Workflow 2 to Phase 2 unless Phase 1b prereqs hardened; sequence as 1→Gardening (uses existing vault-check)→2→3.

- [S3]
- [Severity]: SIGNIFICANT
- [Finding]: HITL model (§9) has gaps: dispatch initiation itself unclassified (Tier 1?); "new notes/insights" auto-approved but no rollback on feedback="not-useful"; Tier 3 "customer decisions" vague (e.g., SE prep implications?).
- [Why]: Exploit risk (e.g., Tess spams dispatches as "vault ops"); violates C4 mechanical enforcement and progressive trust (L4).
- [Fix]: Classify "initiate dispatch group" as Tier 2 if >1 worker or budget>$1; add feedback→rollback (e.g., archive bad insights); enumerate 3-5 Tier 3 examples.

- [S4]
- [Severity]: SIGNIFICANT
- [Finding]: Capability-based dispatch (§8.6) lacks concrete YAML schema for manifests (lists fields verbally but no example); resolution logic (learning log → cost → quality → tier) has no tiebreaker or fallback weights.
- [Why]: Not implementable without iteration; Haiku (A1) may hallucinate parses; "passive registration" latency unbenchmarked (A7).
- [Fix]: Add full YAML example for researcher-skill manifest; define weighted scoring (e.g., learning log 40%); prototype parse in Phase 1 PLAN.

- [S5]
- [Severity]: SIGNIFICANT
- [Finding]: Potential circular dependency in Phase 1b: A2A-009 (Workflow 2) depends on A2A-025 (capability resolution), but A2A-025 needs "skills with manifests" (A2A-024), and manifests reference "research-brief.yaml" from A2A-023 — but no cycle if sequential, yet table lists 25 before 9 confusingly.
- [Why]: Risks stalled Phase 1b; conditionals don't resolve cycle if researcher-skill manifest extraction fails.
- [Fix]: Explicitly sequence A2A-023→024→025→009; make Phase 1b gate require manifests validated.

- [S6]
- [Severity]: SIGNIFICANT
- [Finding]: Delivery layer (§7) claims decoupling but Phase 1 is "Telegram-only with abstract interface" wrapping "existing delivery code"; if current Telegram code scattered (F9 limit implies it is), leaks inevitable (e.g., workflows hardcode truncation).
- [Why]: Undermines L1 lever; future channels require full rewrite if not truly abstracted now.
- [Fix]: Audit/excerpt current Telegram code in spec; mandate all Phase 1 workflows use ONLY `deliver()` with no direct imports; add unit test for mock adapter.

- [S7]
- [Severity]: SIGNIFICANT
- [Finding]: 25-task scope overambitious for solo operator: 18/25 tagged `#code`/`#architecture` (high-risk), Phases 1-3 span months implied by 3-day gates + prereqs (e.g., TOP-049); no agent assistance for building this meta-system.
- [Why]: Violates C1 (reduce load); agents (Tess/Crumb) not yet orchestrating their own build, leading to burnout.
- [Fix]: Merge/merge low-value (e.g., A2A-008 learning log into A2A-003 feedback); cut Phase 3 to roadmap; assign 20% tasks to Crumb via manual dispatch.

- [S8]
- [Severity]: SIGNIFICANT
- [Finding]: Multi-dispatch (§8.5) amends CTB-016 post-Workflow 1 proof, but Workflow 3 deps on it (#13 before #15); assumes bridge runner extensible without breakage.
- [Why]: F7 single-dispatch rule hardcoded? Risks Workflow 3 stall if amendment fails.
- [Fix]: Prototype multi-dispatch in Phase 1 gate as optional; make Workflow 3 conditional on it.

- [M1]
- [Severity]: MINOR
- [Finding]: Assumptions A1-A7 lack explicit validation owners/metrics beyond "Validate: Workflow 1 gate"; e.g., A6 8K context "track failures" vague.
- [Why]: Reduces traceability; gates may overlook.
- [Fix]: Table per-assumption: metric (e.g., A1: % judgment errors), owner (Tess/Danny), gate.

- [M2]
- [Severity]: MINOR
- [Finding]: Unknowns U1-U7 listed but resolutions tie to "Phase X PLAN" without timelines; U5 multi-channel conflicts assumes "first-response-wins" without UX details.
- [Why]: Delays decisions; Danny unclear on multi-channel rollout.
- [Fix]: Add estimated resolution task IDs (e.g., U1 → A2A-XXX orchestration hosting).

- [M3]
- [Severity]: MINOR
- [Finding]: Quality schema (§11.1) "adaptive" filters by manifest, but relevance "always applies" (Tess judgment) — Haiku risk high for subjective check.
- [Why]: False positives on delivery; A1 unproven.
- [Fix]: Threshold relevance (e.g., low → escalate); Sonnet for it initially.

- [M4]
- [Severity]: MINOR
- [Finding]: Mission control (§12) hosting Cloudflare Tunnel unverified for "approval gates" (U3); Phase 1 read-only but API "anticipates" all phases (A4).
- [Why]: Scope creep risk; mobile unproven.
- [Fix]: Phase 1 prototype without auth first; validate Tunnel in PLAN.

- [M5]
- [Severity]: MINOR
- [Finding]: Compound insight schema (§10.1) requires "confidence" but no generation logic (Tess? Crumb?).
- [Why]: Inconsistent provenance (§11.3).
- [Fix]: Specify: Crumb sets, Tess overrides post-gate.

- [T1]
- [Severity]: STRENGTH
- [Finding]: Architecture diagram (§5.2) clearly illustrates file-based transport (C5) and delivery abstraction (L1), with atomic handoff proven (F1).
- [Why]: Visual aid reduces misinterpretation; aligns constraints.
- [Fix]: N/A (but edge: add worker N+1 label consistency).

- [T2]
- [Severity]: STRENGTH
- [Finding]: HITL tiers (§9.1 table) cover spectrum with examples; escalation auto-res (§9.2) logged/mechanical.
- [Why]: Enforces C4 progressively (L4); low exploit surface if dispatch budgeted (contra C2).
- [Fix]: N/A (edge: test low-confidence override).

- [T3]
- [Severity]: STRENGTH
- [Finding]: Phased build order (§19) with gates and conditionals sequences by risk/deps (e.g., single→multi-dispatch); 3-day evals (A5) feasible.
- [Why]: Mitigates solo scope (C1); Workflow 1 low-risk entry proven.
- [Fix]: N/A (challenge: assumes feed-intel M2 finishes on time).

---

## Synthesis

*Integrated across 6 reviewers: OpenAI GPT-5.2 (OAI), Google Gemini 3 Pro (GEM), DeepSeek Reasoner (DS), Grok 4.1 Fast (GRK), Claude Opus 4.6 external session (EXT), and Perplexity Sonar Reasoning Pro (PPLX). EXT had ground-truth vault access; PPLX reviewed the formal specification.md directly.*

### Consensus Findings

**1. Phase 1b dependency ordering is broken** (OAI-F1, DS-F1, GRK-C1, GRK-S5) — 4/5 reviewers
The build order table in §19 Phase 1b has confusing non-sequential numbering (#23, #24, #6, #7, #8, #25, #9) and a logical dependency issue: A2A-009 (Workflow 2) depends on A2A-025 (capability resolution), but the table lists #25 after #9. The actual sequence must be A2A-023 → A2A-024 → A2A-025 → A2A-009. OpenAI also flags that A2A-024 includes manifests for skills that don't exist yet (critic), which should be split.

**2. Capability dispatch resolution underspecified** (OAI-F6, GEM-F2, DS-F3, GRK-S4, EXT-F11, EXT-F12, PPLX-4.2, PPLX-4.3) — 6/6 reviewers
§8.6 defines the principle of capability-based dispatch but lacks: a concrete YAML schema for manifests, a capability ID namespace convention, a deterministic selection algorithm with tiebreaker, and versioning. Every reviewer flagged this. EXT adds that the cost_profile should be rigor-specific (light/standard/deep ranges) since rigor is the primary cost driver. PPLX adds the strongest formulation: manifests need explicit `supported_rigor: [quick, standard, deep]` and briefs need `rigor:` — Tess must filter candidates by rigor compatibility *before* cost/learning-log selection. Also proposes `domain.purpose.variant` naming convention and no-synonym rule for capability IDs.

**3. Delivery layer risks Telegram leakage** (OAI-F5, GEM-F3, DS-F4, GRK-S6) — 4/6 reviewers
Phase 1's "Telegram-only with abstract interface" risks leaking the 4096-char limit into workflow logic. All recommend: artifacts should be vault/web-first, with adapters owning truncation and formatting. Workflows should never branch on channel capabilities.

**4. Mission Control scope is too large for a single task** (GEM-F1, OAI-F16, DS-F9, GRK-S7, PPLX-5.2) — 5/6 reviewers
A2A-012 is a full-stack project (Express + SSR + Cloudflare Auth + multi-source data fetching + responsive UI) disguised as one task. Gemini recommends breaking into 3 sub-tasks; others recommend radically reducing scope (static site generator vs. dynamic SSR). PPLX adds: consider delaying Mission Control until after vault gardening + dispatch retrospective have run — front-loading UI before A2A behavior is stabilized risks rework. All flag tension with C1 (reduce Danny's load).

**5. HITL mechanical enforcement unspecified** (OAI-F2, GRK-C2, GRK-S3) — 3/6 reviewers
The spec says "mechanical enforcement" (C4) but doesn't define the mechanism: tool guardrails, filesystem path allowlists, approval token validation, dispatch budget gates. Without this, HITL is aspirational. Grok uniquely adds that dispatch initiation itself should be classified (what tier?) and that there's no rollback for bad auto-approved outputs. (Note: EXT praises P3 as consistently applied but doesn't flag the missing implementation details — the automated panel is stronger here.)

**6. Feedback / learning log bootstrapping gaps** (GEM-F5, GRK-C3, EXT-F2, PPLX-2.3) — 4/6 reviewers
New workflows have zero feedback data, but the learning log requires outcome_signal from feedback. No seeding mechanism exists. Grok suggests quality gate pass/fail as bootstrap; Gemini asks for explicit ledger→log linkage. EXT adds that the pattern_note inference is weak on qualitative issues. PPLX adds the strongest formulation: define a mechanical rule where learning log entries are only created when a dispatch completes AND a feedback entry exists (or a timeout window passes, logged as "no-feedback" outcome). Distinguish "no-feedback yet" vs "no-feedback after window."

**7. Multi-channel approval needs more detail** (OAI-F9, DS-F6, PPLX-6.3) — 3/6 reviewers
"First-response-wins" lacks TTL/expiry, replay protection, idempotency key, and primary channel designation. DeepSeek raises a UX concern: Danny might "mark as read" on Telegram, accidentally triggering an approval. PPLX adds: define that availability of any one configured channel is sufficient to proceed; others are best-effort, failures logged but non-fatal.

**8. Unverifiable internal claims — resolved by EXT** (OAI-F17-23, GEM-UC1-5, DS-F5, GRK-S1, EXT-§5) — all reviewers
The automated panel flagged all Facts (F1-F14) as unverifiable. EXT validated them against actual project files: researcher-skill M5 confirmed (15/15), FIF actually *better* than claimed (M3 done, not just M2 9/11), CTB confirmed DONE (37 tasks, 897 tests), TOP-009 confirmed done. TOP-053 "operational" is generous (deployed with caveats). **This finding is now closed** — claims are verified with caveats noted.

### Unique Findings

**EXT-F8 + PPLX-1.2 + PPLX-2.1 + PPLX-5.1: Multi-dispatch is sequential, not parallel — now consensus** — CRITICAL, promoted from unique to consensus (2/6 reviewers)
Claude Code sessions are single-threaded (lockfile prevents concurrent sessions; concurrent vault writers are unsafe). Dispatch groups proposing 2-3 "concurrent" dispatches to Crumb can't actually run in parallel. The real model is sequential-with-shared-context: Tess holds the join contract, dispatches branch A, waits, dispatches branch B, then merges. PPLX goes further: demote multi-dispatch from generic infra prerequisite to "Workflow-3-specific orchestration pattern." Implement W3 with simple two-step sequential dispatch + synthesis logic; only introduce CTB-016 amendments if Research Council or cascading chains prove needed. This removes A2A-013 as a hard W3 prerequisite — high-ROI SE prep unblocked earlier.

**EXT-F3: CTB-016 "rule 12" may not exist as described** — SIGNIFICANT, grounded fact-check
The reviewer searched the CTB specification for "rule 12" and a single-active-dispatch restriction — couldn't find it. The global flock enforces single-bridge-session (preventing overlap with interactive Claude Code), which is a different constraint. Multi-dispatch infrastructure may be solving a problem that doesn't exist in the described form. Must verify actual CTB lockfile semantics before designing §8.5.

**EXT-F1: Haiku orchestration capacity needs A/B validation** — CRITICAL, reframes model tier question
Even Workflow 1 requires judgment work (cross-reference genuineness, implication formulation), not just pattern matching. If Haiku produces low-quality compound insights during the gate period, the gate itself produces garbage data — you can't measure quality from garbage. Fix: run Haiku vs Sonnet A/B comparison (5 items each) as the *first* gate activity, not after-the-fact.

**EXT-F5: Workflow 1 trigger language mismatches FIF's output format** — SIGNIFICANT, implementability blocker
The spec says "top quartile of historical scores" but FIF's triage produces tier assignments (T1/T2/T3), not continuous scores. The threshold language needs to be replaced with tier-based selection (e.g., "all T1 items + T2 items matching active project tags"). This affects whether the pipeline receives 2 items/day or 20.

**EXT-F13: Phase 3 real timeline is much longer than effort estimates suggest** — SIGNIFICANT, expectation calibration
Workflow 3 requires TOP-027 (calendar) → TOP-016/017 (Google integration) → TOP-014 (M1 gate pass) → M0+M1 operational. TOP-049 (Approval Contract) has a similar chain. Phase 3 is gated on several tess-operations milestones completing — realistically Q3 2026 at earliest, not "next month." The per-task effort estimates are accurate but the calendar timeline is much longer.

**DS-F2: Missing escalation path for auto-resolution failures** — CRITICAL, genuine insight
§9.2 defines auto-resolution for scope/access escalations but doesn't handle what happens if the resolution *logic itself* fails (error, missing data, indeterminate). The system could hang. Fix: catch-all → treat as Conflict escalation to Danny with error details.

**OAI-F3: No canonical dispatch envelope** — CRITICAL, genuine insight
Correlation IDs are defined but no shared envelope schema carries them end-to-end. Without this, adoption will be inconsistent and traceability fragile. Fix: define a minimal YAML/JSON envelope.

**GRK-C2: Dispatch budget not in HITL tiers** — CRITICAL, genuine insight
Tier 2 mentions "budget above threshold" but workflows like Workflow 1 auto-dispatch Crumb without a cost gate. Fix: define a dispatch cost threshold for Tier 2.

**OAI-F7: Quality check computation sources unspecified** — SIGNIFICANT, genuine gap
What produces "convergence score"? What is "writing validation"? Fix: specify source of truth and algorithm per check.

**OAI-F8: Mission Control needs artifact index** — SIGNIFICANT, genuine for Phase 2
Fix: lightweight artifact index populated by delivery router. Defer to Phase 2 PLAN.

**EXT-F4: Confidence-based escalation override lacks calibration** — SIGNIFICANT
"Low confidence" is undefined operationally. Without calibration, Tess either always escalates (defeating the purpose) or never escalates (bypassing the safety net). Fix: start with N-entries heuristic (escalate if account/project has < N entries in learning log); calibrate N during gate.

**EXT-F9 + PPLX-2.2: Mid-day context staleness for time-sensitive workflows** — SIGNIFICANT, consensus (2/6)
tess-context.md refreshes at morning briefing only. Mid-day priority changes make context stale for Workflow 3. EXT suggests lightweight context refresh before brief formulation. PPLX adds a tiered staleness model: "soft stale" (>24h, warn) vs "hard stale" (>N days, certain workflows disallowed). For time-sensitive workflows, stale context should force escalation or confidence downgrade, not just a warning.

**PPLX-1.1: Orchestration artifact lifecycle / garbage collection** — SIGNIFICANT, unique genuine insight
The blackboard pattern does double duty as long-term knowledge store AND short-lived orchestration scratchpad, but only the durable side is designed. No lifecycle or retention policy for dispatch state files, briefs, partial outputs, scratch notes in `_openclaw/state`. These accumulate and slow grep-based debugging. Fix: define durable vs. ephemeral split with retention policy (archive ephemeral state > N days; compact into monthly summary logs).

**PPLX-1.3: Intra-vault conflict resolution / source precedence** — SIGNIFICANT, unique genuine insight
§11.4 handles contradictions in external information, but not when a worker writes conclusions that conflict with existing vault knowledge. Workflow 3 prefers vault facts over external research, but no general source precedence rule exists. Fix: add source precedence (e.g., `_system/` specs > account dossiers > recent research > older research) tied to Tess's conflict-resolution schema.

**PPLX-3.1: Compound insight acceptance criteria don't require utility** — SIGNIFICANT, genuine
Max 5/day can be met while still spamming low-value insights — acceptance criteria are structural (frontmatter, wikilinks, vault-check) but not utility-based. Fix: add minimum utility threshold from feedback; if insights from a given pattern receive >X% "not useful" over gate period, Tess disables that pattern.

**PPLX-3.2: "Tess-identified research need" trigger is open-ended** — CRITICAL, genuine
No guardrail on Tess-initiated research beyond cost-aware routing (which arrives later). Can drive up cost and generate vault noise in Phase 1b before cost controls exist. Fix: constrain to briefs used by existing active workflows or explicit "investigate" flags; add daily cap.

**PPLX-3.3: Workflow 3 timing guarantees are aspirational** — CRITICAL, genuine extension of EXT-F8
Even with sequential dispatch acknowledged, the spec doesn't model expected wall-clock runtime or account for backlog from other workflows. "Delivered >= 20 min before meeting" isn't enforceable without runtime statistics. Fix: Tess computes expected completion time from learning log averages; precondition check: sufficient time slack, otherwise escalate with "too late to fully prep."

**PPLX-6.1: Worker crash mid-dispatch — orchestration semantics missing** — SIGNIFICANT, genuine
CTB-016 handles crash recovery at transport level, but the spec doesn't define what Tess does: re-dispatch once (same correlation_id)? Escalate? Log crash as distinct outcome in learning log? Without this, orphaned dispatches or duplicate work.

**PPLX-6.2: Re-dispatch strategy after quality gate failure** — SIGNIFICANT, genuine
Spec says max 2 re-dispatches but doesn't specify: same brief? Modified brief? Partial output reuse? Sending the same brief repeatedly after the same error causes repeated failures. Fix: first failure → Tess refines brief using learning log; second failure → try alternative skill or escalate.

### Contradictions

**1. Workflow ordering direction**
OAI-F4 suggests W2 before W1 (feed scoring unstable, research has clearer success criteria). GRK-S2 suggests demoting W2 *further* to Phase 2 (too much new infra). Gemini, DeepSeek, and EXT endorse current ordering.
**Assessment:** Current ordering is sound — W1 builds operational habits with daily cadence; W2's infra dependencies are Phase 1b prerequisites that gate it properly. EXT confirms the ordering is correct and Workflow 1 is "the right starting point."

**2. A2A-023/024 merge vs. split**
DS-F8 suggests merging A2A-023 and A2A-024 (tightly coupled, small). OAI-F1 suggests *splitting* A2A-024 further (separate manifests for existing vs. new skills).
**Assessment:** Keep separate — schema definition vs. multi-skill rollout are distinct concerns. OAI's split suggestion has merit (manifests for critic can't be written until critic exists) but can be handled by scoping A2A-024's acceptance criteria to existing skills only.

**3. Haiku default for orchestration**
EXT-F1 argues Haiku may be insufficient for Workflow 1 judgment calls and recommends A/B testing. The formal spec (§13) defers the question to gate evaluation with Haiku as default.
**Assessment:** EXT's concern is well-grounded — the bootstrapping problem (garbage gate data from garbage quality) is real. A/B comparison as first gate activity is the right fix.

### Action Items

**Must-fix (blocking stability):**

- **A1** — Fix Phase 1b dependency ordering: renumber sequentially, ensure A2A-023 → 024 → 025 → 009. Scope A2A-024 to existing skills only (researcher, feed-pipeline); defer critic manifest to A2A-011.
  Source: OAI-F1, DS-F1, GRK-C1, GRK-S5

- **A2** — Add HITL mechanical enforcement subsection to §9: define tool guardrails, filesystem path allowlists, dispatch budget threshold for Tier 2, approval token TTL/idempotency.
  Source: OAI-F2, GRK-C2, GRK-S3

- **A3** — Add concrete capability manifest schema to §8.6: YAML example (researcher-skill), ID namespace convention (`domain.purpose.variant`), deterministic selection algorithm with tiebreaker, manifest version field. Include rigor dimension: `supported_rigor: [quick, standard, deep]` in manifests, `rigor:` in briefs. Filter by rigor compatibility *before* cost/learning-log selection. No-synonym rule for capability IDs.
  Source: OAI-F6, GEM-F2, DS-F3, GRK-S4, EXT-F11, PPLX-4.2, PPLX-4.3

- **A4** — Reframe §8.5 multi-dispatch as sequential-with-shared-context: Claude Code is single-threaded. Demote from generic infra prerequisite to Workflow-3-specific orchestration pattern. Implement W3 with simple two-step sequential dispatch + synthesis; remove A2A-013 as hard W3 prerequisite. Reintroduce CTB-016 amendments only if Research Council or cascading chains prove needed.
  Source: EXT-F8, PPLX-1.2, PPLX-2.1, PPLX-5.1

- **A5** — Verify CTB-016 "rule 12" single-dispatch constraint exists as described: audit actual lockfile semantics before designing dispatch groups. If the constraint is session-level (not protocol-level), §8.5 design premise changes.
  Source: EXT-F3

**Should-fix (significant but not blocking):**

- **A6** — Define channel-neutral artifact model for `present` intent: vault artifact first, adapters own truncation/formatting. No workflow branches on channel capabilities.
  Source: OAI-F5, GEM-F3, DS-F4, GRK-S6

- **A7** — Add feedback cold-start / seeding mechanism + generalize "What was missing?" prompt from Workflow 3 to all workflows. Define mechanical rule: learning log entry created only when dispatch completes AND feedback exists (or timeout window passes as "no-feedback" outcome). Distinguish "no-feedback yet" vs "no-feedback after window."
  Source: GEM-F5, GRK-C3, EXT-F2, PPLX-2.3

- **A8** — Add auto-resolution failure catch-all to §9.2: if Tess cannot execute auto-resolution, treat as Conflict escalation to Danny with error details.
  Source: DS-F2

- **A9** — Break A2A-012 (Mission Control Phase 1) into 2-3 sub-tasks, or reduce scope to minimal static site for read phase. Consider delaying until after vault gardening + dispatch retrospective have run to avoid rework. Defer dashboards until data stores are stable.
  Source: GEM-F1, OAI-F16, DS-F9, GRK-S7, PPLX-5.2

- **A10** — Extend multi-channel approval with TTL, idempotency key, replay protection, primary channel designation. Any one configured channel sufficient to proceed; others best-effort.
  Source: OAI-F9, DS-F6, PPLX-6.3

- **A11** — Define canonical dispatch/delivery envelope schema carrying correlation_id, dispatch_id, workflow, intent, timestamps, artifact_paths, cost, model.
  Source: OAI-F3

- **A12** — Specify quality review check computation sources per §11.1: who/what produces each check, algorithm, cost implications. Validate researcher-skill RS-008 output format against gate expectations.
  Source: OAI-F7, EXT-F6

- **A13** — Replace Workflow 1 score-based threshold language with tier-based selection criteria matching FIF's actual T1/T2/T3 output (e.g., "all T1 items + T2 items matching active project tags").
  Source: EXT-F5

- **A14** — Add Haiku vs Sonnet A/B comparison (5 items each) as first Workflow 1 gate activity rather than defaulting to Haiku and measuring quality after the fact.
  Source: EXT-F1

- **A15** — Add confidence calibration mechanism for escalation override §9.2: start with N-entries heuristic, calibrate during gate.
  Source: EXT-F4

- **A16** — Add tiered context staleness model: "soft stale" (>24h, warn) vs "hard stale" (>N days, workflows disallowed). For time-sensitive workflows (Workflow 3), stale context forces lightweight refresh or escalation, not just a warning.
  Source: EXT-F9, PPLX-2.2

- **A17** — Add realistic calendar timeline alongside session-effort estimates for Phase 3. Dependency chain through tess-operations milestones suggests Q3 2026 at earliest.
  Source: EXT-F13

- **A18** — Define orchestration artifact lifecycle: strict durable vs. ephemeral split. Add retention policy for `_openclaw/state` dispatch files, briefs, scratch notes (archive > N days; compact into monthly summary logs).
  Source: PPLX-1.1

- **A19** — Add intra-vault source precedence rule for conflict resolution: `_system/` specs > account dossiers > recent research > older research. Generalize beyond Workflow 3's vault-over-external preference.
  Source: PPLX-1.3

- **A20** — Add minimum utility threshold for compound insights based on feedback: if insights from a given pattern receive >X% "not useful" over gate period, Tess disables that pattern. Acceptance criteria should require utility, not just structural correctness.
  Source: PPLX-3.1

- **A21** — Constrain "Tess-identified research need" trigger: only for briefs used by existing active workflows or explicit "investigate" flags. Add daily cap for Tess-initiated research.
  Source: PPLX-3.2

- **A22** — Integrate runtime statistics into Workflow 3 scheduling: Tess computes expected completion time from learning log averages. Precondition: sufficient time slack; otherwise escalate with "too late to fully prep."
  Source: PPLX-3.3

- **A23** — Define orchestration-level crash policy: re-dispatch once (same correlation_id) or escalate depending on workflow/risk tier. Log crash as distinct outcome in learning log. Define re-dispatch strategy after quality gate failure: first failure → refine brief; second → try alternative skill or escalate.
  Source: PPLX-6.1, PPLX-6.2

**Defer (minor or speculative):**

- **A24** — Add glossary / terminology standardization (dispatch_id vs correlation_id vs group_id). Resolve during PLAN.
  Source: OAI-F11, GEM-F6

- **A25** — Define gate measurement formulas (utility rate, false positive rate, minimum sample size). Define at gate time.
  Source: OAI-F12

- **A26** — Add artifact index for Mission Control querying. Phase 2 PLAN concern.
  Source: OAI-F8

- **A27** — Define account dossier MVP data requirements + fallback behavior. Phase 2 PLAN.
  Source: OAI-F10

- **A28** — Add per-assumption validation metrics table (metric, owner, gate). Nice-to-have for traceability.
  Source: GRK-M1

- **A29** — Specify confidence generation logic for compound insights (Crumb sets, Tess overrides post-gate).
  Source: GRK-M5

- **A30** — Add dispatch learning log pruning policy (archive entries > 90 days).
  Source: EXT-F10

- **A31** — Track quality_signals versioning as "revisit if this breaks" item.
  Source: EXT-F12

- **A32** — Add wikilink-variant count to vault-check as mechanical trigger for entity resolution.
  Source: EXT-F7

- **A33** — Tighten Workflow 4 Tier 1 auto-fix definition: only purely additive operations (adding backlinks) or proven non-destructive via tests (reformatting frontmatter). Moves/deletes → Tier 2+.
  Source: PPLX-3.4

- **A34** — Constrain Phase 1b capability dispatch to exactly one capability (`external-research`) + one concrete alternative before adding complexity. Defer unused manifest fields until two consumers need them.
  Source: PPLX-4.1

### Considered and Declined

- **GEM-F4** (dual orchestration patterns from start): Workflow 1's direct dispatch is a deliberate exception — the substitution test explicitly says "no plausible substitute" for template-write. Two patterns is acceptable when one is trivial. Reason: `constraint`

- **GRK-S2** (demote Workflow 2 to Phase 2): W2's infrastructure dependencies are Phase 1b prerequisites that gate it properly. The skill being ready is a genuine unlock — the infra is being built for W2 anyway. Reason: `incorrect`

- **DS-F8** (merge A2A-023/024): Schema definition vs. multi-skill manifest rollout are distinct concerns. Keeping separate allows validating the schema before rolling it out to multiple skills. Reason: `overkill`

- **OAI-F4** (swap W1/W2 ordering): Feed-intel M2 at 9/11 is near completion (actually M3 done per EXT validation). W1's daily cadence builds operational habits and feedback loops more effectively than on-demand W2 triggers. Reason: `constraint`

- **GRK-S8** (prototype multi-dispatch in Phase 1): Multi-dispatch is explicitly deferred to after single-dispatch is proven. Premature prototyping adds scope without validated need. Reason: `overkill`

- **GRK-M4** (Mission Control Phase 1 without auth): Cloudflare Access is trivial to set up (email OTP) and is a security requirement, not scope creep. Reason: `incorrect`

- **EXT process note** (input spec frontmatter type should be `research` not `specification`): Valid hygiene observation. However, the input spec already lives in `design/` (not at project root), and the run-log explicitly notes its role as research material. The `type: specification` frontmatter is misleading but low-risk since vault-check doesn't enforce uniqueness on type within a project. Reason: `overkill` — fix if it causes confusion, don't prioritize now.
