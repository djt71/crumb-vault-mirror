---
type: review
review_type: code
review_mode: diff
scope: manual
project: feed-intel-framework
domain: software
language: shell
framework: null
diff_stats:
  files_changed: 7
  insertions: 549
  deletions: 2
skill_origin: code-review
created: 2026-03-01
updated: 2026-03-01
status: active
reviewers:
  - codex/gpt-5.3-codex
config_snapshot:
  curl_timeout: 120
  codex_timeout: 180
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  anthropic:
    http_status: 400
    latency_ms: 300
    attempts: 1
    error: "Credit balance too low — billing error, non-retryable"
    token_usage:
      input_tokens: 0
      output_tokens: 0
    raw_json: reviews/raw/2026-03-01-code-review-manual-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 286699
    tools_run:
      - "bash -n session-startup.sh vault-check.sh"
      - "shellcheck (not installed)"
      - "bash vault-check.sh"
      - "bash session-startup.sh"
      - "rg (file discovery, pattern search)"
      - "nl -ba (source inspection)"
      - "find (script discovery)"
      - "ls -la (file listing)"
    token_usage:
      input_tokens: 863515
      cached_input_tokens: 754304
      output_tokens: 6061
    jsonl_log: reviews/raw/2026-03-01-code-review-manual-codex.jsonl
    raw_text: reviews/raw/2026-03-01-code-review-manual-codex.txt
tags:
  - review
  - code-review
---

# Code Review — Feed Intel Pipeline Phase 1 (Manual)

**Scope:** 7 files changed, +549/-2 lines
**Reviewers:** 1 dispatched (Codex), 1 failed (Anthropic — billing)
**Date:** 2026-03-01

## Anthropic (Claude Opus 4.6) — SKIPPED

Dispatch failed with HTTP 400: "Your credit balance is too low to access the Anthropic API."
This is a billing issue, not a model or prompt problem. Non-retryable.

Raw error response: `reviews/raw/2026-03-01-code-review-manual-anthropic.json`

## Codex (GPT-5.3-Codex)

**Latency:** 287s | **Tools executed:** 22 | **Tokens:** 863,515 in (754,304 cached) / 6,061 out

### Tool Execution

Codex ran the following verification before reviewing:

1. **Syntax check:** `bash -n` on both `session-startup.sh` and `vault-check.sh` -- PASSED
2. **Shellcheck:** Not installed on host; skipped
3. **Vault-check.sh:** Failed in read-only sandbox (`mktemp` blocked by sandbox policy -- expected)
4. **Session-startup.sh:** Ran successfully, exercised the new feed-intel scanning code
5. **Source inspection:** Read actual feed-intel inbox files to verify frontmatter field positions
6. **Script discovery:** Checked for `feed-inbox-ttl.sh` (referenced in SKILL.md, confirmed missing)

### Findings

- **[CDX-F1] SIGNIFICANT** -- `session-startup.sh:170-171` -- Tier classification reads only `head -15` of each feed file. If frontmatter grows past 15 lines, `recommended_action`/`confidence` may be missed. Fix: Parse the full YAML frontmatter block between `---` delimiters.

- **[CDX-F2] MINOR** -- `session-startup.sh:172-174` -- Field parsing depends on exact `key: value` formatting (`awk -F': '`). Minor YAML variation can produce empty parsed values. Fix: Use a frontmatter extractor like vault-check.sh style, or parse with a YAML-aware helper.

- **[CDX-F3] SIGNIFICANT** -- `vault-check.sh:1462,1477` -- Signal-note required subfield checks are not scoped to `source:`/`provenance:` blocks. A malformed note can pass validation if matching keys exist elsewhere in frontmatter. Fix: Parse YAML structure or anchor checks to indentation/context.

- **[CDX-F4] SIGNIFICANT** -- `vault-check.sh:1501` -- Signal-note scan only searches `Sources` and `Projects`. A mislocated `type: signal-note` file under other paths (Domains, _system, Archived) will be missed entirely. Fix: Scan the whole vault with known excludes.

- **[CDX-F5] MINOR** -- `vault-check.sh:1495` -- `kb/` tag validation is a plain substring search. False positives possible from non-tag fields/comments. Fix: Validate at least one item under `tags:` matches `^\s*-\s*kb/`.

- **[CDX-F6] MINOR** -- `vault-check.sh:1453,1459` -- Validation checks presence of `schema_version` and `source_type` but not allowed values. Schema drift won't be caught early. Fix: Enforce `schema_version: 1` and validate `source_type` against documented enum.

- **[CDX-F7] SIGNIFICANT** -- `SKILL.md:79-80` -- Skill references TTL cron purge behavior (Tier 3: "TTL cron purges after 45 days") but `_system/scripts/feed-inbox-ttl.sh` does not exist. Fix: Add the script or mark TTL handling as planned/future.

- **[CDX-F8] STRENGTH** -- `session-startup.sh:184,309` -- Startup surfaces feed-intel totals and tier split in both machine-readable and human summary output. Good observability.

- **[CDX-F9] STRENGTH** -- `vault-check.sh:1443,1447` -- Location guard for signal-notes in `Sources/signals/` is explicit and clear. Matches design intent.

### Category Notes (No Issues)

- **Security:** No injection or secret-handling issues in this diff
- **Type safety:** N/A for bash/markdown
- **Performance:** No bottlenecks for expected inbox sizes
- **Test coverage gap:** No automated tests added for tier parsing or signal-note schema checks

### Summary

0 CRITICAL, 4 SIGNIFICANT, 3 MINOR, 2 STRENGTH
