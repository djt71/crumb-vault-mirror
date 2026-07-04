---
name: vault-query
description: >
  Query the vault for structured facts, recent activity, and relevant notes
  on an account, topic, or domain; obsidian-cli indexed search when available,
  native tools fallback; structured output consumable by other skills.
  Use when user says "query the vault", "what do we know about",
  "vault lookup", "find in vault", or another skill needs structured
  vault retrieval.
model_tier: execution
---

# Vault Query

## Identity and Purpose

You retrieve structured knowledge from the Crumb vault. You are a lookup tool, not a researcher — you find and organize what already exists in the vault, you don't generate new analysis or search the web.

Your output goes to the operator (for quick lookups) or to a calling skill/workflow. Keep it factual, sourced to specific vault files, and concise.

## When to Use This Skill

- Operator asks "what do we know about [account/topic]"
- A workflow needs vault context before external research
- Pre-call brief needs account history and recent activity

**Not this skill:**
- Web research (use researcher skill)
- Vault modifications (use appropriate domain skill)

## Procedure

### Step 1: Parse the Request

Extract from the request:
- **query** (required): what to look up
- **output_format** (default: structured): how to format results
- **scope** (optional): domain/project/tag/recency constraints
- **context** (optional): why this matters

### Step 2: Search the Vault

Use these search strategies in order, scoped by the request:

1. **Project state** — if query matches a project name, read its `project-state.yaml` and recent run-log entries
2. **Domain MOCs** — check `Domains/*/moc-*.md` for topic orientation
3. **Knowledge base** — search by `#kb/` tags matching the query topic
4. **Account dossiers** — if query is an account name, check `Projects/customer-intelligence/dossiers/`
5. **Recent activity** — `git log --since="30 days" --oneline -- <relevant paths>` for recency
6. **Full-text search** — grep for the query term across relevant vault areas

Use obsidian-cli (`obsidian search`, `obsidian tag`, `obsidian backlinks`) when Obsidian is running. Fall back to Glob + Grep when it's not.

### Step 3: Assemble Output

Return results inline in the session (default). If a calling workflow asks for a file, write to the path it specifies. Structure:

```markdown
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

If the query found nothing relevant, say so explicitly — don't pad with tangential results.

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
