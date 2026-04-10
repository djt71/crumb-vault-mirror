---
type: research-note
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-19
project: crumb-tess-bridge
task: CTB-001
---

# CTB-001: Claude Code `--print` Mode Research

## Methodology

This research combines two sources:

1. **`--help` output analysis** — definitive for flag availability, syntax, and documented behavior
2. **Empirical tests** — a test script (`/private/tmp/print-mode-tests.sh`) was written but
   must be run manually from a terminal because Claude Code blocks recursive `claude` CLI
   invocations from within an active session (see Finding 0 below)

Claude Code version: tested against the CLI available at time of research (2026-02-19).
Help output captured successfully within the session.

---

## Finding 0: Recursive Invocation Restriction

**Discovery:** Claude Code's Bash tool blocks execution of any command containing `claude`
CLI invocations from within an active session. This applies to both direct commands
(`claude --print "..."`) and scripts that contain such commands (`bash script-with-claude.sh`).

**Implication for B4 architecture:** This is a **non-issue** for the bridge. The bridge runner
will be invoked by launchd as an external process, not from within a Claude Code session.
However, it means CTB-001 empirical testing must be done from a standalone terminal session,
not from within an interactive Claude Code session.

**Verdict:** No architectural impact. Testing methodology adjusted.

---

## 1. CLAUDE.md Loading

### From Documentation

The `--print` help text states:
> Print response and exit (useful for pipes). Note: The workspace trust dialog is skipped
> when Claude is run with the -p mode. Only use this flag in directories you trust.

The `--cwd` flag is not listed in help but the working directory context implies CLAUDE.md
loading follows the same discovery mechanism as interactive mode (working directory traversal).

### Test Command (run manually)

```bash
time claude --print "What project instructions do you see from CLAUDE.md? List the first 3 section headers you can identify." --cwd /Users/tess/crumb-vault
```

### Expected Behavior

CLAUDE.md should load from the working directory, since `--print` is described as a
non-interactive variant of the same session, and the trust dialog skip implies the
project context IS being loaded (just without the confirmation prompt).

### Verdict: **PENDING EMPIRICAL CONFIRMATION**

**Confidence: HIGH** that it loads — the trust-skip language implies project context is
processed, and `--cwd` sets the working directory for project detection.

---

## 2. Tool Access Matrix

### From Documentation

The `--tools` flag is available:
> `--tools <tools...>` — Specify the list of available tools from the built-in set.
> Use "" to disable all tools, "default" to use all tools, or specify tool names
> (e.g. "Bash,Edit,Read").

This confirms tools ARE available in `--print` mode. The `--allowedTools` and
`--disallowedTools` flags provide granular control:
> `--allowedTools, --allowed-tools <tools...>` — Comma or space-separated list of
> tool names to allow (e.g. "Bash(git:*) Edit")
> `--disallowedTools, --disallowed-tools <tools...>` — Comma or space-separated list of
> tool names to deny (e.g. "Bash(git:*) Edit")

### Test Commands (run manually)

```bash
# File read
time claude --print "Read the file /Users/tess/crumb-vault/Projects/crumb-tess-bridge/project-state.yaml and tell me the exact value of the phase field" --cwd /Users/tess/crumb-vault

# File write (to /tmp for safety)
time claude --print "Write the text 'hello from print mode' to /private/tmp/claude-print-test.txt then confirm the write by reading it back" --cwd /Users/tess/crumb-vault

# Bash execution
time claude --print "Run 'echo hello-from-print-mode' using bash and show me the output" --cwd /Users/tess/crumb-vault
```

### Verdict: **PENDING EMPIRICAL CONFIRMATION**

**Confidence: HIGH** — flags exist specifically for tool configuration in `--print` mode.
The critical question is what the **default permission behavior** is (see Finding 6).

---

## 3. MCP Server Loading

### From Documentation

The `--mcp-config` flag is available and `--strict-mcp-config` exists:
> `--mcp-config <configs...>` — Load MCP servers from JSON files or strings (space-separated)
> `--strict-mcp-config` — Only use MCP servers from --mcp-config, ignoring all other
> MCP configurations

This implies MCP servers from `.claude/settings.json` ARE loaded by default (otherwise
`--strict-mcp-config` would be unnecessary).

### Test Command (run manually)

