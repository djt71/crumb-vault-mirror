---
type: design
domain: career
project: post-call-pipeline
skill_origin: systems-analyst
review_round: 1
created: 2026-03-08
updated: 2026-03-08
tags:
  - automation
  - se-workflow
  - gong
  - customer-intelligence
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Post-Call Pipeline — Specification

## 1. Problem Statement

After every customer call, the SE must: review the transcript, extract what was discussed, identify next steps, update account documentation, draft a client-facing follow-up, and create tasks for committed actions. This process takes 20-30 minutes per call and is largely manual despite being structurally repetitive. The cognitive load isn't in the extraction itself — it's in the context-switching between tools (Gong, email, vault, calendar, task manager) and the risk that follow-ups slip through cracks when the SE is back-to-back on calls.

Gong already provides an AI-generated summary emailed after each call, including next steps and a link to the full transcript. This summary is adequate for ~80% of calls but insufficient for complex, multi-stakeholder, or technically dense conversations. The pipeline should use the Gong summary as the default input and escalate to full transcript extraction when needed.

The pipeline produces three outputs: an internal vault note (structured call summary that updates the customer dossier context), a client-facing follow-up artifact (format varies by client context), and actionable tasks with owners and dates. Delivery is via Telegram for operator review before any client-facing output is sent.

**Project identity:** This is a standalone project (`post-call-pipeline`) with `related_projects: [tess-operations, customer-intelligence]`. The pipeline is career-domain SE workflow that consumes Tess infrastructure — it doesn't build Tess infrastructure. Tess-operations provides the platform (email access, Telegram delivery, bridge dispatch). Customer-intelligence provides the account context (dossiers, dossier conventions, account structure).

## 2. Facts vs Assumptions

### Facts

- **F1:** Gong emails arrive with two useful components: an AI-generated summary in the email body (participants, topics, next steps) and a link to the full call on the Gong platform with transcript download available.
- **F2:** The dispatch protocol (CTB-016) is complete and available for pipeline lifecycle management.
- **F3:** The Excalidraw skill exists and can produce visual diagrams for system/architecture contexts. Its effectiveness for call flow visualizations is unvalidated (see A-5).
- **F4:** Customer dossiers exist in the vault at `Projects/customer-intelligence/dossiers/`. Dossier structure and depth vary by account maturity. Currently 3 of ~25 target accounts are populated.
- **F5:** The inbox-processor pattern is established and archived — its intake conventions are available as prior art.
- **F6:** Tess monitors Telegram and can deliver artifacts for review. The bridge supports structured escalation (blocked → relay → resume).
- **F7:** The researcher-skill pipeline (stage-separated, handoff-driven, vault-as-output) is complete and provides a proven architectural pattern for multi-stage skills.
- **F8:** Dispatch-tier classification ([[dispatch-tier-classification]]) provides the framework for determining operator involvement level. Gong call transcripts default to Yellow (operator review before client send).

### Assumptions

- **A-1:** Gong's email summary is sufficient input for 80% of calls. Full transcript extraction is needed only for complex/contentious/technically-dense calls. *Validate:* Track Tier 2 escalation rate over first 20 calls. If >40%, the Gong summary is less adequate than assumed.
- **A-2:** Email access for Gong transcript intake can be implemented via a narrow adapter (Gong-specific email watcher) without requiring full email triage infrastructure. *Validate:* Confirm Gong email format is stable and parseable. Confirm email API access path (Gmail API, IMAP, or forwarding rule to a monitored path).
- **A-3:** Customer dossiers have sufficient context for the pipeline to produce meaningful cross-referenced call notes. *Validate:* Test against 3 accounts with varying dossier depth. If thin dossiers produce generic output, the pipeline needs a graceful degradation path.
- **A-4:** Client-facing follow-up format preferences can be inferred from vault context (client role, account stage, communication history) with operator override. *Validate:* Track override rate over first 20 calls. If >50%, the inference logic needs rework. This is a gate evaluation instance (see [[gate-evaluation-pattern]]).
- **A-5:** Excalidraw can produce client-send-ready call flow visualizations. *Validate:* Test with 2-3 real call extractions before committing Excalidraw as a format option. If output quality requires heavy manual editing, fall back to styled markdown summary — don't ship a format option that defeats the pipeline's purpose.

