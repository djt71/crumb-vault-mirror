---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/attention-manager/design/specification.md
artifact_type: spec
artifact_hash: 58fe9acf
prompt_hash: dcc016bc
base_ref: null
project: attention-manager
domain: software
skill_origin: peer-review
created: 2026-03-06
updated: 2026-03-06
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
  - claude/claude.ai (manual)
  - perplexity/perplexity (manual)
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 54591
    attempts: 1
    raw_json: Projects/attention-manager/reviews/raw/2026-03-06-specification-openai.json
  google:
    http_status: 200
    latency_ms: 35347
    attempts: 1
    raw_json: Projects/attention-manager/reviews/raw/2026-03-06-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 106467
    attempts: 1
    raw_json: Projects/attention-manager/reviews/raw/2026-03-06-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 36256
    attempts: 1
    raw_json: Projects/attention-manager/reviews/raw/2026-03-06-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Attention Manager Specification

**Artifact:** Projects/attention-manager/design/specification.md
**Mode:** full
**Reviewed:** 2026-03-06
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Full specification review -- correctness, completeness, consistency, feasibility, clarity. Severity-classified findings with unverifiable claim flagging.

---

## OpenAI (gpt-5.2)

## Structured Review — Attention Manager Specification

### Correctness

- **[F1]**
  - **Severity:** CRITICAL
  - **Finding:** Carry-forward mechanics depend on checkboxes/`[done]` markers, but the Focus item template is *not* defined as a task/checkbox list (it uses `### 1. ...` headings, not `- [ ]` items).
  - **Why:** If the operator follows the template as written, there’s nothing to “check off,” so carry-forward will mis-detect completion and roll items forever (or rely on brittle text heuristics).
  - **Fix:** Standardize Focus items as tasks, e.g.:
    - `- [ ] Item description` with sub-bullets for Why/Domain/Source, or
    - keep headings but require a status token in a consistent field (e.g., `Status: open|done`), and define exact parsing rules.

- **[F2]**
  - **Severity:** CRITICAL
  - **Finding:** Monthly review artifact is specified to use **type `daily-attention`**, despite being a different artifact class (“same type, different scope”).
  - **Why:** This breaks type semantics and validation. Any UI, analytics, vault-check rules, or carry-forward logic may treat the monthly review like a daily plan, causing confusion and mis-parsing.
  - **Fix:** Introduce a distinct type, e.g. `monthly-attention-review` (or `attention-review` with `period: month`). Update taxonomy + vault-check accordingly.

- **[F3]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The skill contract says “Budget: Standard tier (5 docs) for daily curation,” but the daily procedure includes scanning *all* `Projects/*/project-state.yaml` plus possibly dossiers—potentially far more than 5 documents.
  - **Why:** This is an internal inconsistency and a feasibility risk: the skill may exceed context budgets or become slow/expensive, undermining the ceremony budget principle.
  - **Fix:** Define a bounded project scan strategy:
    - only load projects marked `status: active` and/or recently touched,
    - maintain an index file listing “active projects,”
    - cap to N projects and log when truncation occurs.

- **[F4]**
  - **Severity:** SIGNIFICANT
  - **Finding:** “Graceful degradation” is specified, but there’s no explicit precedence/behavior when sources conflict (e.g., project next_action says one thing, operator edits daily artifact to another; SE inventory says pending, but operator defers repeatedly).
  - **Why:** Without conflict-resolution rules, the system can oscillate or repeatedly re-suggest things the operator intentionally deprioritized—creating annoyance and abandonment risk.
  - **Fix:** Add explicit suppression/override mechanisms:
    - allow operator to mark an item as `snoozed until YYYY-MM-DD` or `dropped`,
    - define that “Deferred” section entries suppress resurfacing for X days unless deadline approaches.

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec says operator edits are authoritative and “must not break carry-forward mechanics,” but doesn’t define what structure the skill requires to remain parseable after edits.
  - **Why:** The “human override” constraint conflicts with fragile parsing. Real edits will drift format quickly.
  - **Fix:** Define a minimal “stable core” the parser relies on (e.g., Focus must be a markdown task list; each line contains optional tags like `Domain:`). Add a vault-check (lint) that warns (not blocks) if format drifts.

---

### Completeness

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** No explicit data model for “Domain” values (enumeration) across artifacts (goals, SE inventory items, project next actions, daily list).
  - **Why:** Domain balance logic (“work >60% for 3+ consecutive days”) requires a consistent domain taxonomy and a definition of what counts as “work”.
  - **Fix:** Add a canonical domain list in one place (e.g., `_system/docs/domain-taxonomy.md`) and specify mapping rules:
    - “work” = `{career, software}` (or whatever is intended)
    - how to treat ambiguous items (default domain, or require domain tag).

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The 5–8 items list is defined, but there’s no stated rule for *time feasibility* (e.g., one item could be a 6-hour deep work block; another could be 5 minutes).
  - **Why:** A “curated list” can still be unrealistic, causing repeated carry-forward and learned helplessness.
  - **Fix:** Add lightweight sizing:
    - either a rough estimate field (S/M/L or minutes),
    - or a daily “capacity” assumption (e.g., 2 deep-work blocks + 3 small tasks) and enforce it in curation.

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Customer dossiers are assumed to have “machine-readable action items,” but no interim approach is defined if they don’t.
  - **Why:** This is a key input stream (25 accounts). If it’s not ready, curation may underweight customer engagement or become manual.
  - **Fix:** Define a minimal fallback extraction method:
    - e.g., “If dossier lacks structured action items, extract from a `## Next Actions` section using bullet parsing; otherwise ignore dossier.”

- **[F9]**
  - **Severity:** MINOR
  - **Finding:** Retention policy says “pruned (not archived)” after 90 days, but monthly review depends on reading daily artifacts for that month; also future longitudinal analysis is implicitly valuable.
  - **Why:** Pruning may delete useful behavioral history; “monthly review captures durable signal” may not be sufficient if you later want quarterlies.
  - **Fix:** Consider: retain 12 months, or archive beyond 90 days to `_archive/daily-attention/` with compression, or keep only metadata summaries.

---

### Internal Consistency

- **[F10]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Goal tracker is YAML-only to reduce ceremony, but SE inventory uses markdown with inline cadence annotations “parseable via lightweight regex.” This introduces hidden complexity and fragility compared to YAML.
  - **Why:** Regex parsing of freeform cadence text is likely to break and will increase maintenance cost (violating ceremony budget).
  - **Fix:** Either:
    - move cadence into a small structured block per item (still in markdown, but consistent), or
    - provide a strict cadence annotation grammar (e.g., `cadence: weekly; due: Friday;`), with examples and validation.

- **[F11]**
  - **Severity:** MINOR
  - **Finding:** The directory for monthly review is `_system/daily/` although it’s not “daily,” and its filename overlaps conceptually with dailies.
  - **Why:** Navigation and mental model friction.
  - **Fix:** Use `_system/attention/` or `_system/reviews/` or `_system/daily/reviews/` (keeping web UI consumption in mind).

