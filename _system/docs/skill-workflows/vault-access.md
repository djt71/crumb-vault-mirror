---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Vault Access

Two skills handle vault access: `obsidian-cli` provides the low-level indexed query interface, and `vault-query` is a higher-level lookup skill that produces structured output for Tess or the operator.

## Skills in This Workflow

### /obsidian-cli
**Invoke:** Description match — any indexed vault operation (search, backlinks, tags, tasks, properties, orphans)
**Inputs:** A query or operation to perform; optional scope (project path, domain, tag prefix)
**Outputs:** CLI query results — raw structured output (JSON, TSV, or plain) passed to the calling skill
**What happens:**
- Verifies CLI availability; falls back to file tools if Obsidian is not running
- Executes scoped CLI commands using safe patterns (silent flag, format flags, no unbounded searches)
- Routes write-adjacent operations through risk alignment (create/move = medium; delete = high)

### /vault-query
**Invoke:** Description match — "query the vault", "what do we know about", "vault lookup", or Tess dispatch brief
**Inputs:** A query term; optional scope (domain, tag, recency), output format
**Outputs:** Structured markdown file at `_openclaw/tess_scratch/vault-query-{slug}.md` with Key Facts, Recent Activity, Open Items, and Sources Consulted
**What happens:**
- Parses brief for query, scope, and format
- Searches in order: project state → domain MOCs → #kb/ tags → account dossiers → git recency → full-text grep
- Writes results file and returns the path; reports explicitly if nothing found

## When to Use Which

| Need | Use |
|------|-----|
| Another skill needs vault index access (backlinks, tags, orphans, staleness) | `obsidian-cli` |
| Operator or Tess wants a knowledge brief on an account, topic, or project | `vault-query` |
| Direct file read/write, bulk text ops, Obsidian not running | Native file tools (Read, Grep, Glob) — no skill needed |
| Pre-call account prep, dispatch brief requiring vault context | `vault-query` |

`obsidian-cli` is a query primitive — consumed by other skills. `vault-query` is the end-user-facing lookup skill that uses `obsidian-cli` internally when available.
