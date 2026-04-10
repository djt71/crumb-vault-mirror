---
type: reference
domain: software
status: active
created: 2026-02-26
updated: 2026-02-26
tags:
  - codex
  - setup
---

# Codex CLI Setup — Prerequisites for Code Review Integration

## Install

```bash
npm i -g @openai/codex
codex --version  # verify
```

## Authenticate

Primary — ChatGPT login (uses Plus subscription quota):
```bash
codex login
# Follow browser flow — one-time, credentials cached at ~/.codex/auth.json
# Verify:
cd ~/openclaw/x-feed-intel && codex --sandbox read-only exec --ephemeral "echo hello"
```

Optional fallback — API key (pay-as-you-go when subscription quota exhausted):
```bash
# Add to ~/.config/crumb/.env alongside existing keys
echo 'export OPENAI_API_KEY="sk-..."' >> ~/.config/crumb/.env
```

Note: If `OPENAI_API_KEY` is set in `.env`, the dispatch agent uses it as
`CODEX_API_KEY` (API-key auth). If not set, Codex uses the cached ChatGPT
login. For normal usage, ChatGPT login is sufficient — no API key needed.

## Verify Read-Only Sandbox

```bash
cd ~/openclaw/x-feed-intel
codex --sandbox read-only exec --ephemeral \
  "Run npx tsc --noEmit and report any type errors. Then list the test files."
```

Codex should be able to:
- Read all source files
- Run `npx tsc --noEmit`
- Run `node --test` or equivalent
- NOT modify any files

## Create AGENTS.md (per repo)

Each repo that Codex reviews should have an `AGENTS.md` at root.
Codex loads this automatically before processing any prompt.

### x-feed-intel/AGENTS.md
```markdown
## Project
x-feed-intel: Automated X/Twitter intelligence pipeline.
TypeScript/Node.js. SQLite for state. Telegram for delivery.

## Test Runner
No unified test suite. Type check: `npx tsc --noEmit`
Build: `npx tsc` (compiles to dist/)

## Conventions
- camelCase for variables/functions, PascalCase for types/interfaces
- Explicit error handling — no swallowed promises
- All API keys from macOS Keychain via security CLI
- Paths use path.join, never string concatenation
```

### feed-intel-framework/AGENTS.md
```markdown
## Project
feed-intel-framework: Source-agnostic content intelligence framework.
TypeScript/Node.js. SQLite. Designed to replace x-feed-intel.

## Test Runner
`npx tsx --test` (TypeScript test files require tsx loader). 25 test suites.
Type check: `npx tsc --noEmit`

## Conventions
- camelCase for variables/functions, PascalCase for types/interfaces
- All public functions have JSDoc comments
- Source type as first parameter for multi-source functions
- Explicit error handling — no swallowed promises
```

## Keychain Entry (if using API key)

```bash
# Store OpenAI API key in Keychain (if not already in .env)
security add-generic-password -a "crumb" -s "openai-api-key" -w "sk-..." -U
```

The dispatch agent reads from `~/.config/crumb/.env`, not Keychain directly.
Ensure `OPENAI_API_KEY` is set in that file.

## Checklist

- [ ] `codex --version` returns current version
- [ ] `codex login` completed (ChatGPT browser flow)
- [ ] `codex --sandbox read-only exec` can run tsc in target repo
- [ ] AGENTS.md created in x-feed-intel and feed-intel-framework
- [ ] (Optional) OPENAI_API_KEY in ~/.config/crumb/.env for API-key overflow