- **[F12]**
  - **Severity:** MINOR
  - **Finding:** “Type registration” adds `daily-attention`, but the monthly review is also declared that same type; additionally the frontmatter schema includes `carry_forward_count`, which doesn’t apply to monthly review.
  - **Why:** Schema drift and validation exceptions.
  - **Fix:** Separate types or add optional fields by artifact subtype (explicitly documented).

---

### Feasibility (Ceremony Budget, Habit Formation, Practical Operation)

- **[F13]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Operator time budget (<5 minutes) is asserted, but the operator still must maintain goal tracker monthly, SE inventory “when responsibilities change,” and potentially correct the daily artifact frequently while habit is forming.
  - **Why:** Early adoption is the riskiest period; if week 1 requires frequent edits, it fails before it stabilizes.
  - **Fix:** Add an explicit “week 1 onboarding mode”:
    - smaller list (3–5 items),
    - fewer sources (goal tracker + yesterday + SE inventory only),
    - expand sources only after stable usage.

- **[F14]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Daily procedure step “assess which goals have had recent representation in daily artifacts” implies reading historical daily notes—potentially more docs than budgeted.
  - **Why:** This can quietly blow context and compute cost.
  - **Fix:** Maintain a lightweight rolling summary file (e.g., `_system/daily/_index.yaml`) updated each run with domain counts and goal references.

- **[F15]**
  - **Severity:** MINOR
  - **Finding:** “No carry-forward if yesterday’s artifact doesn’t exist” may lose continuity after weekends or missed days—precisely when continuity is helpful.
  - **Why:** People often skip planning on weekends; Monday then drops unresolved items.
  - **Fix:** Change rule to “use most recent prior daily artifact within last N days (e.g., 3)”; if older, start fresh.

---

### Clarity

- **[F16]**
  - **Severity:** MINOR
  - **Finding:** “Flag if work is >60% of items for 3+ consecutive days” is underspecified: is it item-count based or time-weighted? what’s “work” exactly?
  - **Why:** Ambiguity leads to surprising flags or none at all.
  - **Fix:** Define precisely:
    - denominator = total focus items
    - numerator = items whose domain in set `{career, software}` (or defined set)
    - consecutive days computed from existing daily files.

- **[F17]**
  - **Severity:** MINOR
  - **Finding:** The “Deferred” section is defined but not used in mechanics (does deferring prevent resurfacing, does it affect escalation?).
  - **Why:** Users will expect it to have behavioral effect; otherwise it’s pure journaling overhead.
  - **Fix:** Specify: deferred items are excluded for X days unless deadline/cadence triggers; or deferred items are candidates but down-ranked.

---

### Strengths

- **[F18]**
  - **Severity:** STRENGTH
  - **Finding:** Clear articulation of the core user problem, constraints, and the ceremony budget as the governing design principle.
  - **Why:** This is the right “north star” for personal systems; it prevents over-engineering.
  - **Fix:** None.

- **[F19]**
  - **Severity:** STRENGTH
  - **Finding:** Strong separation between prerequisite artifacts (goal tracker, SE inventory) and generated artifacts (daily plan, monthly review), with explicit locations and schemas.
  - **Why:** Enables automation, validation, and later UI consumption.
  - **Fix:** None.

- **[F20]**
  - **Severity:** STRENGTH
  - **Finding:** “Graceful degradation” and “human override” are explicitly called out as constraints.
  - **Why:** These are essential for real-world robustness in personal workflows.
  - **Fix:** None (but see findings on making override structurally safe).

- **[F21]**
  - **Severity:** STRENGTH
  - **Finding:** Overlay lenses (Life Coach + Career Coach) are integrated into procedure, not tacked on as optional commentary.
  - **Why:** Ensures cross-domain prioritization isn’t purely urgency-driven.
  - **Fix:** None.

---

## UNVERIFIABLE CLAIMS (flagged as requested)

- **[F22]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “~25 active Infoblox accounts with varying engagement levels, tracked by the customer-intelligence project.”
  - **Why:** Specific quantity and system-of-record reference cannot be independently verified from the spec alone.
  - **Fix:** Cite the source artifact (e.g., link to the customer-intelligence index) or replace with “N active accounts (see …)” and make N computed.

- **[F23]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “Delivery will be via a planned web UI (FIF/tess-operations workstream).”
  - **Why:** Workstream naming and plan status can’t be verified here; also it creates implied dependency expectations.
  - **Fix:** Link to the relevant project spec or issue in-vault; or phrase as “planned” with a pointer to the authoritative roadmap artifact.

---

## Top Recommendations (Most Leverage)

1. **Make Focus items structurally completable** (checkbox task list or explicit status field) to fix carry-forward correctness.  
2. **Split monthly review into its own type** and schema to avoid type confusion and validation hacks.  
3. **Bound the document load** (project index + cap + rolling summary) to align with stated context budget and ceremony budget.  
4. **Add explicit suppression/snooze semantics** so operator intent persists and the system doesn’t nag.  
5. **Define domain taxonomy + work-mapping** to make domain balance checks reliable and explainable.

---

## Google (gemini-3-pro-preview)

## Review of Attention Manager Specification

### Summary
 This is a high-quality, thoughtful specification that successfully applies systems thinking to personal productivity. The "Ceremony Budget" constraint (C1) and the "System runs the 24 hours" principle provide excellent architectural grounding. The distinction between input sources (goals/inventory) and the output artifact (daily plan) is clear.

However, there are three critical/significant mechanical issues regarding data persistence and context limits that may cause the system to fail in practice:
1.  **Context Window Overload:** The instruction to scan "all" project files contradicts the stated document budget.
2.  **Recurring Task Logic:** The mechanism for resetting recurring SE tasks in a static Markdown file is undefined, likely leading to stale data.
3.  **Carry-Forward Fragility:** The "skip a day, lose the list" logic creates a dangerous failure mode for weekends or sick days.

### Findings