```bash
time claude --print "List all MCP tools or servers you have access to. If you have none, say NONE." --cwd /Users/tess/crumb-vault
```

### Verdict: **PENDING EMPIRICAL CONFIRMATION**

**Confidence: HIGH** — the `--strict-mcp-config` flag specifically exists to override
default MCP loading, implying defaults load from project settings.

---

## 4. Session Startup Time

### Test Commands (run manually, 3 runs)

```bash
time claude --print "Say exactly: PONG" --cwd /Users/tess/crumb-vault
time claude --print "Say exactly: PONG" --cwd /Users/tess/crumb-vault
time claude --print "Say exactly: PONG" --cwd /Users/tess/crumb-vault
```

### Verdict: **PENDING EMPIRICAL MEASUREMENT**

**Expectation:** Cold start includes CLI initialization + CLAUDE.md loading + API round trip.
Likely 3-15 seconds for a trivial response, depending on model selection and API latency.
This is acceptable for the bridge use case (async file exchange, not real-time chat).

---

## 5. Allowable Flags (DEFINITIVE — from `--help`)

### Flags confirmed available with `--print`

| Flag | Purpose | Bridge Relevance |
|------|---------|-----------------|
| `--model <model>` | Select model (alias like 'sonnet' or full name) | **CRITICAL** — controls cost per bridge invocation |
| `--allowedTools <tools>` | Whitelist specific tools | **CRITICAL** — restrict bridge runner to Read, Write, Edit, Bash |
| `--disallowedTools <tools>` | Blacklist specific tools | Alternative to allowlist |
| `--tools <tools>` | Specify full tool set | Override default tool set entirely |
| `--system-prompt <prompt>` | Override system prompt | **CRITICAL** — inject bridge processing instructions |
| `--append-system-prompt <prompt>` | Append to default system prompt | **USEFUL** — add bridge context without replacing CLAUDE.md |
| `--max-budget-usd <amount>` | Cap API spend | **CRITICAL** — cost guardrail per invocation |
| `--output-format <format>` | text, json, stream-json | **USEFUL** — json mode for structured output parsing |
| `--json-schema <schema>` | Structured output validation | **VERY USEFUL** — enforce bridge response schema |
| `--permission-mode <mode>` | acceptEdits, bypassPermissions, default, dontAsk, plan | **CRITICAL** — see Finding 6 |
| `--dangerously-skip-permissions` | Bypass all permission checks | Available but NOT recommended |
| `--allow-dangerously-skip-permissions` | Enable skip-permissions as option | More conservative variant |
| `--no-session-persistence` | Don't save session to disk | **USEFUL** — bridge sessions are ephemeral |
| `--fallback-model <model>` | Auto-fallback on overload | **USEFUL** — resilience for bridge runner |
| `--cwd` (implicit via working directory) | Set working directory | **CRITICAL** — must be vault root for CLAUDE.md |
| `--add-dir <directories>` | Additional tool access directories | May need for `_openclaw/` access |
| `--mcp-config <configs>` | Load MCP servers | Can load bridge-specific MCP config |
| `--strict-mcp-config` | Ignore default MCP, use only specified | Isolate bridge from interactive MCP servers |
| `--disable-slash-commands` | Disable all skills | **USEFUL** — bridge doesn't need interactive skills |
| `--effort <level>` | low, medium, high | Cost optimization for simple operations |
| `--session-id <uuid>` | Specify session UUID | Traceability for bridge transcripts |
| `--include-partial-messages` | Stream partial chunks | Only with stream-json output |
| `--input-format <format>` | text or stream-json | **text** is default, sufficient for bridge |
| `--betas <betas>` | Beta API headers (API key only) | Not needed for consumer auth |

### Flags explicitly marked `--print` only

- `--fallback-model` — only works with `--print`
- `--max-budget-usd` — only works with `--print`
- `--output-format` — only works with `--print`
- `--no-session-persistence` — only works with `--print`
- `--include-partial-messages` — only works with `--print`

### Verdict: **YES — all required flags exist**

The flag surface area exceeds requirements. Notable capabilities:
- `--json-schema` enables structured output enforcement at the CLI level
- `--max-budget-usd` provides per-invocation cost caps
- `--permission-mode` provides non-interactive permission resolution
- `--append-system-prompt` allows bridge context injection without replacing CLAUDE.md governance

---

