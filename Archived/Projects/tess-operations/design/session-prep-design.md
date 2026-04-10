---
project: tess-operations
type: design-note
domain: software
status: active
created: 2026-03-09
updated: 2026-03-09
tags:
  - intelligence
  - session-prep
  - tess
---

# Session Prep & Debrief — Design Note

Resolves open design questions for TOP-047 before prompt template
implementation. Covers pre-session context assembly (Crumb sessions),
customer meeting prep (last30days + vault dossiers), post-session debrief,
and the execution model for each.

TOP-046 (overnight research) is a sibling design concern — see
`overnight-research-design.md`. The connection point is `--emit=context`
from last30days, which serves both overnight watchlists and on-demand
meeting prep queries.

## Two Distinct Functions

TOP-047 combines two prep workflows that share infrastructure but differ
in trigger, audience, and output:

| Dimension | Crumb Session Prep | Customer Meeting Prep |
|-----------|-------------------|----------------------|
| Trigger | Telegram: "Prepping for [project]" | Telegram: "Meeting with [account] in 30 min" |
| Audience | Crumb (Claude Code session) | Operator (human, pre-meeting) |
| Output format | Structured context injection file (machine-readable) | Conversational brief (human-readable) |
| Output path | `_openclaw/inbox/session-context-<project>-<date>.md` | Telegram inline + `_openclaw/research/output/meeting-prep-<account>-<date>.md` |
| Data sources | Vault project state (run-log, tasks, project-state.yaml) | Vault dossier + last30days + FIF digest |
| Token ceiling | 20k (spec §11) | 20k |
| Model | Sonnet 4.6 | Sonnet 4.6 |

Post-session debrief is a third function (same task ID) but fires on a
different trigger — see §Debrief below.

---

## Crumb Session Prep (Anticipatory Session)

### Purpose

Tess pre-stages a context injection file so Crumb sessions start faster
with better context. The operator tells Tess which project, Tess reads
the vault, and produces a structured file Crumb can consume immediately.

### Trigger

On-demand via Telegram. Operator sends a message matching:
- "Prepping for [project-name]"
- "Crumb session in [N] min, [project-name]"
- "Session prep [project-name]"

Tess extracts the project name, validates it against `Projects/*/`, and
proceeds. If the project name doesn't match, Tess asks for clarification.

### Context Injection Schema (from spec §14)

Required sections, max 2000 tokens total:

```yaml
---
type: session-context
project: <project-name>
created: YYYY-MM-DD
skill_origin: tess-session-prep
---
```

```markdown
## Current State
- **Phase:** [from project-state.yaml]
- **Active task:** [from project-state.yaml active_task]
- **Next action:** [from project-state.yaml next_action]

## Last Session
- **Date:** [from run-log, most recent entry date]
- **Summary:** [1-2 sentences from run-log entry]
- **Handoff items:** [uncompleted items from last entry]

## Blockers
- [From run-log + cross-project-deps.md where this project is blocked]

## Recent Dispatch Results
- [Any bridge dispatch results in _openclaw/inbox/ referencing this project]

## Relevant Feed Intel
- [FIF items tagged with project-relevant topics, last 7 days]

## Vault Check Status
- [Any vault-check warnings relevant to this project's files]

## Suggested First Command
[Based on active_task and next_action — e.g., "Resume MC-067: read the
task acceptance criteria, then implement the adapter"]
```

### Data Gathering Sequence

1. Read `Projects/<project>/project-state.yaml`
2. Read last 2 entries from `Projects/<project>/progress/run-log.md`
3. Read `Projects/<project>/tasks.md` — extract active task + next pending
4. Scan `_system/docs/cross-project-deps.md` for rows where this project
   is blocked or blocking
5. Scan `_openclaw/inbox/` for dispatch results referencing this project
   (filename or frontmatter match)
6. Read most recent FIF digest files from
   `~/openclaw/feed-intel-framework/state/digests/` (last 24h). Extract items
   whose triage excerpts or matched_topics contain keywords from the project's
   `domain` and `tags` fields in project-state.yaml. This is keyword matching,
   not semantic — if the project is `feed-intel-framework` with domain
   `software` and tags `[pipeline, feed-intel]`, match digest items containing
   those terms. If no items match, omit the section rather than force weak
   matches. Signal-notes in `_system/signal-notes/` tagged with relevant
   `#kb/` subtags are a secondary source if digest matching is sparse.
7. Read `_system/logs/vault-check-output.log` — extract project-relevant
   warnings

### Execution Model

**On-demand, not cron.** Tess runs this as a reactive response to a
Telegram trigger — no cron scheduling needed. The session runs entirely
within the Telegram conversation context (Tess already has vault read
access).

**No wrapper orchestration needed** (unlike TOP-046). The data sources
are all local vault files — no external tool invocations, no subprocess
timeouts. Tess reads files and synthesizes. Simple enough for a single
LLM session.