### Unknowns

- **U-1:** Email integration path — Gmail API via MCP, IMAP polling, or a forwarding rule that dumps Gong emails to a monitored filesystem path. Each has different auth/complexity tradeoffs. The forwarding-rule path (option 1) may bypass the Gmail OAuth dependency on tess-operations M2 — test this path first.
- **U-2:** Gong transcript download mechanism — whether the link in the email supports programmatic download (API, direct URL) or requires browser-based interaction. If programmatic download isn't available, Tier 2 requires manual transcript paste — functional but not fully automated.
- **U-3:** Optimal Excalidraw diagram structure for post-call summaries — pending A-5 validation.
- **U-4:** Task destination — vault project files, Todoist, or another task surface. Determines the output adapter needed for Stage 5.

## 3. System Map

### 3.1 Pipeline Architecture

The post-call pipeline operates as a stage-separated skill consuming the dispatch protocol (CTB-016). Each stage is a single `claude --print` invocation. The pipeline has two tiers: Tier 1 (fast, Gong summary as input) and Tier 2 (deep, full transcript as input). Tier 1 is the default. Tier 2 triggers on explicit operator request or automatic detection (see §3.2).

#### Stage Definitions

| Stage | Purpose | Input | Output |
|-------|---------|-------|--------|
| **Intake** | Detect Gong email, parse AI summary from body, extract call metadata, extract Gong link | Gong email (body + headers) | Structured call record: participants, date, duration, account, summary text, next steps text, Gong link |
| **Extraction** | Parse summary into structured data: topics discussed, decisions made, requirements surfaced, objections/concerns, committed next steps (who/what/when), open questions | Intake output, call record | Structured extraction with typed fields per category |
| **Vault Contextualization** | Pull customer dossier from `Projects/customer-intelligence/dossiers/`, cross-reference extraction against prior call notes and account state, flag deltas (new stakeholders, changed requirements, timeline shifts, contradictions with prior commitments) | Extraction output, vault customer dossier, prior call notes | Contextualized extraction with delta annotations, account-aware enrichment |
| **Artifact Generation** | Produce two artifacts: (a) internal vault note (structured call summary for dossier context), (b) client-facing follow-up in context-appropriate format with format recommendation and rationale | Contextualized extraction, client communication preferences (from dossier or operator override) | Vault note (markdown, YAML frontmatter), client follow-up artifact (email draft + optional visual) |
| **Task + Delivery** | Generate actionable tasks from committed next steps (owner, due date, context), classify each task by dispatch tier, package all outputs, deliver via Telegram for operator review | Artifact output, committed next steps with owners/dates | Task list (with dispatch tiers), packaged delivery (vault note, client artifact, tasks), Telegram notification |

#### Stage Flow

```
Intake ──▶ Extraction ──▶ Vault Contextualization ──▶ Artifact Generation ──▶ Task + Delivery
                                                            │
                                                            ▼
                                                        [escalation]
                                                     (format_confirm:
                                                      "Client X prefers
                                                      visual summaries.
                                                      Send diagram + email,
                                                      or email only?")
```

### 3.2 Tier 2 Trigger Criteria

Tier 2 (full transcript extraction) activates when any of the following are true:

- Operator explicitly requests it ("go deeper on this one")
- Call duration exceeds 45 minutes
- Participant count exceeds 4
- Gong summary contains keywords indicating complexity: "POC", "migration", "security review", "RFP", "proof of concept", "architecture review", "escalation"
- Account is flagged as high-priority in the dossier (`health: red` or `tier: strategic`)

When Tier 2 triggers, the pipeline pauses after Intake and attempts to retrieve the full transcript via the Gong link. If retrieval fails (U-2 unresolved), the pipeline escalates to the operator — who can paste the transcript manually — and falls back to Tier 1 if no transcript is provided.

### 3.3 Client-Facing Format Selection

The Artifact Generation stage selects follow-up format based on vault context. Format recommendation is presented to operator for confirmation via bridge escalation (first 20 calls minimum, relaxable after override rate stabilizes below 20%).