#### F1. Context Budget vs. Dynamic Project Scanning
**Severity:** CRITICAL
**Finding:** Section 7.2 states a "Standard tier (5 docs)" budget. However, Section 7.3 (Procedure) Step 2 instructs the skill to "Scan active projects: read all `Projects/*/project-state.yaml` files."
**Why:** If the user has more than 1 or 2 active projects, the system will immediately exceed the 5-doc budget when combined with the 4 mandatory files (Goal Tracker, SE Inventory, Context, Yesterday's Note). This will either cause the prompt to fail or force the model to truncate essential context, leading to hallucinations about what tasks are actually pending.
**Fix:** 
1.  Create an intermediate aggregation step (a "Project Summary" file maintained by a separate process).
2.  Or, modify the `project-state.yaml` naming convention so the skill only reads `active-*.yaml` and enforce a hard limit (e.g., "Top 3 active projects").

#### F2. Undefined State Reset for SE Inventory
**Severity:** CRITICAL
**Finding:** Section 4.2 describes the SE Inventory as a static Markdown file with checkboxes ("This is NOT a task tracker. Completed items get unchecked at the start of each cycle"). However, the spec provides no mechanism for *how* this unchecking happens.
**Why:** Markdown files do not auto-reset. If the operator checks "Run inspects" on Tuesday, the file remains checked on Wednesday. Next Tuesday, the skill will see it as "checked" (done) and won't schedule it, even though the weekly cycle has reset. If the operator must manually uncheck items, this violates Constraint C1 (Ceremony budget). The skill cannot easily "edit" the file to uncheck boxes without risking file corruption or requiring complex file I/O capabilities not fully detailed here.
**Fix:** 
1.  Change the SE Inventory schema to include a `last_completed: YYYY-MM-DD` field next to items.
2.  The skill logic should be: `IF (today - last_completed > cadence) THEN status = pending`. This allows the file to be a log, not a toggle, and the skill handles the logic.

#### F3. Carry-Forward Data Loss on Skipped Days
**Severity:** SIGNIFICANT
**Finding:** Section 5.5 states: "If yesterday's artifact doesn't exist (weekend, missed day), no carry-forward — the skill produces a fresh list."
**Why:** This breaks the chain of custody for tasks. If an operator skips Sunday, the "carry_forward_count" for a task ignored on Saturday is lost on Monday. Critical tasks that were being procrastinated on (high carry count) will disappear from view exactly when they need escalation.
**Fix:**
1.  Modify the logic to search for `_system/daily/*.md` and sort by date descending, picking the *most recent* file, even if it is 2-3 days old.
2.  Calculate carry-forward days based on the date delta between the found file and today.

#### F4. Parsing Fragility of "Carried" Items
**Severity:** SIGNIFICANT
**Finding:** Section 5.5 implies the skill calculates carry counts by reading the generated prose of the previous day ("Item — carried N days").
**Why:** LLMs vary in their output formatting. If the model outputs "Carried forward (3 days)" one day and "Rolled over: 4 days" the next, the parsing logic in the next session may fail to recognize the integer, resetting the count.
**Fix:** Embed the carry-forward data in a machine-readable comment or HTML comment block within the daily note, e.g., `<!-- { "task_id": "G1-A", "carry_count": 3 } -->`, or rely on strict Regex enforcement in the prompt instructions.

#### F5. Prerequisite Logic Gap (SE Inventory)
**Severity:** MINOR
**Finding:** Section 3 (System Map) and Section 7.3 imply the system "reads" the SE Inventory. Section 4.2 defines it as a Markdown file.
**Why:** The skill needs to parse "cadence" and "deadline" from natural language text like `[cadence: weekly, deadline: Friday]`. While LLMs are good at this, it introduces ambiguity. Does "Friday" mean *this* Friday or *next* Friday?
**Fix:** Standardize the metadata in the SE Inventory to strictly structured text, e.g., `(Cadence: Weekly) (Day: Friday)`, to ensure consistent interpretation.

#### F6. Robustness of "Human Override"
**Severity:** STRENGTH
**Finding:** The design choice in C5 (Human override) and Section 5.5 (Operator edits are authoritative) is excellent. It acknowledges that the map is not the territory.
**Why:** Many systems fail because they try to force compliance. By treating the daily artifact as a "proposal" that becomes a record only after human interaction, the system remains subservient to the user.

#### F7. Goal Tracker "Progress" Field
**Severity:** MINOR
**Finding:** The Goal Tracker YAML includes a `progress` field defined as "free-text".
**Why:** If this field is updated by the operator, the skill needs to know *not* to overwrite it during monthly reviews, or how to append to it. The interaction between manual updates and skill-proposed updates in the Monthly Review section (7.4) is slightly ambiguous.
**Fix:** Clarify that the Monthly Review artifact *proposes* new YAML for the user to copy-paste, rather than the skill attempting to edit the file in place.

### Unverifiable Claims
No unverifiable external claims found. References to "Infoblox," "Tess," "FIF," and internal file paths are accepted as internal context data.

---

## DeepSeek (deepseek-reasoner)

## Structured Review of Attention Manager Specification

**Overall Assessment:** This is a well-structured, comprehensive specification that effectively balances ambition with practical constraints. The system design demonstrates strong internal consistency and thoughtful consideration of human factors.

---

### **CRITICAL Findings**

**F1 - CRITICAL**  
**Finding:** Missing validation mechanism for ceremony budget constraint (C1)  
**Why:** The primary design constraint is a 5-minute daily overhead, but the specification lacks concrete measurement or validation procedures. Without objective tracking, the system could fail its core requirement without detection.  
**Fix:** Add a validation task (AM-007) to implement time-tracking of operator interactions with the system during the dry-run, with explicit success criteria: "Average daily engagement <5 minutes over 7-day period."

**F2 - CRITICAL**  
**Finding:** Unclear reconciliation between SE inventory checkbox state and task completion  
**Why:** The SE inventory uses checkboxes that "get unchecked at the start of each cycle" but also states "the skill reads current checkbox state to know what's pending." This creates ambiguity: when an item is completed, does the operator check it (making it appear "done") or leave it unchecked? How does the skill distinguish "not yet due" from "overdue"?  
**Fix:** Clarify the state machine: (1) Unchecked = pending for current cycle, (2) Checked = completed in current cycle, (3) Skill resets all checked items to unchecked at cycle boundaries (daily for daily tasks, weekly for weekly, etc.). Specify reset logic in skill procedure.

**F3 - CRITICAL**  
**Finding:** Goal representation assessment mechanism unspecified  
**Why:** Section 7.3 step 4 states "assess which [goals] have had recent representation in daily artifacts" but provides no definition of "recent" or method for linking daily items to goals. Without this, the goal alignment section (5.4) becomes speculative.  
**Fix:** Add requirement for daily items to optionally reference goal IDs (e.g., `goal: G1` in item metadata). Define "recent" as "within last 7 days" for monthly goals, "within last 30 days" for quarterly.

---

### **SIGNIFICANT Findings**

**F4 - SIGNIFICANT**  
**Finding:** Unverifiable claim about dependency state  
**UNVERIFIABLE CLAIM:** "Customer-intelligence dossiers will contain machine-readable action items by the time this system is operational." (A3)  
**Why:** This assumption underpins the career domain curation but references future work outside this specification. If untrue, the system will have incomplete input.  
**Fix:** Add fallback behavior specification: "If dossier action items are not machine-readable, skill will include placeholder items based on dossier last-updated dates and priority flags."

**F5 - SIGNIFICANT**  
**Finding:** Missing error handling for missing prerequisite artifacts  
**Why:** Section 7.2 states the skill "MUST load" several files, but section 7.4's graceful degradation constraint (C4) only mentions unavailable sources, not missing files. If `goal-tracker.yaml` doesn't exist, should the skill create it? Error or degrade?  
**Fix:** Add explicit error states: "If goal-tracker.yaml missing → create template with placeholder goals and notify operator. If SE inventory missing → proceed with warning and no SE items."

**F6 - SIGNIFICANT**  
**Finding:** Vague vault-check validation requirements  
**Why:** Task AM-002 acceptance criteria mention "vault-check validates a sample daily-attention note without errors" but no validation rules are specified for the new type.  
**Fix:** Add explicit vault-check rule specification in AM-002: "Validate location pattern `_system/daily/*.md`, required frontmatter fields (type, created), and prohibited fields (no project, domain)."

**F7 - SIGNIFICANT**  
**Finding:** Unclear operator edit detection for carry-forward  
**Why:** Section 5.5 states operator edits are authoritative and lists three completion markers (checkbox, `[done]`, deletion), but doesn't specify how the skill detects which items were edited versus carried forward.  
**Fix:** Add item hashing or ID scheme: "Each daily item receives a unique ID combining source identifier and date. Skill tracks IDs, not just text, for carry-forward."

**F8 - SIGNIFICANT**  
**Finding:** Inconsistent monthly review location specification  
**Why:** Section 6 states location `_system/daily/review-YYYY-MM.md` but section 3's system map shows `_system/daily/review-YYYY-MM.md` under "monthly review" while the table says `_system/daily/` for both daily and monthly. This creates potential naming conflicts.  
**Fix:** Clarify: "Monthly reviews in `_system/daily/reviews/` subdirectory to avoid filename conflicts with daily artifacts."

**F9 - SIGNIFICANT**  
**Finding:** Unclear overlay co-firing mechanism  
**Why:** Section 7.2 states "MUST load (overlays)" but doesn't specify how conflicting guidance from Life Coach vs. Career Coach is resolved.  
**Fix:** Add prioritization rule: "Life Coach lens takes precedence for personal/spiritual domains; Career Coach for career/software. For cross-domain items, apply both and note tension in reasoning."

---

### **MINOR Findings**

**F10 - MINOR**  
**Finding:** Ambiguous "domain" categorization in daily artifacts  
**Why:** Section 5.4 lists example domains "career | software | learning | ..." but doesn't align with established Crumb domain taxonomy (Career, Software, Learning are domains; "software" appears as both domain and project class).  
**Fix:** Standardize to existing domain names: Career, Software, Learning, Spiritual, Personal, Creative.

**F11 - MINOR**  
**Finding:** Inconsistent date format in examples  
**Why:** Goal tracker example uses `target_date: 2026-03-31` (ISO format) but daily artifact uses `YYYY-MM-DD.md` in text. While clear, consistency aids parsing.  
**Fix:** Use ISO format (YYYY-MM-DD) consistently in all examples.

**F12 - MINOR**  
**Finding:** Missing retention automation specification  
**Why:** Section 5.1 mentions "Files older than 90 days can be pruned" but doesn't specify who or what performs pruning.  
**Fix:** Add note: "Pruning is manual operator task during monthly review. Future automation possible via vault-check rule."

**F13 - MINOR**  
**Finding:** Typographical inconsistency in system map  
**Why:** Diagram shows `_system/daily/` for monthly review path but table below shows same directory for both.  
**Fix:** Correct diagram to show `_system/daily/review-YYYY-MM.md` consistently.

---

### **STRENGTH Findings**

**S1 - STRENGTH**  
**Finding:** Excellent constraint-driven design  
**Why:** The Ceremony Budget Principle (C1) is consistently applied throughout the specification, with explicit attention to minimizing overhead. This human-centered approach increases likelihood of adoption.

**S2 - STRENGTH**  
**Finding:** Comprehensive consideration of failure modes  
**Why:** The specification thoughtfully addresses graceful degradation (C4), missing data, and human override (C5), making the system robust to real-world imperfections.

**S3 - STRENGTH**  
**Finding:** Clear separation of concerns  
**Why:** The division between prerequisite artifacts, daily operations, and monthly review creates a sustainable rhythm with appropriate abstraction levels.

**S4 - STRENGTH**  
**Finding:** Effective use of existing Crumb patterns  
**Why:** Leveraging vault-check, YAML frontmatter, existing overlay system, and project-state conventions ensures integration with the broader ecosystem rather than creating siloed functionality.

**S5 - STRENGTH**  
**Finding:** Well-structured validation plan  
**Why:** The task decomposition includes appropriate dry-run and validation steps (AM-004, AM-005) with concrete acceptance criteria, enabling iterative refinement.

---

### **Summary**

The specification demonstrates sophisticated system thinking with strong attention to human factors. The critical issues primarily involve missing operational details (state management, validation) rather than fundamental design flaws. Addressing the critical and significant findings will produce a robust, usable system that respects its core constraint of minimizing attention overhead.

**Most important fixes:**  
1. Clarify SE inventory state machine (F2)  
2. Add ceremony budget validation (F1)  
3. Define goal-item linking mechanism (F3)  
4. Specify error handling for missing files (F5)

The specification successfully navigates the tension between providing meaningful curation and maintaining low ceremony—a balanced approach that should serve the operator well if implemented as specified with the recommended improvements.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: CRITICAL
- [Finding]: No precise specification for how the attention-manager skill parses the SE management inventory (e.g., extracting unchecked checkboxes, cadences from inline annotations like "[cadence: weekly]"). Procedure mentions "lightweight regex" but provides no regex patterns, parsing logic, or edge-case handling (e.g., malformed annotations, varying formats).
- [Why]: Parsing unstructured markdown is error-prone and brittle for a vault-resident system; failures lead to incorrect curation (missing tasks or false positives), violating graceful degradation (C4) and feasibility as a reliable daily tool.
- [Fix]: Add a subsection under 7.3 with explicit parsing rules (e.g., regex for checkboxes `\[ \]`, cadence extraction `\[(cadence|deadline): ([^\]]+)\]`), sample inputs/outputs, and fallback (e.g., treat all listed items as pending if parsing fails).

- [F2]
- [Severity]: CRITICAL
- [Finding]: Skill lacks date/time awareness mechanism (current date, deadlines from goal-tracker.target_date, cadence matching like "weekly" to today). No mention of loading system date or computing "approaching deadlines" (e.g., expense reports "last business day").
- [Why]: Prioritization ("Why now"), carry-forward counters, domain balance streaks (3+ days), and monthly cadence depend on dates; without this, outputs are timeless and useless, breaking core functionality and assumptions (A2).
- [Fix]: Specify in 7.3 Procedure: "Load current date from system/environment. Compute business days, match cadences (e.g., weekly=every Mon, monthly=last Fri)." Add date-parsing library note if needed (within C2 no new infra).

- [F3]
- [Severity]: CRITICAL
- [Finding]: Inconsistency between referenced files: F6 and overlays mention `personal-philosophy.md`, but System Map, Dependencies, and 7.2 Context Contract specify `_system/docs/personal-context.md`. Unclear if distinct or error.
- [Why]: Skill context loading will fail or load wrong grounding, corrupting Life Coach prioritization; violates internal consistency.
- [Fix]: Clarify/resolve file paths (e.g., merge or list both). Update all sections to consistent paths with links.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Scanning active projects assumes all `Projects/*/project-state.yaml` have `next_action` fields, but no spec for identifying "active" projects (e.g., status: active filter?) or handling missing/invalid YAML.
- [Why]: Could pull stale/irrelevant actions from inactive projects, bloating list and violating curation aggressiveness (L2); incomplete graceful degradation.
- [Fix]: Define "active" (e.g., filter `status: active` in YAML). Add: "Skip files without valid next_action; log skipped in artifact."

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Customer-intelligence dossiers assumed "machine-readable action items" (A3, U3 partial), but no schema or parsing spec; procedure says "MAY load... when needed" without criteria.
- [Why]: Hard dependency risk (C4 violated if not ready); daily list incomplete for career domain (~25 accounts, F4), undermining cross-domain prioritization.
- [Fix]: Add validation task in AM-002: "Confirm dossier action format." Specify parsing (e.g., YAML frontmatter actions) or default to none.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Domain balance check ("work >60% for 3+ days") undefined: what counts as "work"? (e.g., career+software? Full domain taxonomy missing). No computation spec (e.g., item count %).
- [Why]: Ambiguous output; skill can't reliably produce "Brief assessment" without rules, leading to inconsistent artifacts.
- [Fix]: Define taxonomy in new section 8 (e.g., table: career=work, software=work, family=personal). Spec % as (work domains items / total focus items).

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Carry-forward assumes unchecked items via pattern matching (`[ ]`, `[x]`, `[done]`), but no exact matching logic or handling for operator custom edits (e.g., strikethrough, comments).
- [Why]: Breaks if operator edits freely (C5 human override); multi-day misses could cascade stale items, per U3.
- [Fix]: Detail in 5.5: "Match lines starting with '### \d+\. ', check for checkbox variants or 'done/deleted'. Preserve operator-added notes."

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Monthly review uses same `type: daily-attention` as daily artifacts; no distinction in schema (e.g., subtype, filename pattern triggers it).
- [Why]: Vault-check/type taxonomy can't differentiate; future consumers (web UI) confused; violates C3 vault-resident standards.
- [Fix]: Use `type: monthly-attention-review` or add `scope: monthly` frontmatter. Update taxonomy.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: No weekend/holiday handling: daily curation every day? Goal alignment/cadences ignore non-work days?
- [Why]: Wastes attention on non-applicable days (e.g., spiritual heavy weekends); feasibility low for 7-day habit from scratch (F1).
- [Fix]: Add trigger filter: "Skip if weekend unless operator requests." Or auto-adjust (lighter list weekends via Life Coach).

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Prioritization lenses (Life/Career Coach) referenced extensively but not excerpted/defined here; assumes external overlays perfect.
- [Why]: Skill procedure can't be implemented without them; validation (AM-004) risks subjective quality.
- [Fix]: Inline key questions from 11 as procedure steps, or link excerpts.

- [F11]
- [Severity]: MINOR
- [Finding]: Goal-tracker schema `domain` values (e.g., software, career) don't match daily artifact examples (learning, family implied); no full domain list.
- [Why]: Minor inconsistency; skill can't reliably map for goal alignment section.
- [Fix]: Add domain taxonomy table in 4.1.

- [F12]
- [Severity]: MINOR
- [Finding]: Retention "90 days" arbitrary; no rationale or automation spec (manual prune?).
- [Why]: Adds unstated ceremony; risks vault bloat if forgotten.
- [Fix]: Justify (e.g., "monthly reviews suffice") or add vault script note.

- [F13]
- [Severity]: MINOR
- [Finding]: Task AM-001 tags `#writing` but requires operator data population (not Crumb); acceptance lacks verification of "real data."
- [Why]: Blurs task ownership; dry-run (AM-004) fails without it.
- [Fix]: Split: Crumb creates empty, operator action separate.

- [F14]
- [Severity]: MINOR
- [Finding]: Context budget "standard tier (5 docs)" but lists >5 MUST/MAY loads (goal-tracker, SE inv, personal-context, yesterday, overlays x2+, projects scan).
- [Why]: Exceeds limits; skill fails in practice.
- [Fix]: Prioritize MUST (top 5), conditional others; note tier escalation.

- [F15]
- [Severity]: STRENGTH
- [Finding]: Ceremony Budget Principle (C1 <5 min, L1/L2 levers) permeates design (YAML light, curation aggressive, no new infra).
- [Why]: Directly addresses key tension; enables habit from scratch (F1/F2).
- [Fix]: N/A

- [F16]
- [Severity]: STRENGTH
- [Finding]: Graceful degradation (C4) explicit: partial inputs ok, no hard deps.
- [Why]: Robust for evolving prereqs (A3/A5); supports feasibility.
- [Fix]: N/A

- [F17]
- [Severity]: STRENGTH
- [Finding]: Dry-run validation (AM-004/AM-005) with metrics (4/5 useful, actionable observations) calibrates assumptions (A1/A2/U1-U3).
- [Why]: Empirical tuning prevents abandonment (F8 principle).
- [Fix]: N/A

---

## Claude (claude.ai — manual submission)

**Overall assessment: Strong spec.** Problem well-defined, ownership split clean, Ceremony Budget Principle threaded through correctly, design decisions well-reasoned. Open questions from input spec all resolved with defensible answers.

### Findings

- **[F1] SIGNIFICANT:** Context budget math doesn't close for daily procedure. MUST-load is 6 items (goal-tracker, SE inventory, personal-context, yesterday's artifact, life-coach + companion, career-coach). Then §7.3 step 2 scans all `Projects/*/project-state.yaml` (18 files currently). Suggests: (a) revise budget, (b) scope scan to active only, or (c) define lightweight scan mechanism like session-startup.sh aggregation. Notes overlays are stated elsewhere as exempt from budget.