### Output

Written to `_openclaw/inbox/session-context-<project>-<date>.md`.

Crumb's session startup hook can check for this file and include it as
additional context. Until that automation exists, the operator manually
references it or pastes the key points. The file persists for the session
day and is overwritten if prep runs again for the same project.

### Convergence

- Max 2000 tokens output (spec constraint)
- Read at most 5 vault files per prep (run-log, tasks, project-state,
  cross-deps, vault-check-output)
- Wikilinks must resolve to actual vault paths — no hallucinated links
- If run-log is >200 lines, read only the last 50

---

## Customer Meeting Prep

### Purpose

Before a customer meeting, Tess assembles a brief combining vault
intelligence (dossier, signal-notes, FIF history) with fresh external
context (last30days `--emit=context`). The output is conversational —
optimized for the operator to skim in 5 minutes before walking in.

### Trigger

On-demand via Telegram:
- "Meeting with [account] in [N] min"
- "Prep for [account] meeting"
- "What should I know about [account] before my call?"

Tess extracts the account name, matches it against known dossiers in
`Projects/customer-intelligence/dossiers/`, and proceeds.

**Account name matching:** Tess does LLM-level fuzzy matching — the operator
says "ACG" or "Auto Club" and Tess matches it to `auto-club-group.md`. This
works at ~25 accounts without an alias map. The dossier directory listing is
small enough to include in the Telegram session context, so Tess can scan
filenames directly. If the account count grows beyond ~50, add a `slug-aliases`
section to each dossier's frontmatter (e.g., `aliases: [ACG, "Auto Club"]`)
and build a lookup in the wrapper script.

### Data Sources

| Source | What It Provides | Priority |
|--------|-----------------|----------|
| Vault dossier | Account context, relationship history, tech stack, org structure | Required |
| SE inventory notes | Recent engagement, cadence status, open actions | Required |
| last30days `--emit=context` | Fresh external signal — news, social, community mentions | If validated (see overnight-research-design.md §last30days) |
| FIF signal-notes | Promoted intelligence items tagged to this account | If available |
| Daily attention artifact | Whether this account appears in today's Focus items | Ambient |

### Execution Model

**Option (a): Wrapper orchestrates external tools, Tess synthesizes.**

Same pattern as TOP-046. A lightweight script handles external data
gathering before launching the Tess session:

```
meeting-prep.sh <account-name>
  1. Look up dossier path: Projects/customer-intelligence/dossiers/<slug>.md
  2. IF last30days validated AND account has watchlist topic:
     - Run: python3 /Users/openclaw/.claude/skills/last30days/scripts/last30days.py "<account>" --emit context --include-web > /tmp/meeting-prep-context.txt
     - Timeout: 120s
  3. Gather vault files:
     - Dossier content
     - Relevant SE inventory section
     - FIF signal-notes matching account (last 30 days)
  4. Launch Tess session with gathered files as context
  5. Tess synthesizes → writes brief + delivers inline to Telegram
```

**Why wrapper:** last30days is an external Python process that may hang
or fail. Isolating it from the Tess session means a last30days timeout
doesn't burn LLM tokens. If last30days fails or returns no signal, Tess
still produces a useful brief from vault data alone.

**Alternative for quick requests:** If the operator just wants the vault
dossier summarized (no external research), Tess can handle it entirely
in-session without the wrapper. The wrapper only fires when external data
gathering is requested or when the account has an active last30days
watchlist.

### Output Format

**Telegram inline delivery** (primary) — the operator reads it in the
chat before the meeting. Keep it scannable.

**Vault copy** (secondary) — written to
`_openclaw/research/output/meeting-prep-<account-slug>-<date>.md` for
reference and potential attention-manager surfacing.

```markdown
# Meeting Prep — [Account Name] — YYYY-MM-DD

## Quick Context
[2-3 sentences: who they are, relationship status, last interaction]

## Recent Intelligence
- [Signal 1 — source attribution]
- [Signal 2 — source attribution]
- [Signal 3 — source attribution]

## Key People
[Names, titles, last interaction date — from dossier]

## Open Items
[Action items, pending proposals, follow-ups — from SE inventory + dossier]

## Talking Points
[3-5 suggested conversation topics based on intelligence + relationship context]

## External Signal (last30days)
[If available: compact snippet from --emit=context. If not: "No fresh
external signal. Vault intelligence only."]
```

### Frontmatter

```yaml
---
type: meeting-prep
account: <account-name>
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
skill_origin: tess-meeting-prep
---
```

### Token Budget

20k ceiling. Breakdown:
- Dossier read: ~5k (some are large)
- SE inventory section: ~1k
- FIF signal-notes: ~3k
- last30days context: ~2k (--emit=context is designed for compactness)
- Synthesis overhead: ~5k
- Output: ~2k
- Headroom: ~2k

