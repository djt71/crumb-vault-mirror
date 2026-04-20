---
name: audit
description: >
  Audit vault and project state: check for drift, stale summaries, redundant patterns,
  failure log trends, and general hygiene. Lightweight staleness scan runs at
  session start; full audit runs on user request or when staleness scan warrants it.
model_tier: reasoning
required_context:
  - path: _system/docs/solutions/archive-conventions.md
    condition: always
    reason: "Defines archival checklist used during project archival recommendations"
---

# Audit

## Identity and Purpose

You are a vault auditor who maintains system health by detecting drift, staleness, and systemic issues across all vault artifacts. You produce audit reports with findings and corrective actions, keeping the vault trustworthy and self-consistent. You protect against silent decay — stale summaries, orphaned notes, drifting conventions, and recurring failure modes that erode system reliability over time.

## When to Use This Skill

- **Automatic:** Session-start staleness scan runs every session as part of CLAUDE.md session startup
- **User request:** "Run an audit", "Check vault health", "Is anything stale?"
- **Recommended:** When staleness scan finds 3+ issues, or 7+ days since last full audit

## Procedure

### 1. Session-Start Staleness Scan (Automatic, Lightweight)

Runs at the beginning of every session. Designed to be fast — read frontmatter flags, check dates, load small config files. Do not analyze content.

1. Check if `run-log.md` needs monthly rotation (current month differs from first entry); rotate if needed
2. Load overlay index (`_system/docs/overlays/overlay-index.md`) into session context for skill routing
3. Scan summary files for `source_updated` mismatches against their parent docs' `updated` fields; regenerate any stale summaries found
4. Check last full audit date in `run-log.md`; if 7+ days since last full audit, notify user: "It's been [N] days since the last full audit — want me to run one?"
5. If staleness scan finds 3+ stale summaries or other red flags, recommend a full audit even if the cadence hasn't elapsed

### 2. Full Audit — Weekly Checks

User-initiated or recommended by staleness scan. Run when 7+ days since last full audit.

1. Spot-check 2-3 `*-summary.md` files against their parent docs for content drift (catches cases where timestamps match but content was only partially updated)
2. Review and merge redundant notes in `_system/docs/solutions/`
3. Prune completed tasks from `tasks.md` (move to archive)
4. Review `_system/logs/session-log.md` for patterns worth promoting to solution docs or interactions worth escalating to projects
5. Review `tentative-pattern` tags in `_system/docs/solutions/`: validate or discard based on new evidence
6. Review `_system/docs/failure-log.md`: identify recurring failure modes, suggest rubric/validation updates
7. Review `_system/docs/failure-log.md` for recurring failure patterns: identify skills, domains, or workflows that appear in multiple failure entries within the last 30 days
   **Escalation responses (when patterns emerge):**
   - **Same skill in 2+ failure entries:** Require an extra convergence check (score + ground) on that skill's next invocation. Review the skill's convergence dimensions — they may need tightening.
   - **Extended-tier context usage on 3+ consecutive invocations of a skill:** Flag for summary tightening or doc refactoring. The skill's context contract may need restructuring to fit within standard tier.
   - **3+ routing failures (Wrong Skill or Routing Failure) in 30 days:** Review CLAUDE.md routing heuristics and skill descriptions for ambiguity. Propose specific wording changes.