- **[F2] SIGNIFICANT:** SE inventory "reset each cycle" mechanic underspecified and fragile. Checkbox toggling simulates recurrence with state that doesn't naturally have recurrence semantics. Deeper alternative: skill infers "this is due" from cadence annotation + last daily artifact where it appeared as completed. SE inventory becomes a static reference doc that only changes when responsibilities change — no checkbox toggling needed.

- **[F3] SIGNIFICANT:** Write-read path verification gap. Per `write-read-path-verification.md` solution pattern, every write path needs a verified read path. Two of three consumers (web UI, Tess briefing) are explicitly future. Spec should acknowledge the gap and note the schema flexibility risk.

- **[F4] MODERATE:** `carry_forward_count` in frontmatter counts the wrong thing. Per-artifact count vs per-item carry counts in the body. An artifact with items carried 1 day and 8 days both have `carry_forward_count: 1`. Field is redundant with lower fidelity — consider dropping.

- **[F5] MODERATE:** Monthly review shares `type: daily-attention`. Two different document shapes need different validation. Give monthly review its own type.

- **[F6] MODERATE:** Missing day carry-forward rule creates information loss. Suggests: scan backward up to 3 days for most recent artifact.

- **[F7] MINOR:** Goal-tracker is first pure `.yaml` file in `_system/docs/`. Every other file is markdown. vault-check may need to handle this.