## 6. Permission Mode (DEFINITIVE — from `--help`)

### Available Permission Modes

```
--permission-mode <mode>  choices: acceptEdits, bypassPermissions, default, dontAsk, plan
```

| Mode | Behavior | Bridge Suitability |
|------|----------|-------------------|
| `default` | Standard interactive prompts | **UNSUITABLE** — blocks on permission prompts in `--print` |
| `acceptEdits` | Auto-accept edit operations, prompt for others | **PARTIAL** — may still block on Bash |
| `dontAsk` | Never prompt, deny anything that would need permission | **SAFE** — but may over-restrict |
| `bypassPermissions` | Skip all permission checks | **FUNCTIONAL** — but security concern |
| `plan` | Read-only, no writes allowed | **TOO RESTRICTIVE** — bridge needs to write outbox |

### Help text for `--print` mode

> Print response and exit (useful for pipes). Note: The workspace trust dialog is skipped
> when Claude is run with the -p mode. Only use this flag in directories you trust.

Key insight: `--print` skips the **trust dialog** but the help does NOT say it skips
**tool permission prompts**. This means `--print` in `default` permission mode would
likely hang waiting for interactive permission approval.

### Recommendation for Bridge (UPDATED — empirical findings)

For the bridge runner, the recommended configuration is:

```bash
cd /Users/tess/crumb-vault
claude --print \
  --tools "Read,Write,Edit,Bash,Glob,Grep" \
  --permission-mode dontAsk \
  --max-budget-usd 0.50 \
  "..."
```

Rationale (from Test 7 follow-up):
- **Do NOT use `bypassPermissions`** — it overrides both `--allowedTools` and `--disallowedTools`
- `--tools` controls tool **availability** (hard gate, survives all permission modes)
- `--permission-mode dontAsk` auto-approves within the available tool set without prompts
- `--max-budget-usd` caps runaway cost
- `--cwd` does not exist — use `cd` into vault directory before invoking

**Tool restriction model (empirically verified):**

| Flag | Layer | Survives bypassPermissions? |
|------|-------|---------------------------|
| `--tools` | Availability (hard) | YES — removes tools from session |
| `--allowedTools` | Permission (soft) | NO — bypass overrides it |
| `--disallowedTools` | Permission (soft) | NO — bypass overrides it; Claude routes around via Bash |

**Defense-in-depth stack:**
1. `--tools` limits available tools (hard gate)
2. `--permission-mode dontAsk` auto-approves within tool set
3. CLAUDE.md governance constrains what tools are used FOR
4. Schema-level operation allowlist constrains accepted operations

### Verdict: **YES — permission control is adequate**

`--tools` + `dontAsk` provides enforceable tool restriction for unattended operation.

---

## 7. Additional Findings

### 7a. Structured Output (`--json-schema`)

```
--json-schema <schema>  JSON Schema for structured output validation
```

This is highly valuable for the bridge. We can enforce the bridge response schema at the
CLI level, ensuring the `--print` output is always valid JSON matching our schema. This
reduces the need for post-processing validation in the bridge runner.

### 7b. Cost Control (`--max-budget-usd`)

Per-invocation budget caps are available. Combined with `--model` for model selection
and `--effort` for reasoning effort, we have three levers for cost optimization:

1. **Model selection:** `--model sonnet` for simple operations, `--model opus` for complex
2. **Effort level:** `--effort low` for lookups, `--effort high` for analysis
3. **Budget cap:** `--max-budget-usd 0.50` as safety net

### 7c. Session Persistence Control

```
--no-session-persistence  Disable session persistence - sessions will not be saved to disk
```

Bridge sessions are ephemeral by design (transcript saved to `_openclaw/transcripts/`).
Using `--no-session-persistence` avoids polluting the session history with bridge
invocations and reduces disk writes.

### 7d. Fallback Model

```
--fallback-model <model>  Enable automatic fallback when default model is overloaded
```

This is `--print` only and provides resilience. If the bridge uses Opus and Opus is
overloaded, it can fall back to Sonnet automatically.

### 7e. Stdin Pipe Support

The help shows `prompt` as an argument, and `--input-format` supports `text` (default)
and `stream-json`. For the bridge, we can either:
- Pass the bridge request as a CLI argument: `claude --print "process this request: ..."`
- Pipe it via stdin: `cat request.json | claude --print --cwd /Users/tess/crumb-vault`

