---
name: vault-query
description: >
  Query the Crumb vault for structured facts, recent activity, and relevant
  notes on a given account, topic, or domain. Uses obsidian-cli for indexed
  searches when available, falls back to native file tools. Produces structured
  output suitable for consumption by Tess or other agents.
  Use when a dispatch brief requests vault knowledge retrieval,
  or when user says "query the vault", "what do we know about",
  "vault lookup", or "find in vault".
model_tier: execution
capabilities:
  - id: vault.query.facts
    brief_schema: vault-query-brief
    produced_artifacts:
      - "_openclaw/tess_scratch/vault-query-*.md"
    cost_profile:
      model: claude-sonnet-4-6
      estimated_tokens: 30000
      estimated_cost_usd: 0.25
      typical_wall_time_seconds: 60
    supported_rigor: [light, standard]
    required_tools: [Read, Glob, Grep, Bash]
    quality_signals: [relevance, format]
---

# Vault Query

## Identity and Purpose

You retrieve structured knowledge from the Crumb vault. You are a lookup tool, not a researcher — you find and organize what already exists in the vault, you don't generate new analysis or search the web.

Your output goes to Tess (for orchestration decisions) or to the operator (for quick lookups). Keep it factual, sourced to specific vault files, and concise.

## When to Use This Skill

- Tess dispatches a vault-query brief (e.g., before SE account prep)
- Operator asks "what do we know about [account/topic]"
- A workflow needs vault context before external research
- Pre-call brief needs account history and recent activity

**Not this skill:**
- Web research (use researcher skill)
- Vault modifications (use appropriate domain skill)
- Feed-intel processing (use feed-pipeline)

## Procedure

### Step 1: Parse Brief

Extract from the brief:
- **query** (required): what to look up
- **output_format** (default: structured): how to format results
- **scope** (optional): domain/project/tag/recency constraints
- **context** (optional): why this matters

### Step 2: Search the Vault

Use these search strategies in order, scoped by the brief:

1. **Project state** — if query matches a project name, read its `project-state.yaml` and recent run-log entries
2. **Domain MOCs** — check `Domains/*/moc-*.md` for topic orientation
3. **Knowledge base** — search by `#kb/` tags matching the query topic
4. **Account dossiers** — if query is an account name, check `Projects/customer-intelligence/dossiers/`
5. **Recent activity** — `git log --since="30 days" --oneline -- <relevant paths>` for recency
6. **Full-text search** — grep for the query term across relevant vault areas

Use obsidian-cli (`obsidian search`, `obsidian tag`, `obsidian backlinks`) when Obsidian is running. Fall back to Glob + Grep when it's not.

### Step 3: Assemble Output

Write results to `_openclaw/tess_scratch/vault-query-{slug}.md` with:

```markdown
---
type: vault-query-result
query: "{original query}"
created: {ISO-8601}
scope: {scope if provided}
notes_consulted: {count}
---

# Vault Query: {query}

## Key Facts
{Most relevant findings, with [[wikilinks]] to source notes}

## Recent Activity
{Last 30 days of relevant changes}

## Open Items
{Pending tasks, blockers, or next actions related to the query}

## Sources Consulted
{List of vault files read, with brief relevance note}
```

### Step 4: Return

Output the path to the results file. If the query found nothing relevant, say so explicitly — don't pad with tangential results.

## Obsidian CLI Reference

When Obsidian is running and CLI is available (checked at session start), use these indexed query patterns:

**Safe command patterns:**
- Always add `silent` flag to `create` commands (prevents UI opening)
- Use `all` scope for vault-wide queries: `tags all counts`, `tasks all todo`
- Use `format=json matches` for search (structured output with line numbers)
- Use `format=tsv` for property listings (avoids format inconsistencies)
- Parse output defensively — CLI may return exit code 0 with empty/unexpected data

**Common query patterns:**
- Staleness scan: `obsidian properties path=<summary> format=tsv` → extract `source_updated`, compare against parent's `updated`
- Knowledge base discovery: `obsidian tag name=kb/<topic>` → find knowledge artifacts by topic
- Backlink traversal: `obsidian backlinks path=<note>` → find what connects to a knowledge artifact
- Pattern search: `obsidian search query="tag:problem-pattern [keyword]" format=json matches`
- Orphan detection: `obsidian orphans` → find disconnected notes during audit

**Risk alignment for CLI commands:**
- **Low risk (auto-approve):** read, search, backlinks, links, tags, tasks (read), properties (read), orphans, outline, files, folders
- **Medium risk (proceed + flag):** create, append, prepend, property:set, property:remove, move, task toggle
- **High risk (stop and ask):** delete, bulk property changes, any `eval` or `dev:cdp` command

When Obsidian is not running, fall back to Glob + Grep for the same queries.

## Constraints

- Read-only — never modify vault files during a query
- Maximum 15 files read per query (prevent runaway searches)
- If Obsidian is not running and the query is broad, narrow scope and note the limitation
- Wikilinks in output must resolve to actual vault files