- **[F8] MINOR:** 5-8 items range not justified. Number interacts with item granularity — "ship FIF soak" vs "reply to 3 emails" are different scales. Skill should define what constitutes "one item."

- **[F9] MINOR:** No AKM integration mentioned. Input spec listed AKM as existing source. Could enrich monthly reviews with library knowledge about productivity/attention patterns.

### Strengths

- Ownership split (Crumb reasons, Tess delivers, human overrides) crisp and well-maintained.
- Ceremony Budget Principle genuinely applied, not just cited. Goal-tracker design reflects real constraint thinking.
- Carry-forward escalation at 5 days distinguishes "busy" from "not a priority."
- On-demand rather than session-startup is correct — avoids coupling to session frequency.
- Deferred section is underrated — knowing what was excluded with reasoning is as valuable as what was included.

---

## Perplexity (manual submission)

**Overall assessment: Strong spec with targeted mechanical gaps.** Problem well-defined, ceremony budget discipline genuine, graceful degradation is the right default. The spec's biggest blind spot is calendar integration — a day-planning tool that ignores existing schedule commitments. SE inventory and carry-forward mechanics need tightening. Monthly review context budget is off by an order of magnitude.

### Findings

- **[F10] CRITICAL:** Calendar is completely absent from the input model. The problem statement names "calendar" as one of the places SE management tasks currently live, but the system map, context contract, and daily procedure contain zero calendar integration. A day-planning tool that ignores the operator's existing schedule will produce Focus lists that conflict with the calendar, requiring mental merging that undermines the <5 min ceremony budget.

