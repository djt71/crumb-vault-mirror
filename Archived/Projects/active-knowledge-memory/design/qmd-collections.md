---
type: design-doc
domain: software
status: active
project: active-knowledge-memory
created: 2026-03-02
updated: 2026-03-02
tags:
  - kb/software-dev
  - retrieval
  - qmd
topics:
  - moc-crumb-architecture
---

# QMD Collection Configuration

## Collections

Four coarse collections map vault directories to QMD's indexed document store.

| Collection | Source Directory | Files | Content |
|------------|----------------|-------|---------|
| `sources` | `Sources/` | ~315 | Book digests, articles, video notes |
| `projects` | `Projects/` | ~317 | Specs, designs, run-logs, action plans |
| `domains` | `Domains/` | ~25 | MOCs, domain overviews |
| `system` | `_system/docs/` | ~72 | Solutions, protocols, conventions |

Total: ~729 documents, ~4,949 embedding chunks.

### Creation Commands

```bash
qmd collection add ~/crumb-vault/Sources --name sources --mask "**/*.md"
qmd collection add ~/crumb-vault/Projects --name projects --mask "**/*.md"
qmd collection add ~/crumb-vault/Domains --name domains --mask "**/*.md"
qmd collection add ~/crumb-vault/_system/docs --name system --mask "**/*.md"
qmd update && qmd embed
```

## Granularity Rationale

**Coarse (4 collections) over fine (per-project, per-domain).**

Reasons:
1. **BM25 scores better with a full index.** QMD's BM25 IDF calculation benefits from seeing the entire corpus — splitting into micro-collections skews relevance scores
2. **Cross-collection queries are the primary use case.** Session-start retrieval searches all collections; post-filtering to Sources/ and Domains/ handles KB scoping. Fine-grained collections would require multi-collection query logic for every invocation
3. **Collection count maps to maintenance surface.** 4 collections is one `qmd update` call. Per-project collections would require add/remove on project create/archive
4. **Artem's production setup uses 5 coarse collections** (5,700 docs) — validated at comparable scale

The retrieval wrapper (`knowledge-retrieve.sh`) searches all collections and applies KB-path filtering in post-processing — only Sources/ and Domains/ results appear in knowledge briefs. Project and system docs are indexed for completeness (future use cases, QMD mode evaluation) but excluded from proactive surfacing.

## Collection Scoping

QMD supports per-collection search via `-c <collection>`:

```bash
qmd search "systems thinking" -c sources -n 10 --json
```

Currently unused — all queries run against the full index for BM25 scoring advantages. May revisit if:
- Noise from project/system docs degrades result quality in future modes (semantic, hybrid)
- AKM-EVL evaluation shows collection scoping improves cross-domain recall

## Indexing Strategy

### Incremental Re-indexing

`qmd update` scans all collections for new, modified, and deleted files. Only changed files are re-indexed. Runtime: <5s at current scale.

**Session-end hook** (added during AKM-004): `qmd update` runs as step 4 of the session-end protocol (`_system/docs/protocols/session-end-protocol.md`). Non-blocking on failure — index staleness is acceptable for one session.

`qmd embed` creates vector embeddings for new/changed chunks. Runs after `qmd update`. Required for `vsearch` and `query` modes but not for `search` (BM25).

### Full Rebuild

Not needed for normal operation. `qmd cleanup` + `qmd update` + `qmd embed` for a clean rebuild if the index becomes corrupted or after major vault restructuring.

### Embedding Model

QMD bundles three models (auto-downloaded to `~/.cache/qmd/models/`):
- **embeddinggemma-300M** (~328MB) — embedding model, 900-token chunks with 15% overlap
- **Qwen3-Reranker-0.6B** (~640MB) — reranker for `query` mode
- **qmd-query-expansion-1.7B** (~1.7GB) — query expansion for `query` mode

All run locally on Metal (Apple Silicon GPU). No external API calls.

## Excluded Content

Directories NOT indexed:
- `_inbox/` — transient processing queue
- `_openclaw/` — agent scratch space, feed items
- `Archived/` — historical, low-signal content
- `_system/scripts/` — code, not knowledge
- `_system/logs/` — operational logs
- Attachment directories (`**/attachments/`) — binary files, not markdown

QMD's `--mask "**/*.md"` naturally excludes non-markdown files within indexed directories.

## Future Considerations

- **AKM-EVL** will test whether collection scoping (`-c sources`) improves recall for specific trigger types
- **AKM-009** may tune the result count requested per collection based on EVL data
- If vault grows significantly (>2,000 notes), evaluate whether splitting Sources/ into sub-collections (books, articles, profiles) improves ranking
- MCP server mode (deferred) would enable direct tool-based queries without Bash wrapping