The piped approach avoids shell escaping issues with JSON payloads.

---

## Candidate Bridge Runner Command (UPDATED — empirical findings)

```bash
#!/bin/bash
# Bridge runner — invoked by file watcher (launchd KeepAlive process)

VAULT="/Users/tess/crumb-vault"
REQUEST_FILE="$1"

cd "$VAULT"

claude --print \
  --tools "Read,Write,Edit,Bash,Glob,Grep" \
  --permission-mode dontAsk \
  --append-system-prompt "You are processing a bridge request from the Crumb-Tess bridge. Read the request file, validate it against the bridge schema, execute the allowed operation under full CLAUDE.md governance, and write the response to the outbox. Request file: $REQUEST_FILE" \
  --max-budget-usd 0.50 \
  --no-session-persistence \
  --model sonnet \
  --fallback-model haiku \
  --effort medium \
  --output-format json \
  --disable-slash-commands \
  "Process the bridge request at $REQUEST_FILE"
```

Key changes from initial design:
- `cd "$VAULT"` instead of `--cwd` (flag doesn't exist)
- `--tools` instead of `--allowedTools` (hard gate vs soft permission)
- `--permission-mode dontAsk` instead of `bypassPermissions` (respects tool restrictions)
- Removed `--disallowedTools` (doesn't survive `bypassPermissions`; `--tools` is the correct mechanism)

**Keychain note:** The API key must be available without interactive Keychain prompt.
Either export `ANTHROPIC_API_KEY` in the LaunchAgent plist EnvironmentVariables (from a
600-permission file) or grant "Always Allow" in Keychain Access.app.

---

## GO/NO-GO Assessment

### Verdict: **FULL GO** (empirically confirmed 2026-02-19)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| CLAUDE.md governance loading | **CONFIRMED** | Test 1: listed vault section headers, startup hook ran |
| Tool access (Read, Write, Bash) | **CONFIRMED** | Tests 2–4: all three tools executed successfully |
| Tool restriction | **CONFIRMED** | Test 7A/7D: `--tools` enforces hard availability gate |
| Non-interactive execution | **CONFIRMED** | `--permission-mode dontAsk` + `--tools` = auto-approve within restricted set |
| MCP server loading | **CONFIRMED (absent)** | Test 9: no MCP servers loaded. Use `--mcp-config` if needed. |
| Cost control | **CONFIRMED** | JSON output: $0.014/PONG, 26.8K cache tokens. `--max-budget-usd` available. |
| Structured output | **CONFIRMED** | Test 6: full JSON metadata (cost, usage, session_id, model breakdown) |
| Session isolation | **CONFIRMED** | Test 8: `--no-session-persistence` — no session files created |
| Startup time | **CONFIRMED** | 4.1–4.7s baseline, 7–8s one tool, 16.6s Bash reasoning |

### Errata

- `--cwd` does not exist. Working directory is set by `cd` before invocation.
- `bypassPermissions` overrides `--allowedTools` and `--disallowedTools`. Use `--tools` + `dontAsk` instead.
- Keychain may prompt for API key access. Must be resolved for unattended automation (see Keychain note above).

---

## Test Script Location

A comprehensive test script has been written to `/private/tmp/print-mode-tests.sh`.
Run it from a standalone terminal:

```bash
chmod +x /private/tmp/print-mode-tests.sh
/private/tmp/print-mode-tests.sh
# Results written to /private/tmp/print-mode-results.txt
```

The script tests all 9 capabilities and records timing data.

---

## Unknowns Resolved

| Unknown | Resolution |
|---------|-----------|
| U1 (Does `--print` load CLAUDE.md?) | **YES** — empirically confirmed (Test 1) |
| U2 (Does `--print` provide tool access?) | **YES** — Read, Write, Bash all confirmed (Tests 2–4) |
| U5 (What permission mode for non-interactive?) | **RESOLVED** — `--tools` (hard gate) + `--permission-mode dontAsk` |

## Unknowns Remaining

| Unknown | Status |
|---------|--------|
| U3 (Repeated automated invocations) | Deferred to CTB-011. Keychain prompt is a new U3 data point. |
| U4 (Telegram message formatting) | Resolved by CTB-002 |
| U7 (Session concurrency) | `--no-session-persistence` + flock in bridge runner addresses this |
