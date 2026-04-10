# Crumb — Personal Multi-Agent OS
*The work persists.*

## Project Overview
Crumb is a personal multi-agent operating system built on Claude Code. It uses this Obsidian vault as external memory and single source of truth. All context, decisions, patterns, and deliverables persist in the vault — not in chat history. The vault root is wherever this CLAUDE.md file lives.

## Domains
software · career · learning · health · financial · relationships · creative · spiritual · lifestyle

## Workflow Routing

### Ceremony Budget Principle
Before proposing new capabilities, skills, or pipelines, evaluate whether existing friction can be reduced first. Reducing ceremony is higher leverage than adding capability. New primitives increase operational surface — justify against maintenance gravity. If a feature exists but isn't being used, the bottleneck is more likely ceremony than missing functionality. Conversely, if a new capability seems necessary, ask whether the real need is to unblock an existing one — heavy intake ceremony that suppresses adoption creates the illusion of missing features when the feature exists and the pipeline is just too costly to use. See `_system/docs/crumb-v2-system-health-assessment.md` for provenance.

- **Strategic directive:** When multiple projects compete for session priority, consult `_system/directives/liberation-directive.md` for the active governing directive. Revenue-generating prompts get priority claim; all other work continues in parallel.
- **Software projects:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Knowledge work** (career, learning, financial): SPECIFY → PLAN → ACT
- **Personal** (health, relationships, creative, spiritual, lifestyle): CLARIFY → ACT
- **Non-project interactions:** Log to `_system/logs/session-log.md` with compound evaluation at session end
- **Workflow entry threshold:** ≥3 vault files modified OR downstream dependencies → formal workflow
- If threshold crossed mid-conversation, prompt user for project creation (Project Creation Protocol)
- User can request project creation at any time without waiting for threshold
- When uncertain, default to lighter workflow variant for the domain
- Within-project prompt triage — calibrate response depth to the request:
  - FULL: new phase, new task, scope change → full skill/overlay/context loading
  - ITERATION: refining current work → load only what the change needs
  - MINIMAL: quick fix, lookup, clarification → just do it, no skill invocation
- Never skip phases within a workflow. If reality diverges from spec, update spec first.

### Phase Transition Gate (REQUIRED before moving to next phase)
Load and follow the full procedure in `_system/docs/context-checkpoint-protocol.md`. Do NOT proceed to the next phase until all steps are complete.

### Project Creation (REQUIRED before starting any formal workflow)
When work crosses the workflow entry threshold OR user requests a project:
1. Propose project name (kebab-case) and domain classification
2. User confirms or overrides name and domain
3. Create scaffold: `Projects/[name]/`, `Projects/[name]/project-state.yaml`,
   `Projects/[name]/progress/run-log.md`,
   `Projects/[name]/progress/progress-log.md`, `design/` subdirectory (software only)
3b. External repo gate (software `system` projects only):
    Confirm code directory with user (convention: `~/openclaw/[project-name]/`), `mkdir -p`,
    `git init` + `.gitignore`, initial commit, record `repo_path` in `project-state.yaml`.
    If the repo has a build step (`tsconfig.json` or `build` script in `package.json`),
    record `build_command` in `project-state.yaml`.
    Skip for: knowledge-work, vault-only software, and non-`system` projects.
3c. Service registration (ongoing, not just creation):
    When creating a launchd plist for a project with `repo_path`, add the plist label
    to `services` list in `project-state.yaml`. This enables the session-end build
    verification step to restart services after rebuilds.
4. Use `specification.md` (not `spec.md`), frontmatter `type: specification`,
   `skill_origin: systems-analyst`. See _system/docs/crumb-design-spec-v2-4.md §2.1, §2.2.
5. Enter first workflow phase

## Risk-Tiered Approval
- **Low risk:** Auto-approve — reading, drafting, testing, logging, searching vault
- **Medium risk:** Proceed + flag — creating new files, modifying non-critical docs, routine changes
- **High risk:** Stop and ask — architecture changes, schemas, external comms, production, irreversible actions

## Context Rules
- Always read *-summary.md before full docs
- Target ≤5 source docs per skill invocation (standard); 6-8 with justification (extended); 10 design ceiling
- Write a context inventory to run-log after loading context, before beginning core work
- Scope all vault queries by project/domain + topic — never unbounded vault searches
- Write YAML frontmatter on every new document (see _system/docs/file-conventions.md)
- Use Context Checkpoint Protocol between workflow phases (see _system/docs/context-checkpoint-protocol.md)
- Context pressure degrades quality before hitting hard limits — see degradation guide in Context Checkpoint Protocol for operational adjustments at each capacity band
- **Input validation before skill execution:** Before running a skill's core procedure, verify: (1) required input files exist and are readable, (2) input frontmatter matches expected type/schema, (3) any referenced artifacts (specs, designs, tasks) are current (not stale). If validation fails, stop and flag — do not proceed with stale or missing inputs

## File Access
- Use **Obsidian CLI** for indexed queries (search, tags, backlinks, properties) when Obsidian is running
  — see obsidian-cli skill for safe command patterns