- **[F11] SIGNIFICANT:** SE inventory cadence parsing is specified by example, not by schema. Inline annotations show inconsistent formats: `cadence: weekly/biweekly, day: TBD`, `cadence: monthly, deadline: last business day`, `cadence: as announced, typical lead time: 2 weeks`. Computing "approaching deadline" from `cadence: as announced` is an inference problem, not a parsing problem. Needs either a constrained vocabulary or an acknowledgment that cadence-based surfacing is best-effort.

- **[F12] SIGNIFICANT:** Focus item done-detection underspecified — body template used headings with no checkboxes, but carry-forward mechanics assumed checkbox state. *(Note: This is now addressed by A1 — Focus items are checkboxes in the revised spec.)*

- **[F13] SIGNIFICANT:** Domain balance 3-day consecutive check requires reading at least 3 daily artifacts, but context contract only loads yesterday. Either relax to a 2-day check (today + yesterday) or expand the contract.

- **[F14] SIGNIFICANT:** Monthly review loads "all daily artifacts for the month" (~17-20 at 4 days/week). Budget says "Extended tier (7-8 docs)". Off by 10-15x. Needs a pre-processing aggregation step. *(Note: Now addressed in revised §7.4 — pre-processing step added.)*

- **[F15] MODERATE:** 90-day retention policy uses passive voice ("can be pruned") with no assigned executor. No task in §9 creates a pruning mechanism.

- **[F16] MODERATE:** No mechanism surfaces items from domains without input sources. Health, relationships, creative, spiritual have no input pipeline — only reachable through goal-tracker. Domain balance check will flag their absence but can't fix it. Should distinguish "no input source exists" from "input exists but was deprioritized."

- **[F17] MINOR:** Deferred section creates ceremony with unclear payoff. Monthly review content spec (§6) doesn't reference the Deferred section. If it has no active reader, it fails the write-read path test.

- **[F18] MINOR:** Goal tracker `updated` field has no consumer. Adding a staleness check (>45 days → flag in daily artifact) would give it a purpose for free.

### Directed Question Responses

**Staleness risk:** Cheap fix — skill checks `updated` fields on goal-tracker (45-day threshold) and SE inventory (30-day threshold). Deeper staleness (stale data inside current files) is deferred to monthly review.

**Prioritization algorithm:** One more layer needed — not a rigid matrix, but a tiebreaker heuristic: non-negotiable commitments always make the list; among discretionary items, bias toward external visibility and time decay; "What has the worst consequence if deferred one more day?"

**Scale of daily scan:** Addressable via a project-index digest file or status-gated loading. Project index is the better investment — reusable across skills.

**Bootstrapping:** Suggests a bootstrapping sequence: first runs use whatever input exists, then day-5 mini-review proposes initial goals from observed patterns.

**Skill vs. habit:** Usage gap warning ("Last daily artifact was N days ago") and Tess as nudge layer (integration point recommendation, not a change to this spec).

### Strengths

- S1: Ceremony budget as a first-class design razor, not just a constraint statement.
- S2: Honest epistemics in Facts/Assumptions/Unknowns — A4 labeled as assumption to validate, not requirement to enforce.
- S3: Graceful degradation enables shipping before all inputs exist.
- S4: Carry-forward behavioral design is sound (escalation at 5 days, "fresh list after gap").
- S5: On-demand trigger avoids coupling to session frequency.

---

## Synthesis

### Consensus Findings

**1. Context budget exceeded by project scan** (OAI-F3, GEM-F1, GRK-F4, GRK-F14, CLD-F1, PPX-F14)
All 6 reviewers flagged context budget issues. The skill's MUST-load list has 6 items before project scanning. Perplexity extends this to the monthly review, which is off by 10-15x (loading ~17-20 daily artifacts against a 7-8 doc budget). Claude notes overlays are exempt from budget, but the MUST-load count still exceeds 5.

**2. SE inventory state management undefined** (GEM-F2, DS-F2, OAI-F10, GRK-F1, CLD-F2, PPX-F11)
All 6 reviewers flagged this. Perplexity adds that the cadence annotations are specified by example, not by schema, with inconsistent formats. Claude proposes the deepest solution: static inventory with skill-inferred due dates from daily artifact completion history. Adopted.

**3. Carry-forward items not structurally completable** (OAI-F1, GEM-F4, GRK-F7, PPX-F12)
4 reviewers noted that Focus items use `### N.` headings but carry-forward relies on checking off items. No structural completion marker exists in the template. Perplexity extended this to done-detection ambiguity across three methods.

**4. Monthly review shares type with daily artifact** (OAI-F2, DS-F8, GRK-F8, CLD-F5)
4 reviewers flagged that using `type: daily-attention` for both daily plans and monthly reviews breaks type semantics, vault-check validation, and future consumers (web UI).

