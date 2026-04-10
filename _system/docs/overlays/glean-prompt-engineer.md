---
type: overlay
domain: null
status: active
created: 2026-02-17
updated: 2026-02-17
tags:
  - overlay
  - glean
  - enterprise-search
---

# Glean Prompt Engineer

Expert lens for constructing optimal Glean queries and structuring Glean output
for ingestion into Crumb. Crumb cannot access Glean directly — this overlay
helps the user bridge between the two systems.

## Activation Criteria

Task involves any of: querying Glean, enterprise knowledge search, internal data
lookup at Infoblox, populating vault artifacts from enterprise sources,
customer intelligence gathering via Glean, Glean-to-Crumb data pipeline.

## Lens Questions

1. What specific information is needed from Glean, and what will Crumb do with the result? (Output format depends on downstream use.)
2. Is this a search query (finding specific documents/data) or an assistant query (synthesizing across sources)? Glean handles these differently.
3. Which Infoblox data sources most likely contain the answer? (Salesforce, Jira, Confluence, Slack, email, Drive?) Naming the source improves retrieval.
4. Does the query need temporal scoping? ("Last 6 months" vs. all-time matters.)
5. What structured output format does Crumb need? (Frontmatter fields, markdown table, sectioned prose?)

## Key Frameworks

**Prompt Construction:**
- Be specific about what, not just the topic. "Open support cases for Acme Corp in the last 90 days" beats "Acme Corp support."
- Name likely source systems: "Search Salesforce for..." or "Find in Confluence..."
- Lean into Glean's role-awareness — it personalizes based on your permissions.
- Request structured output: "Summarize in a table with columns X, Y, Z."
- Break multi-step research into sequential focused prompts. Glean retrieves better with narrow queries.

**Glean-to-Crumb Bridge:**
- Define the target Crumb artifact before querying. Know which sections map to which queries.
- Use consistent extraction templates so Glean output pastes into vault artifacts with minimal rework.
- For dossier population: run separate queries per section (company overview, tech stack, commercial position, support history).
- Evaluate returns: raw data for systems-analyst processing, or pre-synthesized for direct vault placement?
- Note source confidence: Glean cites sources — strong sourcing vs. thin coverage maps to Crumb's confidence conventions.

## Anti-Patterns

- Vague questions expecting Crumb-ready output. The bridge requires structuring on both sides.
- Treating Glean as a general-purpose LLM — it searches your org's indexed data, not the open web.
- Pasting raw Glean output into vault artifacts without reviewing accuracy, recency, and relevance.
- Forgetting Glean results are permission-scoped to your view — may not be the complete picture.
- One giant compound query when sequential focused queries give better retrieval.