- Use **native file tools** (Read, Write, Edit, Grep, Glob) for direct read/write and as fallback
  when Obsidian is not running
- CLI availability is checked automatically by the SessionStart hook
- Knowledge base queries: `obsidian tag name=kb/<topic>` and
  `obsidian backlinks path=Domains/<domain>/<domain>-overview.md`
- **Canonical #kb/ Level 2 tags** (use these — do not invent new Level 2 tags without user approval):
  `religion` · `philosophy` · `gardening` · `history` · `inspiration` · `poetry` · `writing` · `business` · `networking` · `security` · `software-dev` · `customer-engagement` · `training-delivery` · `fiction` · `biography` · `politics` · `psychology` · `lifestyle`
- Level 3 subtopics (e.g., `#kb/networking/dns`, `#kb/business/pricing`) are open — create through compound engineering when needed
- Three levels is the hard cap: `#kb/topic/subtopic` maximum. vault-check.sh enforces this.
- When a subtopic is subordinate to an existing Level 2 tag (e.g., DNS is a subtopic of networking), use Level 3 (`kb/networking/dns`), not a separate Level 2. Cross-domain topics use dual tagging (e.g., `kb/networking/dns` + `kb/security` for DNS security).

## Subagent Configuration
Default model: same as main session. Override per-subagent via agent YAML frontmatter `model` field. Only override when session cost data justifies it.

## Model Routing
Skill `model_tier` maps to concrete models:
- `reasoning` → session default (Opus)
- `execution` → Sonnet (`claude-sonnet-4-6`)

When loading a skill with `model_tier: execution`, delegate the skill's procedure to a Sonnet subagent via the Task tool (`model: "sonnet"`). Pass the skill procedure, relevant file paths, and any required context as the subagent prompt. Review subagent output before finalizing.

Skills without `model_tier` inherit the session model (backward compatible).

Precedence: subagent explicit `model` field > skill `model_tier` > session default.

### Cost Observation
At session end, note model routing decisions and their outcomes in the run-log entry:
- Which skills were delegated to Sonnet vs. kept on Opus
- Whether delegation produced acceptable quality (pass/rework/fail)
- Any notable token-heavy operations (large file reads, multi-round subagents)

This creates a lightweight feedback loop — routing decisions are reviewed against actual results, not just assumed correct. Adjust `model_tier` assignments when patterns emerge (e.g., a skill consistently requires Opus rework after Sonnet delegation → promote to `reasoning`).

Phased rollout — delegation is active for:
- **Phase 1 (immediate):** Zero-context mechanical skills — sync, checkpoint, startup, obsidian-cli, meme-creator
- **Phase 2 (immediate):** Structured-input skills — mermaid, excalidraw, lucidchart
- **Phase 3 (deferred):** Interactive skills with prompting phases (e.g., inbox-processor) — requires dispatch manifest design to preserve user decisions across the handoff

## Plan Mode
- Use Plan Mode (Shift+Tab twice) during SPECIFY and PLAN validation phases for mechanical read-only enforcement
- Exit Plan Mode before phases requiring file writes (TASK, IMPLEMENT)

## Behavioral Boundaries

**System Behaviors (autonomous — Claude handles without prompting):**
- Context management, session logging, run-log rotation per referenced protocol docs
- YAML frontmatter on new docs, summary freshness, staleness scan (audit skill)
- Inline attachment protocol for binary artifacts during project sessions
- Knowledge retrieval at skill activation: **automated via PreToolUse hook** (`_system/scripts/skill-preflight.sh`). Fires before every skill invocation for KB-eligible skills. Injects knowledge brief as `additionalContext`. No manual invocation required. See `_system/docs/solutions/behavioral-vs-automated-triggers.md`.
- Signal scan for compound connections: after creating any `#kb/` tagged note, scan `Sources/signals/`, `Sources/insights/`, and `Sources/research/` for notes with overlapping `#kb/` tags and `topics`. Present matches as potential compound connections. Budget-exempt.

**Always (workflow discipline):**
- Write acceptance criteria for every task
- Run tests before marking code complete
- Log decisions and major changes to run-log.md
- Run compound reflection at every phase transition (enforced via Context Checkpoint Protocol)
- Never skip phases within the active workflow
- Run code review at milestone boundaries and before merge in projects with repo_path (vault-check §23 enforces)

**Exception handling (structured recovery):**
When a tool call, skill invocation, or subagent fails, follow this chain — do not improvise:
1. **Retry** (transient failures only) — one retry with same parameters. If it fails again, move to 2.
2. **Degrade** — attempt a reduced-scope alternative (e.g., summary instead of full doc, direct tool instead of skill, smaller batch). Log what was lost.
3. **Escalate** — flag to user with: what failed, what was tried, what options remain. Do not silently absorb failures or retry indefinitely.

**Ask First (medium/high risk):**
- Changing architecture or adding dependencies
- Modifying schemas or migrations
- Sending external communications
- Creating files outside the vault structure
- Creating new primitives (skills, subagents, overlays) — see Primitive Creation Protocol in spec §3.5
- Writing medium-confidence compound patterns to `_system/docs/solutions/` — see spec §4.4
- Modifying CLAUDE.md, skill definitions, or overlay index

