---
type: solution
domain: software
status: active
track: bug
linkage: discovery-only
created: 2026-03-16
updated: 2026-04-04
topics:
  - moc-crumb-operations
tags:
  - kb/software-dev
  - pattern
  - claude-code
  - automation
---

# claude -p CWD Sensitivity

## Symptoms

LLM returns conversational agent responses ("I need the...", tool descriptions, skill listings) instead of structured output (JSON arrays, scores, etc.) when `claude -p` is invoked.

## Root Cause

`claude -p` (print mode) loads project context — CLAUDE.md, skills, tools, memory — based on the working directory at invocation time. When called from within a directory tree that contains a CLAUDE.md (e.g., the crumb-vault), the model receives the full agent system prompt, which overrides or drowns out any `--system-prompt` argument.

## Resolution

Set `cwd` to a directory outside any CLAUDE.md project tree:

```javascript
execSync(`claude -p --model <model> --system-prompt "$(cat ${promptFile})"`, {
  cwd: '/path/to/repo/without/claudemd',  // no CLAUDE.md here
  // ...
});
```

Or in bash, `cd` to the target repo before invoking `claude -p`.

## Resolution Type

config

## Evidence

Discovered during opportunity-scout OSC-016 validation (2026-03-16). Haiku triage and Sonnet digest ranking both failed when `run-pipeline.sh` was invoked from `~/crumb-vault/` (which has CLAUDE.md). Fixed by setting `cwd` in Node's `execSync` to the opportunity-scout repo root.

## Counterexample

When the target repo intentionally has its own CLAUDE.md with structured output instructions, CWD sensitivity is a feature not a bug — the local CLAUDE.md governs the session correctly.