**5. Domain taxonomy undefined for balance checks** (OAI-F6, OAI-F16, GRK-F6, DS-F10, PPX-F13, PPX-F16)
5 reviewers flagged this area. Perplexity adds that the 3-day consecutive check requires reading 3 daily artifacts, exceeding the context contract, and that domains without input sources (health, relationships, creative, spiritual) will be structurally under-represented — the balance check will flag their absence but can't fix it.

**6. Customer dossier dependency risk** (OAI-F8, GRK-F5, DS-F4)
3 reviewers flagged A3 (machine-readable dossier action items) as an unverified dependency with no fallback behavior specified.

**7. Carry-forward loss on skipped days** (OAI-F15, GEM-F3, CLD-F6)
3 reviewers noted that "no carry-forward if yesterday doesn't exist" drops continuity after weekends. All suggest using the most recent artifact within N days.

### Unique Findings

**DS-F3: Goal-item linking mechanism missing** — Genuine insight. The spec says "assess which goals have had recent representation" but provides no mechanism to connect daily items to goal IDs. Without this, goal alignment is guesswork.

**CLD-F2: SE inventory as static reference (deeper solution)** — Claude proposes that the SE inventory should be a static reference doc with no state at all — no checkboxes, no `last_completed` fields. The skill infers "due" from cadence annotation + scanning recent daily artifacts for when the item last appeared as completed. This is the lowest-ceremony solution: the inventory only changes when responsibilities change. Adopted as the approach for A2.

**CLD-F3: Write-read path verification gap** — Per the `write-read-path-verification.md` solution pattern, every write path needs a verified read path. Two of three stated consumers (web UI, Tess briefing) are explicitly future. The spec should acknowledge the gap and note the schema flexibility risk.

**CLD-F4: `carry_forward_count` frontmatter field redundant** — Per-artifact count vs per-item carry counts in the body. An artifact with items carried 1 day and 8 days both show `carry_forward_count: 1`. Field is lower fidelity than per-item body data. Should be dropped.

**CLD-F7: First `.yaml` file in `_system/docs/`** — Goal-tracker would be the first pure YAML file in `_system/docs/`. Every other file is markdown. vault-check may need to handle this extension.

**PPX-F10: Calendar absent from input model** — The strongest unique finding across all reviewers. A day-planning tool that doesn't know about the operator's existing calendar commitments will produce lists that conflict with scheduled meetings, all-hands, appointments. The operator must mentally merge two planning surfaces, directly undermining the ceremony budget. Either integrate calendar (even a markdown export) or explicitly declare it out of scope with rationale. Claude's assessment: genuine insight, but calendar integration is infrastructure that violates C2 (no new tooling). The pragmatic answer: acknowledge the gap as a known limitation, note that the operator's calendar review is part of the <5 min review time, and flag calendar integration as a future enhancement if ceremony burden proves too high during AM-004.

**PPX-F15: 90-day retention has no executor** — Valid. No task creates a pruning mechanism, and passive "can be pruned" will never happen. Low urgency but should have an owner.

**PPX-F17: Deferred section write-read path** — Extends CLD-F3. The monthly review spec (§6) doesn't reference the Deferred section. If it has no reader, it fails write-read path. Either the monthly review should consume it or it should be lighter (single-line count instead of enumerated reasoning).

**PPX-F18: Goal tracker `updated` staleness** — Cheap fix: skill checks `updated` field and flags if >45 days old. Gives the field a consumer for free.

**PPX bootstrapping sequence** — Suggests first runs with empty goals use whatever input exists, then day-5 mini-review proposes initial goals from observed attention patterns. Elegant, fits within existing AM-004 structure.

**PPX priority resolution heuristic** — Suggests explicit tiebreaker: non-negotiable commitments always make the list, discretionary items biased toward external visibility/time decay, "what has the worst consequence if deferred one more day?" Good addition to §7.3 or §11.

**GRK-F2: Date/time awareness unspecified** — Valid observation but low-risk: the skill runs inside Claude Code which has shell access to `date`. Standard Crumb skill behavior. Worth a one-line clarification, not a redesign.

**DS-F1: Ceremony budget validation/measurement** — Interesting but self-defeating: adding formal time-tracking to validate a <5min constraint adds ceremony to reduce ceremony. AM-004 dry-run already covers this via operator feedback.

**OAI-F7: Time feasibility of items** — Adding time estimates (S/M/L) to items would improve realism but increases ceremony. The 5-8 item cap is the sizing heuristic. Defer and let dry-run reveal if needed.

**OAI-F13: Week-1 onboarding mode** — Good idea (smaller list, fewer sources during initial adoption). Premature to specify — let AM-004 dry-run reveal whether ramp-up is needed.

**GRK-F9: Weekend handling** — Genuine question. On-demand invocation ("plan my day") naturally handles this — the operator simply doesn't invoke on days they don't want a plan. No code change needed, but worth documenting the intent.

**OAI-F4: Suppression/snooze semantics for Deferred section** — The Deferred section currently has no behavioral effect. Should it suppress resurfacing? Good question for dry-run validation.

### Contradictions

**SE inventory format:** OAI-F10 and GRK-F1 want structured parsing rules (regex patterns, strict grammar). GEM-F2 wants a `last_completed` date field approach. DS-F2 wants a formal state machine. CLD-F2 proposes eliminating all state from the inventory — make it a static reference doc and have the skill infer "due" from cadence + last daily artifact completion. All agree the current design is underspecified. Claude's judgment: CLD-F2's static-inventory approach is adopted — it's the lowest-ceremony solution and eliminates the state management problem entirely. The skill scans recent daily artifacts for completion evidence rather than maintaining state in the inventory file.

**Parsing approach:** GRK-F1 wants explicit regex patterns for SE inventory parsing. This assumes a traditional parser, but the attention-manager skill is an LLM reading markdown — it understands inline annotations without regex. The concern about brittleness is valid for regex parsers but overstated for LLM readers. However, the annotations should be consistently formatted.

### Action Items

**Must-fix:**

- **A1** (OAI-F1, GEM-F4, GRK-F7): **Use checkbox-style Focus items.** Change the Focus section template from `### N. [Item]` headings to `- [ ] Item description` with indented sub-bullets for Why/Domain/Source. Gives a clear done/not-done signal for carry-forward.