This is an instance of the gate evaluation pattern ([[gate-evaluation-pattern]]): define criteria (override rate <20%) → run autonomous period (20 dispatches) → evaluate → gate decision (go autonomous or keep confirming).

**Note:** The "first 20 calls" format learning gate runs independently from the A-1 Tier 2 escalation rate gate (also measured over 20 calls). They are separate gate evaluations running in parallel — the same calls feed both measurements, but the gates evaluate different questions.

#### Format Decision Logic

| Signal | Recommended Format |
|--------|-------------------|
| Technical stakeholder (from dossier role field) | Structured email: action items with owners, technical details, timeline |
| Executive / business stakeholder | Visual summary (Excalidraw if A-5 validated, else styled markdown) + brief email |
| New prospect, early discovery stage | Both: visual demonstrates rigor, email provides actionable reference |
| Existing account, active implementation | Focused email: blockers, dependencies, timeline updates, no visual |
| Dossier has no role/preference data | Default to structured email, ask operator to update dossier |

#### Operator Override Loop

For the first 20 dispatches, format recommendation is always surfaced as an escalation. Operator confirms or overrides. Overrides are logged. After 20 dispatches, if override rate <20%, format selection becomes autonomous with Telegram notification (no escalation pause). Operator can always force an override by replying to the notification.

**Dispatch-tier integration:** Format confirmation is governed by dispatch-tier classification. Yellow-classified calls get the escalation. If a call is ever classified Green (routine call with well-documented account), format selection is autonomous — no escalation pause.

### 3.4 Vault Output Conventions

Internal call notes are colocated with customer dossiers, not under `Sources/`. Call notes are account intelligence — they're only meaningful in the context of the account they reference.

**Path:** `Projects/customer-intelligence/calls/[account-slug]-[YYYY-MM-DD]-[brief-topic].md`

**Frontmatter:**

```yaml
---
type: call-note
project: customer-intelligence
domain: career
schema_version: 1
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
account: "[account name]"
date: YYYY-MM-DD
participants:
  - name: "[name]"
    role: "[role]"
    org: "[org]"
gong_link: "[url]"
tier: 1|2
tags:
  - call-note
  - customer-intelligence
---
```

**Convention registration required:** `type: call-note` is a new frontmatter type. Must be registered in `_system/docs/file-conventions.md` and vault-check updated to validate it before implementation begins.

vault-check must pass on all generated files. Call notes link back to the customer dossier via wikilink (`[[account-slug]]`). If no dossier exists for the account, the pipeline creates a stub from `Projects/customer-intelligence/dossier-template.md` and flags it for operator enrichment.

### 3.5 Task Output Format

Tasks generated from committed next steps use the following structure:

```yaml
- action: "[what needs to happen]"
  owner: "[who — Danny, client name, or specific person]"
  due: "YYYY-MM-DD"
  context: "[why — reference to discussion point]"
  source_call: "[link to call note]"
  priority: "[high/medium/low — inferred from urgency signals in discussion]"
  dispatch_tier: "[green/yellow/red — per dispatch-tier classification]"
```

**Date normalization:** Relative dates from call discussion ("next week", "before next call") are resolved to absolute `YYYY-MM-DD` dates at generation time using the call date as reference. The pipeline does not pass relative dates to the consumer.

**Dispatch-tier integration:** Each task is tagged with a dispatch tier at generation time. A committed next step involving pricing or a financial commitment is Red. A routine follow-up email to a known contact may be Green. The tier tag surfaces in the Telegram delivery so the operator sees which tasks need their judgment.

Task destination (U-4) is deferred to implementation. Initial version writes tasks to the Telegram delivery message. Task manager integration (Todoist, vault project files) is a future enhancement.

### 3.6 Delivery Package

The Telegram delivery to operator includes:

1. One-line call summary (account, date, key outcome)
2. Internal vault note (ready to commit, or committed if auto-commit enabled)
3. Client-facing artifact draft (email text + visual if applicable)
4. Task list with owners, dates, and dispatch tiers
5. Format recommendation rationale (during first 20 dispatches)
6. Action prompt: "Review and approve send / Edit / Skip follow-up"