The original estimate of 30k had 12k unused headroom — 40% slack. 20k is
sufficient for all input sources. If a specific dossier exceeds expectations,
the convergence rule (max 5 sources, ≤2000 token output) constrains the
session naturally.

### Convergence

- Max 5 sources consulted (dossier + SE inventory + FIF notes + last30days
  + daily attention)
- Output ≤2000 tokens (Telegram readability constraint)
- If dossier doesn't exist for the account, say so — don't hallucinate
  one. Offer to create it.
- If last30days returns no signal, note it and proceed with vault-only brief

---

## Post-Session Debrief

### Purpose

After a Crumb session, Tess reads the updated run-log, summarizes what
happened, identifies handoff items, and sends a Telegram summary. This
closes the loop on the session prep file.

### Trigger

Git push webhook on the crumb-vault repo. Tess detects that a session
just ended by checking for new run-log entries since the last session-
context file was written.

**Fallback trigger (until webhooks are implemented):** Heartbeat polling
checks two conditions: (1) run-log mtime is newer than the most recent
session-context file's mtime for that project, AND (2) the run-log has
new content since the last debrief check (tracked via a cursor file at
`_openclaw/state/last-run/debrief-<project>`). This prevents false
triggers from manual edits, vault gardening, or non-session run-log
changes.

### Data Sources

1. `Projects/<project>/progress/run-log.md` — most recent entry
2. The session-context file from pre-session (if one was generated)
3. `git log --oneline -5` — recent commits from the session

### Output

Telegram message to `#crumb-dispatch` topic (or general if topics not
yet configured):

```
Session complete: [project-name]
- Completed: [task IDs and summaries]
- In progress: [current state]
- Handoff: [items for next session]
- Duration: [if derivable from run-log timestamps]
```

If a session-context file exists, compare the "Suggested First Command"
with what actually happened — note divergence (not as criticism, as data
for future prep accuracy).

### Execution Model

Reactive to webhook/heartbeat. No wrapper needed — Tess reads vault
files within her existing session context.

### Debrief Output

No vault file written. Telegram-only. The run-log already captures the
session record — the debrief is a notification layer, not a persistence
layer.

---

## Dependencies

| Dependency | Status | Impact |
|-----------|--------|--------|
| TOP-014 (M1 gate) | Done | Tess operational baseline required |
| Vault dossiers | Partial (customer-intelligence project) | Meeting prep quality scales with dossier completeness |
| last30days validation | Pending (overnight-research-design.md) | Meeting prep external signal gated on validation |
| TOP-027/028 (calendar) | Pending | Calendar context in session prep + meeting prep |
| Webhook infrastructure | Not started | Debrief trigger; heartbeat polling as interim |
| Telegram topics | Not started | Debrief routing to #crumb-dispatch |

### Interaction with XD-008

`XD-008` blocks MC Agent Activity session cards on TOP-047. The session-
context file and debrief output provide the structured data MC needs for
session cards — but this is a downstream consumer, not a blocker for
TOP-047 itself.

### Cross-Project Dependency Assessment

**No new XD entries needed.** Evaluated:
- **Dossier schema (customer-intelligence):** Stable — project is in ACT
  phase, dossier template is in production use with ~10 accounts populated.
  Schema changes are unlikely. Not a blocking dependency.
- **MC session cards (XD-008):** Already tracked. Downstream consumer, not
  a blocker.
- **last30days:** External tool, not a cross-project dependency — it's a
  candidate data source gated on validation, not a project deliverable.
- **Webhook infrastructure:** Intra-project dependency (tess-operations),
  not cross-project.

---

## Implementation Sequence

1. **Crumb session prep** — highest value, simplest. All data sources are
   vault-local. No external tool dependencies. Prompt template + Telegram
   trigger recognition.

2. **Customer meeting prep (vault-only)** — dossier + SE inventory + FIF
   notes. No last30days dependency. Useful immediately.

3. **Customer meeting prep (+ last30days)** — add external signal after
   last30days validation gate passes.

4. **Post-session debrief** — requires webhook or heartbeat polling
   infrastructure. Lower urgency since run-logs already capture session
   state.

---

## Cross-Project References

| Artifact | Project | Relevance |
|----------|---------|-----------|
| `overnight-research-design.md` | tess-operations | last30days integration, --emit=context pattern |
| `dispatch-protocol.md` | crumb-tess-bridge | Bridge dispatch for escalation from meeting prep |
| `dossier-template.md` | customer-intelligence | Dossier schema for meeting prep reads |
| `cross-project-deps.md` | system | XD-008 (session cards depend on TOP-047) |
| Anticipatory Session schema | tess-chief-of-staff-spec §14 | Context injection schema origin |