**Never:**
- Implement without a validated spec (for substantial work)
- Merge to main/production without gate checks
- Make medical, legal, or major financial decisions autonomously
- Load more than 10 source documents into a single skill invocation

## Project Archival
- Archive: user-initiated only. Precondition: clean working tree. Confirm → final
  run-log + compound → progress-log → update project-state (phase: archived,
  phase_before_archive: [previous phase]) → move to Archived/Projects/ → update
  companion note paths → vault-check → git commit
- Knowledge-base exception: projects with standalone KB artifacts (profiles, reference
  material, #kb/ tagged content) stay in Projects/ with phase: ARCHIVED — don't bury
  active knowledge graph content in Archived/. Flag KB candidates during confirmation.
- Reactivate: user-initiated only. Move back → update companion note paths → update
  project-state (restore phase from phase_before_archive) → run-log entry →
  progress-log → vault-check → git commit
- Claude never archives or reactivates autonomously — only suggests on explicit user approval
- Project docs do NOT carry a status field — directory location is authoritative
- See spec §4.6 for full procedure

## Completed Project Guard
- Do not add new design artifacts or tasks to a project with `phase: DONE` or `phase: ARCHIVED`
- If new work relates to a completed project, propose a new project and use `related_projects` to link them
- Maintenance artifacts (upgrade runbooks, hotfixes) may be added to DONE projects with a run-log note explaining the maintenance scope
- `related_projects` is an optional YAML list in project-state.yaml for cross-referencing related project names

## Compound Engineering
Structurally enforced at every phase transition via Context Checkpoint Protocol. Non-project sessions: evaluate at session end. Mid-phase: discretionary for notable insights. Route insights to: conventions → update existing docs, patterns → `_system/docs/solutions/`, primitive gaps → Primitive Proposal Flow. See spec §4.4.

## Skills & Agents
Skills in .claude/skills/ are loaded automatically when description matches.
Subagents in .claude/agents/ are spawned for heavy isolated work.
Overlays in _system/docs/overlays/ are loaded when activation signals match the overlay index.
New primitives: user can request creation at any time; compound step proposes
via Primitive Proposal Flow. All creation follows Primitive Creation Protocol —
Claude proposes definition, user approves before files are written.

## Overlay Routing
Overlay index loaded at session start: _system/docs/overlays/overlay-index.md
Skills with overlay check steps (systems-analyst, action-architect) match tasks against
the index's activation signals and load relevant overlays automatically.
User can also request any overlay explicitly.
Overlays add lens questions to the active skill — they don't replace it.
Overlays and _system/docs/personal-context.md don't count against the source document budget tiers.

## Subagent Validation
When subagent returns, apply provenance check: verify key constraints match full output, no interpretive claims introduced. If quality unclear, read full doc from vault and apply lightweight convergence check (2-3 dimensions from _system/docs/convergence-rubrics.md) before approval gate.

## Convergence
Code: binary grounding (tests, types, linting). Non-code: rubrics from `_system/docs/convergence-rubrics.md`. Aggressive stop conditions. See spec §4.2.

## Hallucination Detection
Tiered: always-on (confidence tagging, interpretation flagging), risk-proportional (provenance on consumed summaries), audit-time (deep analysis), monthly (human-grounded). See spec §4.8.

## Session Startup
A startup hook (`_system/scripts/session-startup.sh`) runs automatically on new and resumed sessions — git pull, vault-check, CLI probe. Claude acts on hook output silently (log rotation, overlay index, audit suggestions). Formatted startup summary displayed only when `/startup` is invoked.

## Session Management
Context management is autonomous — proactively manage /context, /compact, /clear
based on Context Checkpoint Protocol (_system/docs/context-checkpoint-protocol.md).
- To resume a project: start a fresh session and tell Claude to resume — vault-based
  state reconstruction reads run-log.md and rebuilds context from vault files.
  Preferred over `claude --resume` (conversation replay), which is fragile under context pressure.

### Session-End Sequence (REQUIRED — autonomous, do not wait for user prompts)
Load and follow the full sequence in `_system/docs/protocols/session-end-protocol.md`.
Steps: (1) log with compound evaluation, (2) failure-log if session went poorly (autonomous — no user prompt), (3) code review sweep — verify review entries for completed code tasks, (4) conditional commit, (5) git push.
- Project sessions → run-log.md. Non-project sessions → `_system/logs/session-log.md` (skip trivial lookups).
- Conditional commit: log-only delta → lightweight commit; substantial delta → flag to user; no changes → skip.
References: spec §6, §4.8.

## Bridge Dispatch Stage Output
When running as a dispatch stage (system prompt says "BRIDGE DISPATCH"), load and follow `_system/docs/protocols/bridge-dispatch-protocol.md` for stage output JSON.

## External Tools
- **MarkItDown:** CLI for binary-to-markdown conversion. Used by inbox-processor skill
  and inline attachment protocol. Invocation: `markitdown <filepath>`. See spec §7.9.