Operator approval is required before any client-facing output is sent. The pipeline never sends email autonomously. This aligns with dispatch-tier classification: client-facing output is always Yellow minimum.

## 4. Dependencies

| Dependency | Status | Required By |
|------------|--------|-------------|
| Dispatch protocol (CTB-016) | Complete | All stages (lifecycle management) |
| Excalidraw skill | Complete (system diagrams); **unvalidated for call flows (A-5)** | Artifact Generation (visual format) |
| Gong email access | **Not started** (U-1) | Intake stage |
| Customer dossiers in vault | Partial (3 of ~25 accounts populated) | Vault Contextualization |
| Customer-intelligence project conventions | Active (dossier schema, file structure, dossier-template.md) | Vault Output (call note placement, dossier stub creation) |
| Tess Telegram delivery | Complete | Task + Delivery stage |
| vault-check | Complete; **needs `call-note` type registration** | Vault Output validation |
| Dispatch-tier classification | Design complete ([[dispatch-tier-classification]]); implementation pending | Task tier tagging, format escalation logic |
| Gmail OAuth (tess-operations M2) | **Not started** (TOP-015–018) | Intake — **only if forwarding-rule path (U-1 option 1) doesn't work** |

### Critical Path Dependency: Gong Email Access (U-1)

The entire pipeline depends on programmatic access to Gong notification emails. Three candidate paths, in order of preference:

1. **Forwarding rule** — Gmail filter forwards Gong emails to a monitored filesystem path (e.g., `_openclaw/gong-inbox/`). Lowest complexity. Requires Gmail filter setup only. **Test this path first** — if it works without OAuth, the pipeline bypasses the tess-operations M2 dependency entirely.
2. **Gmail API via MCP** — Direct API access to read Gong emails. Medium complexity. Requires OAuth setup (tess-operations M2 dependency: TOP-015–018).
3. **IMAP polling** — Tess polls Gmail via IMAP for Gong sender. Medium complexity. Requires app password or OAuth.

Resolution of U-1 is the first milestone. The pipeline cannot proceed to implementation without a working intake path.