- **A2** (GEM-F2, DS-F2, OAI-F10, CLD-F2): **Make SE inventory a static reference doc.** Remove checkboxes. Items list obligations with cadence annotations but no state. The skill infers "due" by scanning recent daily artifacts for when the item last appeared as completed. Inventory only changes when responsibilities change — zero maintenance ceremony. (CLD-F2 approach adopted over GEM's `last_completed` field — even lower ceremony.)

- **A3** (OAI-F2, DS-F8, GRK-F8): **Separate monthly review type.** Register `attention-review` as a distinct type. Monthly reviews go to `_system/daily/review-YYYY-MM.md` with `type: attention-review`.

- **A4** (OAI-F15, GEM-F3): **Carry-forward uses most recent artifact within 3 days.** Change "if yesterday doesn't exist, start fresh" to "find most recent daily artifact within last 3 days; if older or none, start fresh." Preserves continuity across weekends.

**Should-fix:**

- **A5** (OAI-F3, GEM-F1, GRK-F4): **Clarify context budget for project scanning.** Project-state.yaml files are small YAML (~10 lines). The skill reads them as mechanical data extraction (extract `next_action` where not null), not as context documents for reasoning. Clarify that this is a scan step, not a context-loading step, and doesn't count against the 5-doc budget. Cap at active projects only (projects in `Projects/`, not `Archived/`).

- **A6** (OAI-F6, GRK-F6, DS-F10): **Define domain balance taxonomy.** Add: "work" = `{career, software}`. Balance check = `(work items / total focus items)`. Flag when >60% for 3+ consecutive days. Use the existing 8-domain taxonomy from CLAUDE.md.

- **A7** (OAI-F8, GRK-F5, DS-F4): **Add dossier fallback.** "If customer-intelligence dossiers lack structured action items, the skill proceeds without career-engagement items and notes the gap in the Domain Balance section."

- **A8** (DS-F3): **Add optional goal references to daily items.** Each Focus item may include `Goal: G1` linking it to a goal-tracker entry. The skill uses these to populate the Goal Alignment section. Not required on every item — the skill infers alignment for unlinked items.

- **A9** (GRK-F13, DS-F5): **Clarify AM-001 ownership split.** Crumb creates template files with example structure. Operator populates with real data as a separate action item (not a Crumb task). Add to AM-003 acceptance criteria: "Skill produces useful output even with minimal/placeholder data in prerequisites."

- **A10** (CLD-F4): **Drop `carry_forward_count` from frontmatter schema.** Per-artifact count is lower fidelity than per-item carry data in the body. Redundant field adds noise.

- **A11** (CLD-F3): **Acknowledge write-read path gap.** Add a note to §5 or §7 that two of three consumers (web UI, Tess briefing) are future — current verified read path is operator-in-vault only. Schema should be treated as provisional until a second consumer validates it.

- **A12** (PPX-F10): **Acknowledge calendar gap.** Add to constraints: calendar integration is out of scope (violates C2) but operator's calendar review is part of the <5 min review time. Flag as future enhancement if ceremony burden is too high during AM-004.

- **A13** (PPX-F18): **Add goal-tracker staleness check.** Skill checks `updated` field — if >45 days old, flag in daily artifact. Cheap, gives the field a consumer.

- **A14** (PPX priority heuristic): **Add priority resolution heuristic to §7.3.** Non-negotiable commitments always make the list. Among discretionary items, bias toward external visibility/time decay. "What has the worst consequence if deferred one more day?"

- **A15** (PPX-F16): **Distinguish "no input source" from "deprioritized" in domain balance.** Domains without input pipelines (health, relationships, creative, spiritual) can only surface through goal-tracker entries. Balance check should note which domains lack sources rather than nagging about absence it can't fix.

**Defer:**

- **A16** (DS-F1): Formal ceremony budget time-tracking. AM-004 dry-run covers this via operator feedback. Adding measurement adds ceremony. `reason: overkill`
- **A17** (OAI-F7): Time estimates on items. The 5-8 cap is the sizing heuristic. Revisit if AM-004 shows consistently unrealistic lists. `reason: overkill`
- **A18** (OAI-F13): Week-1 onboarding mode. Let dry-run reveal if needed. `reason: overkill`
- **A19** (OAI-F14): Rolling summary file for goal representation tracking. Over-engineering. The skill can check recent filenames in `_system/daily/`. `reason: overkill`
- **A20** (OAI-F4, OAI-F17): Deferred section suppression semantics. Good question but specifying suppression rules before the system exists is premature. Let dry-run reveal whether resurfacing is annoying. `reason: out-of-scope`
- **A21** (GRK-F9): Weekend handling. On-demand invocation naturally handles this. Document intent. `reason: constraint` (on-demand model makes this moot)
- **A22** (OAI-F9, DS-F12, GRK-F12): Retention automation. Monthly review captures durable signal. Manual pruning is fine for now. `reason: out-of-scope`
- **A23** (CLD-F7): vault-check YAML handling. Goal-tracker is first `.yaml` in `_system/docs/`. Check during AM-002 implementation. `reason: out-of-scope` (implementation detail, not spec)
- **A24** (CLD-F8, PPX-F8): Item granularity definition. Let dry-run calibrate what "one item" means. `reason: overkill`
- **A25** (CLD-F9, PPX-F9): AKM integration for monthly reviews. Useful enrichment but not core. Revisit after AM-005. `reason: out-of-scope`
- **A26** (PPX-F15): Retention pruning executor. Assign ownership of 90-day cleanup. Low urgency. `reason: out-of-scope`
- **A27** (PPX-F17): Deferred section write-read path. Monthly review should reference Deferred data, or section should be lighter. Evaluate during AM-004. `reason: out-of-scope`
- **A28** (PPX bootstrapping): Formal bootstrapping sequence for empty goal-tracker. AM-004 acceptance criteria could note day-5 goal proposal. `reason: overkill` (existing graceful degradation + AM-004 covers this)

### Considered and Declined

- **GRK-F3** (personal-philosophy.md vs personal-context.md inconsistency): `incorrect` — These are two separate files serving different purposes. `personal-context.md` provides strategic priorities; `personal-philosophy.md` is the Life Coach companion doc. Both are correctly referenced in their respective contexts. Not an inconsistency.

- **GRK-F2** (date/time awareness): `constraint` — The skill runs inside Claude Code which has shell access to `date` commands and the session startup hook provides the current date. Standard Crumb skill behavior. Worth a clarifying note in the procedure, not a design change.

- **GRK-F10** (overlay lens questions should be inlined): `overkill` — The overlays are loaded as context documents per the context contract. Inlining their questions into the skill procedure duplicates content and creates a maintenance burden. The spec already references them in §11.

- **DS-F9** (overlay conflict resolution rules): `incorrect` — Overlays are lenses providing different perspectives, not competing rule systems. The skill applies both Life Coach and Career Coach lenses and notes tension where it exists. This is by design — the synthesis is the value, not mechanical precedence rules.

- **OAI-F22, OAI-F23** (unverifiable claims about Infoblox accounts and web UI): `constraint` — These are internal facts about the operator's context, verified by the operator during scoping questions. Not claims requiring external verification.

- **GRK-F1** (explicit regex patterns for SE inventory parsing): `incorrect` — The attention-manager skill is an LLM reading structured markdown, not a regex parser. LLMs understand inline annotations like `[cadence: weekly]` without regex specifications. However, A2 (replacing checkboxes with `last_completed` dates) addresses the underlying concern about state management.
