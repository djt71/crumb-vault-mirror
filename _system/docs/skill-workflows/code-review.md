---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Code Review

Overview: Coordinates a two-reviewer panel (Claude Opus for architectural reasoning, Codex for tool-grounded verification) to review code diffs and synthesize actionable findings. Runs automatically at IMPLEMENT milestone boundaries or on manual request.

## /code-review

**Invoke:** Automatic at end of each IMPLEMENT milestone and before merge to main; manual when user says "review this code" or "check my implementation"

**Inputs:** Code diff (uncommitted changes, staged changes, or milestone range); project language and framework context; optionally, specific files to scope the review

**Outputs:** Review note at `{project}/reviews/{YYYY-MM-DD}-code-review-{scope}.md`; synthesis summary in conversation; git tag `code-review-{YYYY-MM-DD}` on reviewed commit; run-log entry with finding counts

**What happens:**
- Test gate runs first (type-checker + test suite) — review is blocked if either fails unless user explicitly waives
- Diff is generated and scoped (manual = `--unified=5`; milestone = `--unified=10` from last review tag)
- Dispatch subagent sends the diff to both reviewers: Opus via raw API, Codex via `codex exec` in read-only sandbox
- Findings are synthesized into consensus findings, unique findings, contradictions, and prioritized action items (must-fix / should-fix / defer)
- Safety gate scans diff for secrets/credentials before dispatch; halts and alerts if matched

## When It Runs

**Automatic:** Phase transition at end of IMPLEMENT (milestone boundary); before merge to main or release tag.

**Manual:** Any time user requests review, before committing substantial changes, or when code touches security boundaries or cross-service interfaces.

**Skip:** Non-executable docs only, or single-line obvious fixes. Config-only changes get a safety gate check but skip the full panel review.

**Review limit:** 3 rounds maximum per review cycle.