## 5. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Gong email format changes without notice | **Medium** | High (breaks Intake parser) | Version the parser, include format validation at Intake, alert on parse failure. Parser maintenance is an ongoing cost, not a one-time build. |
| Gong summary quality varies significantly by call type | Medium | Medium (Tier 1 output quality degrades) | Tier 2 trigger criteria catch the worst cases; operator can always request Tier 2 |
| Thin customer dossiers produce generic contextualization | Medium | Medium (output isn't differentiated from raw Gong summary) | Graceful degradation: skip contextualization delta annotations when dossier is thin, flag dossier for enrichment |
| Client-facing format inference is wrong frequently | Medium | Low (operator catches it in review) | First 20 calls require confirmation; log overrides; adjust decision logic (gate evaluation) |
| Full transcript retrieval (Tier 2) not programmatically accessible | Medium | Medium (Tier 2 unavailable) | Tier 2 is an enhancement, not a requirement. Tier 1 pipeline works without it. Operator can manually paste transcript. |
| Excalidraw call flow quality insufficient for client delivery | Medium | Low (fall back to styled markdown) | Validate with 2-3 test cases (A-5) before committing as format option |
| Gmail OAuth dependency blocks pipeline start | Medium | High (entire pipeline blocked) | Test forwarding-rule path first to bypass dependency |

## 6. Scope Boundaries

### In Scope

- Gong email detection and summary parsing
- Structured extraction of call content into typed fields
- Cross-referencing with vault customer dossiers (Projects/customer-intelligence/)
- Internal vault call note generation (vault-check compliant, colocated with dossiers)
- Client-facing follow-up artifact generation (email draft + optional visual)
- Task generation from committed next steps with dispatch-tier tags
- Telegram delivery with operator approval gate
- Format recommendation with learning from operator overrides (gate evaluation pattern)

### Out of Scope (Deferred)

- Full email triage pipeline (broader than Gong; separate project)
- Email sending automation (operator always reviews and sends manually)
- Todoist / task manager integration (tasks delivered in Telegram initially)
- Gong API direct integration (using email as the intake surface for V1)
- Calendar event creation for follow-up meetings (manual for V1)
- Multi-language support (English only for V1)
- Batch processing of historical calls (pipeline is per-call, triggered by new Gong email)

## 7. Build Sequence

### Phase 0: Intake Path Resolution

Resolve U-1 (Gong email access). Test the forwarding-rule path first — if a Gmail filter can dump Gong emails to a monitored filesystem path without OAuth, skip the tess-operations M2 dependency. If forwarding doesn't work, test Gmail API and IMAP paths. Select and implement.

Register `type: call-note` in file-conventions.md and vault-check before proceeding.

### Milestone 1: Intake + Extraction

Build the Gong email parser and the structured extraction stage. Validate against 5 real Gong emails across different call types (discovery, technical deep-dive, executive briefing, implementation check-in, multi-stakeholder). Acceptance: extraction produces correctly typed fields for all 5 test cases.

### Milestone 2: Vault Contextualization

Build the dossier cross-reference stage. Test against 3 accounts with varying dossier depth (Steelcase = rich, others as available). Acceptance: rich dossier produces meaningful delta annotations; thin dossier degrades gracefully without hallucinating context.

### Milestone 3: Artifact Generation

Build the internal vault note generator and client-facing follow-up generator. Implement format recommendation logic.

**Excalidraw validation gate (A-5):** Before integrating the Excalidraw skill, test with 2-3 real call extractions. If output quality is client-send-ready, integrate. If not, use styled markdown summary as the visual format. This gate must pass before Excalidraw is committed as a format option.

Acceptance: vault notes pass vault-check; client-facing artifacts are review-ready (operator would send with minor or no edits).

### Milestone 4: Task Generation + Delivery

Build the task extraction (with date normalization and dispatch-tier tagging) and Telegram delivery package. Implement operator approval flow via bridge. Acceptance: end-to-end pipeline runs from Gong email to Telegram delivery with all components (summary, vault note, client artifact, tasks with tiers, action prompt).

### Milestone 5 (Deferred): Tier 2 Deep Extraction

Resolve U-2 (Gong transcript download). Build full-transcript extraction stage. Wire Tier 2 trigger criteria. If programmatic download isn't available, implement manual paste workflow. Acceptance: Tier 2 produces richer extraction than Tier 1 for complex calls, validated on 3 test cases.

### Milestone 6 (Deferred): Email Adapter Generalization

Extract the Gong email watcher into a general email adapter pattern. Extend to full inbox triage. This becomes the foundation for the broader email/comms triage pipeline.

## 8. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Per-call processing time (operator involvement) | <5 minutes (from notification to approved send) | Timestamp delta: Telegram delivery → operator text acknowledgment |
| Follow-up format override rate | <20% after 20 calls (gate evaluation) | Override count / total dispatches |
| Vault note quality | vault-check pass rate 100%; operator edit rate <30% | vault-check results; operator edits before commit |
| Task capture completeness | >90% of committed next steps captured | Operator adds <1 task per call on average |
| Pipeline reliability | <5% failure rate on Intake parsing | Parse failures / total Gong emails processed |
| Tier 2 escalation rate | <40% of calls need full transcript (A-1 validation) | Tier 2 triggers / total calls |

## 9. Prior Art

- **Researcher-skill pipeline:** Stage-separated architecture, handoff-driven, vault-as-output. Direct architectural ancestor.
- **FIF adapter pattern:** Source-specific adapters with shared pipeline infrastructure. The Gong email watcher follows this pattern.
- **Inbox-processor (archived):** Intake conventions for processing raw inputs into structured vault artifacts.
- **Ashe's post-meeting workflow:** Transcript → visual diagram → client email. Same concept, lighter implementation.
- **Prosser's chief-of-staff system:** Email triage → task creation → subagent dispatch. Broader scope, overlapping pattern on the email→task conversion.
- **Dispatch-tier classification ([[dispatch-tier-classification]]):** The framework governing operator involvement in pipeline outputs. The pipeline is a consumer of the classification framework.
- **Gate evaluation pattern ([[gate-evaluation-pattern]]):** The format override learning loop and Tier 2 validation threshold are both instances of this pattern.