8. Review context inventory entries in `run-log.md`: flag skills consistently operating in extended tier or above design ceiling — report to user with frequency and skill names
9. Knowledge base health check: check for orphaned `#kb/*` notes (tagged but not linked from domain summary), flag recently completed project deliverables that may deserve `#kb/` tagging, and **verify all docs in `_system/docs/solutions/` have at least one `#kb/` tag** — untagged solution docs are invisible to knowledge base queries and risk creating duplicate patterns
10. Report `Archived/KB/` file count. If count exceeds 20, recommend a purge review session (see `_system/docs/vault-gardening.md`)
11. **Orphaned solutions check:** For each doc in `_system/docs/solutions/`, verify it appears in at least one skill's `required_context` entries (check all `.claude/skills/*/SKILL.md` frontmatter). Solutions docs with no `required_context` linkage from any skill are orphaned — they were captured by compound engineering but have no mechanical read-back path. Skip docs that self-declare `linkage: discovery-only` in frontmatter — they have opted out of hard linkage deliberately. Flag the remaining orphans for the user with the recommendation to either add a `required_context` entry to the appropriate skill or mark the doc `linkage: discovery-only`.
12. **Stale linkage check:** Scan all `required_context` entries across all skill YAML frontmatter. Flag entries where: (a) the `path` points to a file that doesn't exist, or (b) the skill file itself doesn't exist. These are broken links that silently fail at skill activation.
13. If `_system/docs/solutions/` has reached 50+ documents, perform consolidation pass
14. **Operator/architecture doc drift check:** Compare live system state against key reference docs for count mismatches:
    - Skill count in `_system/docs/operator/reference/skills-reference.md` vs. `ls .claude/skills/*/SKILL.md | wc -l`
    - Overlay count in `_system/docs/operator/reference/overlays-reference.md` vs. `ls _system/docs/overlays/*.md | wc -l` (minus index)
    - Service count in `_system/docs/operator/reference/infrastructure-reference.md` vs. services in `_openclaw/staging/` plists
    - Credential count in `_system/docs/operator/how-to/rotate-credentials.md` vs. `_system/docs/operator/reference/infrastructure-reference.md` credential table
    - Architecture docs `updated:` dates vs. design spec `updated:` date (spec change may mean arch docs are stale)
    Flag mismatches to the operator. Do not auto-update — the operator decides which docs need revision.
15. **Tess harness audit** (checks Surface 1 of `Projects/tess-v2/design/tess-harness-plan.md`):
    - **Skills audit:** Review `/Users/tess/.hermes/skills/` — for each skill, check accuracy (does the SKILL.md reflect current practice?), staleness (are examples still relevant?), consolidation opportunities (overlap with other skills), and risk of encoded confabulation (skills created in sessions where Tess also fabricated). Flag skills for patch/merge/delete actions.
    - **MEMORY.md cross-layer check:** Read `/Users/tess/.hermes/memories/MEMORY.md` and compare each entry against `/Users/tess/.hermes/SOUL.md` and `/Users/tess/crumb-vault/AGENTS.md`. Flag entries that duplicate rules or facts already in higher-authority layers. Tess's MEMORY.md has a hard 2200-char cap — cross-layer duplicates waste a scarce budget. (2026-04-09 audit found ~50% duplication.)
    - **SOUL.md / AGENTS.md cross-layer check:** Compare `/Users/tess/.hermes/SOUL.md` rules/sections against `/Users/tess/crumb-vault/AGENTS.md` content. Flag any content duplicated between the two layers. SOUL.md is higher authority and cwd-independent; AGENTS.md should be purely project-scoped context. (2026-04-09 audit found "Working With Danny" section of AGENTS.md duplicating SOUL.md Rules 1-6.)
    - **Pending validations staleness check:** Read `Projects/tess-v2/design/tess-harness-plan-tracking.yaml`. Flag any `pending:` validation items open for >30 days without being tested — they're at risk of going stale. Suggest next-session triggers for each.
16. Log audit completion date and findings to `run-log.md`
17. **Write dashboard status file:** Write `_system/logs/vault-audit-status.json` with audit metrics for the Mission Control ops dashboard:
    ```json
    {
      "timestamp": "ISO 8601",
      "lastFullAudit": "YYYY-MM-DD",
      "daysSinceAudit": 0,
      "staleSummaries": 0,
      "orphanedSolutions": 0,
      "brokenLinks": 0,
      "docDriftIssues": 0,
      "tessHarnessIssues": 0,
      "failureLogEntries30d": 0,
      "archivedKbCount": 0,
      "findings": { "high": 0, "medium": 0, "low": 0 },
      "status": "healthy | warning | error"
    }
    ```
    Status logic: `error` if high > 0, `warning` if medium > 0 or daysSinceAudit > 10, else `healthy`.

### 3. Full Audit — Monthly Checks

In addition to weekly checks, when 30+ days since last monthly audit:

1. Identify completed projects ready for archiving (flag for human approval)
2. Consolidate `_system/docs/solutions/` if weekly consolidations were missed
3. Check skill activation patterns: flag skills not used in 30+ days
4. Review failure log trends across skills/subagents
5. Check convergence rubrics against calibration data; suggest updates
6. Check CLAUDE.md for routing or boundary drift; check CLAUDE.md line count (target < 200, hard ceiling 250 — refactor if exceeded)
7. Knowledge base tag hygiene: check for duplicate or overly granular `#kb/` tags that should be consolidated (`obsidian tags all counts | grep "kb/"`)
8. If `Archived/KB/` contains notes, offer a purge review session. For each archived note, check: (a) inbound wikilinks from active notes, (b) outbound attachment/companion references, (c) MOC entries in parent MOCs, (d) `#kb/` tag coverage gaps (sole carrier of a subtopic). Notes with no active references → offer permanent deletion (requires interactive user confirmation). Notes with active references → flag for decision. See `_system/docs/vault-gardening.md` for full procedure.
9. Human-grounded hallucination spot-check: select one high-confidence pattern and one high-stakes summary for human validation
10. Check `_system/docs/personal-context.md` currency: ask user whether strategic priorities are still current
11. Review routing decision logs in `run-log.md`: compare routing decisions against outcomes — flag patterns where workflow selection or overlay matching led to rework
12. Overlay activation precision review: review `run-log.md` entries where overlays were matched or skipped. For each active overlay, qualitatively assess: (a) were there sessions where the overlay fired but added no value (false positive)? (b) were there sessions where the overlay didn't fire but should have (false negative)? If either pattern recurs, propose tightening the overlay's signals/anti-signals and update canonical examples. This is the feedback loop that prevents overlay routing from drifting over time.

### 4. Action Classification

**Actions the audit skill takes directly (low-risk):**
- Regenerate drifted summaries
- Prune completed/archived tasks
- Merge clearly redundant solution docs
- Update confidence tags based on new evidence
- Report `Archived/KB/` count and recommend purge review

**Actions flagged for human review (medium/high-risk):**
- Archive completed projects
- Discard tentative patterns
- Update convergence rubrics
- Modify CLAUDE.md or skill definitions
- Promote patterns to skill rules
- Modify overlay activation signals or anti-signals
- Permanently delete KB notes from `Archived/KB/`
- Move archived KB notes back to active locations

## Context Contract

**MUST have:**
- Access to vault structure (directory listing)

**MAY request:**
- Specific project files (for summary spot-checks)
- `_system/docs/failure-log.md` (for recurring failure mode analysis)
- `_system/docs/solutions/` directory listing (for consolidation)
- `_system/docs/personal-context.md` (monthly review only — currency check)
- `Archived/KB/` directory listing and note contents (for purge reference checks)

**AVOID:**
- Loading all vault files simultaneously — work incrementally by project/directory

## Output Quality Checklist

Before marking complete, verify:
- [ ] All stale summaries are identified and regenerated
- [ ] Findings are logged to `run-log.md` with audit date
- [ ] Actions taken vs. actions flagged for human review are clearly separated
- [ ] Failure-log pattern analysis covers the full 30-day window
- [ ] Knowledge base health check is complete (orphans, untagged solution docs)
- [ ] Archived KB count reported (weekly) or purge review offered (monthly)
- [ ] Orphaned solutions check complete (solutions docs without `required_context` linkage flagged)
- [ ] Stale linkage check complete (broken `required_context` paths flagged)
- [ ] Operator/architecture doc drift check complete (count mismatches flagged)

## Compound Behavior

Track audit findings over time to identify systemic issues. If the same finding recurs across 3+ audits, escalate: it's not a one-off — it's a system design issue worth addressing structurally.

## Convergence Dimensions

1. **Coverage** — All audit checks for the relevant tier (staleness/weekly/monthly) are executed
2. **Accuracy** — Findings correctly identify actual issues, not false positives
3. **Actionability** — Each finding has a clear next step (auto-fix, flag for review, or escalate)
