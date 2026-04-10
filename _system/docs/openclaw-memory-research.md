---
type: reference
domain: software
status: active
created: 2026-02-27
updated: 2026-02-27
source: ChatGPT deep research
tags:
  - openclaw
  - automation
topics:
  - moc-crumb-operations
---

# Memory Failures in OpenClaw Agents and How to Diagnose and Fix Them

## Executive summary

“Agents forgetting instructions” in entity["organization","OpenClaw (agent framework)","local-first agent runtime"] is often not a single bug; it is usually one (or several) of these predictable mechanisms: (a) **the session is fresh** and the agent never reloaded durable instructions/memories, (b) **the instructions were never persisted** to disk, (c) **context management altered what the model sees** (compaction, truncation, pruning, or sub-agent prompt minimization), or (d) **retrieval is failing or stale** (index not updated, embeddings misconfigured, plugin/backend failures). citeturn33view0turn5view0turn9search2turn3view0turn32view0turn22view3

OpenClaw’s default posture is **transparent, file-first memory**: Markdown files in the agent workspace are the source of truth, and “memory search” is a derived index (rebuildable but potentially stale). This is powerful, but it implies a strict operational contract: **if it must persist, it must be written to a file**, and if it must be recalled reliably, **retrieval must be configured, healthy, and routinely validated**. citeturn9search2turn33view0turn6view0turn22view3

Among the four systems you asked about:

- **QMD** (via OpenClaw’s experimental `memory.backend="qmd"`) is a *local-first hybrid retrieval sidecar* (BM25 + vectors + reranking + query expansion), aimed at improving recall/precision versus simple embeddings-only search. It adds moving parts (Bun/SQLite/extensions/model downloads), but OpenClaw includes explicit fallback behavior when the QMD subprocess fails. citeturn23view1turn23view2turn19view0turn20view0turn31view0  
- **Mem0** is an *externalized “memory layer”* that captures and recalls memories automatically (auto-capture after, auto-recall before), with published benchmark claims (e.g., LoCoMo) but also visible community dispute/replication concerns in the broader ecosystem. Its OpenClaw plugin provides explicit knobs like `topK` and `searchThreshold`, and supports cloud or self-hosted (“open-source”) mode. citeturn12view0turn13search0turn10view1turn13search6  
- **Cognee** provides a *knowledge-graph-driven memory engine*; the OpenClaw plugin syncs Markdown memory files to Cognee with hash-based change detection and injects graph-derived recall before runs. The Cognee team also published a research paper centered on optimizing KG↔LLM interface hyperparameters across multi-hop QA benchmarks. citeturn24view0turn15search0turn15search3  
- **Obsidian** is not (by itself) a retrieval engine; it is a *storage substrate* (a vault is a local folder of Markdown files). It is useful as a durable, inspectable memory corpus for OpenClaw, but retrieval quality still depends on OpenClaw’s indexing/backends. Operationally, Obsidian’s sync/conflict model becomes part of your agent-memory threat surface (conflicts, partial sync, multi-sync “fights,” etc.). citeturn17search0turn17search2turn17search3turn17search21

A key pushback on a common assumption: **“persistent memory” is not the same thing as “the model will remember.”** OpenClaw’s own templates explicitly state you wake up fresh each session and continuity “lives in these files.” citeturn33view0turn33view1turn9search2

## Background on OpenClaw memory models

OpenClaw distinguishes *context* (what the model sees in a single run) from *memory* (what persists across runs). Context includes the OpenClaw-built system prompt, session history, tool calls/results, and injected workspace bootstrap files. citeturn5view1turn5view0

OpenClaw’s memory model has three layers:

1. **Workspace bootstrap “identity + instructions”**: On every run, OpenClaw injects key workspace files under “Project Context” (e.g., `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `USER.md`, and optionally `MEMORY.md`). This is the primary method for persistent *instructions*, but it consumes tokens and is subject to truncation caps (`bootstrapMaxChars`, `bootstrapTotalMaxChars`). citeturn5view0turn5view1turn6view0turn4search14  
2. **Durable Markdown memory**: By default, day-to-day notes live in `memory/YYYY-MM-DD.md` and longer-term curated facts can live in `MEMORY.md` (main/private session only). OpenClaw is explicit that Markdown files are the source of truth and the model only “remembers” what is written to disk. citeturn9search2turn6view0turn33view0  
3. **Derived retrieval**: The default memory plugin builds a per-agent SQLite index over `MEMORY.md` and `memory/**/*.md` and serves `memory_search` snippets and `memory_get` targeted reads. Index freshness is eventual (watchers mark dirty; background sync is asynchronous; searches do not necessarily block on indexing). citeturn22view3turn22view0turn21view3

Two context-management features can make “forgetting” feel worse (even when persistence is correct):

- **Compaction**: When the session approaches the model’s context window, OpenClaw summarizes older history into a compact summary entry. Compaction is inherently lossy, and it persists into session history. OpenClaw can run a *silent memory flush turn* before compaction to encourage writing durable notes to disk. citeturn3view0turn21view0turn23view0  
- **Session pruning**: For certain providers (notably Anthropic-family calls), OpenClaw may prune old tool results from the *in-memory prompt* before a call to reduce cache write costs and token pressure. This does not rewrite the on-disk transcript, but it does change what the model can “remember” from tool outputs at that moment. citeturn32view0

```mermaid
flowchart TB
  subgraph Storage[Durable storage]
    WS[Workspace files\nAGENTS.md / SOUL.md / USER.md / TOOLS.md]
    MMD[MEMORY.md (curated)]
    DLY[memory/YYYY-MM-DD.md (daily logs)]
    OBS[Obsidian vault folder (optional)]
  end

  subgraph Retrieval[Retrieval / indexing]
    CORE[Default memory plugin\nSQLite + embeddings (+ optional BM25)]
    QMD[QMD sidecar\nBM25 + vectors + rerank + expansion]
    MEM0[Mem0 external store\n(auto-capture/recall)]
    COG[Cognee engine\n(graph + vector)]
  end

  subgraph Context[Prompt/context assembly]
    SP[OpenClaw-built system prompt\n+ injected bootstrap files]
    HIST[Session transcript\n(+ compaction summaries)]
    TOOLS[Tool calls/results\n(+ pruning)]
  end

  Storage --> Retrieval --> Context
  WS --> SP
  MMD --> SP
  DLY --> CORE
  OBS --> CORE
  OBS --> QMD
  DLY --> QMD
  DLY --> COG
  MMD --> COG
  HIST --> Context
```

## Detailed profiles of the memory systems

### Comparison table

| System | Persistence model | Retrieval method | Practical capacity constraints | Latency character | Common failure modes | Recommended fixes / mitigations |
|---|---|---|---|---|---|---|
| OpenClaw default memory (Markdown + `memory_search`) | Markdown is source of truth; per-agent SQLite index is derived and rebuildable. citeturn9search2turn22view0 | Vector search over ~400-token chunks (80 overlap); optional hybrid BM25 + vector; optional MMR re-ranking + temporal decay; embeddings via local or remote provider. citeturn21view3turn22view0turn22view3 | Disk capacity for files; context-window/token budget for injected bootstrap files; snippet caps; indexing may lag for large corpora. citeturn5view0turn22view3turn5view1 | Generally low once indexed; can degrade on large backfills; batch embeddings exist for some providers. citeturn21view2turn21view3 | Missing/invalid embedding provider keys disables search; stale/dirty index; asynchronous indexing yields “recent info not found”; some update-related “dirty index” issues reported. citeturn21view0turn22view3turn7view0 | Use `/context` to watch token pressure; run `openclaw memory status --deep --index` or `openclaw memory index`; enable hybrid/MMR/decay; keep bootstrap files concise; ensure workspace consistency. citeturn5view1turn9search0turn22view3turn6view0turn7view0 |
| OpenClaw + QMD backend (`memory.backend="qmd"`) | Markdown remains source of truth; QMD keeps its own config/cache/DB under per-agent XDG dirs; OpenClaw falls back to builtin if QMD fails. citeturn23view1turn21view1 | QMD hybrid pipeline (BM25 + vector + rerank) plus typed query docs (`lex/vec/hyde`) and expansion; multiple modes; OpenClaw shells out to `qmd`. citeturn23view1turn19view0turn20view0 | Local model downloads + VRAM/CPU; multi-collection search; snippet/injection caps in `memory.qmd.limits`. citeturn23view2turn23view3turn19view0 | First query may be slow (model download/warmup); QMD daemon mode can reduce warm latency per QMD changelog. citeturn23view1turn19view0 | Missing `qmd` binary; SQLite without extension support; lock/timeout issues; sparse-term drops in multi-collection searches; CPU storms from embed runs (addressed in release notes). citeturn23view1turn31view0 | Follow OpenClaw’s QMD prewarm recipe; apply QMD-related fixes by upgrading OpenClaw; constrain limits/timeouts; ensure Bun/SQLite prerequisites. citeturn23view2turn31view0turn23view1 |
| Mem0 plugin for OpenClaw | Memories live outside OpenClaw sessions; auto-recall injects relevant memories each turn; auto-capture stores after each turn. citeturn12view0turn10view1 | Semantic retrieval in Mem0; optional graph memory; plugin exposes tools (`memory_search/list/store/get/forget`) and scopes (session vs long-term). citeturn12view0turn13search1 | Dependent on Mem0 service or self-host infra; context-window budget for injected recalls; configuration of embedder/vector store in OSS mode. citeturn12view0turn10view1 | Claims of low retrieval latency in Mem0 docs; paper reports large p95 latency reductions vs full-context (context-dependent). citeturn13search0turn13search8 | API key/config errors; over-injection (token bloat); evaluation/benchmark disputes in ecosystem; reliance on extraction quality. citeturn10view1turn13search6 | Tune `topK` and `searchThreshold`; validate per-user scoping; for OSS mode, pin embedder/vector store explicitly; regression-test with known recall prompts. citeturn12view0turn10view1 |
| Cognee plugin for OpenClaw | Markdown files are synced into Cognee; plugin maintains a local sync index in `~/.openclaw/memory/cognee/`; recall injected before runs; re-sync after runs. citeturn24view0 | Knowledge-graph traversal (“GRAPH_COMPLETION”) plus other search types; backed by Cognee’s graph+vector system. citeturn24view0turn15search0 | Depends on Cognee server availability (local Docker or hosted); graph construction costs; injected recall consumes context tokens. citeturn24view0turn5view1 | Not benchmarked in the plugin doc; Cognee paper focuses on tuning for multi-hop QA benchmarks rather than OpenClaw-specific latency. citeturn15search0turn15search3 | Plugin installation/config-key mismatch can later break gateway reload (reported bug); sync drift if indexing fails silently. citeturn25view0 | Ensure the configured plugin entry key matches the manifest id; use `openclaw cognee status/index`; keep config atomic; upgrade OpenClaw if fixes land. citeturn24view0turn25view0 |
| Obsidian vault used as memory corpus | Notes are local Markdown files in a “vault” folder; persistence is file-system-based; syncing introduces conflict semantics. citeturn17search0turn17search3 | Obsidian itself provides UI search; OpenClaw retrieval depends on its memory backend (builtin/QMD/Cognee/etc.). citeturn17search0turn9search2turn23view1 | Disk + sync constraints; large vaults can raise indexing cost and token pressure if injected files are big. citeturn17search21turn5view0turn5view1 | Local FS operations are fast; sync conflicts can create branching copies and “split brain.” citeturn17search2turn17search11 | Sync conflicts from concurrent edits; multi-sync interference; backup misconceptions (sync ≠ backup). citeturn17search2turn17search18turn17search21 | Use a single “primary” backup device; avoid running multiple sync systems on the same vault; add OpenClaw memory indexing paths carefully; validate conflict resolution workflow. citeturn17search21turn17search18turn21view1 |

### OpenClaw default memory behavior

OpenClaw’s docs are unusually explicit about the “memory contract”: memory is plain Markdown in the workspace, and **the files are the source of truth**. “Memory search tools” are provided by the active memory plugin (default slot is `memory-core`), and can be disabled by setting the memory plugin slot to `"none"`. citeturn9search2

The agent-facing tools are:

- `memory_search`: returns snippets (not full files), including file path and line ranges; snippets are capped in size and built from chunked Markdown. citeturn21view3turn22view3  
- `memory_get`: reads a specific approved memory file/line range (paths outside `MEMORY.md`/`memory/` are rejected). `memory_get` now “degrades gracefully” when a file doesn’t exist (returns `{text:"", path}` rather than throwing `ENOENT`), which changes error-handling expectations and can hide missing-memory conditions if you don’t explicitly check for empty output. citeturn9search2

Retrieval quality can be materially improved with built-in hybrid and post-processing options:

- **Hybrid BM25 + vector** mixing with explicit score-combination logic (candidate pool from both, score transformation, weighted merge). citeturn22view0  
- **MMR** to reduce near-duplicate results. citeturn22view1turn22view3  
- **Temporal decay** (exponential recency boost by half-life) to keep stale daily-note facts from outranking recent updates. citeturn22view2turn22view3

These are disabled by default and live in `memorySearch.query.hybrid`. citeturn22view3

### QMD in OpenClaw

OpenClaw’s “QMD backend (experimental)” swaps the built-in SQLite indexer for entity["organization","QMD (local search sidecar)","bm25 vector rerank cli"] and shells out to it for retrieval, while keeping Markdown as the ground truth. citeturn23view1turn21view1

Operationally, OpenClaw writes QMD’s state under per-agent directories by setting `XDG_CONFIG_HOME` and `XDG_CACHE_HOME` and schedules `qmd update` and embeddings runs on boot and on an interval. A key reliability feature is that **if QMD fails (missing binary, parse failure, subprocess exit), OpenClaw falls back to the builtin provider** so memory tools still work. citeturn23view1turn21view1

QMD’s own changelog and syntax docs show that it is not just “BM25 + vectors,” but also:

- A typed “query document” format (`lex:`, `vec:`, `hyde:`) with an explicit grammar and different backends by type. citeturn19view0turn20view0  
- On-device query expansion, reranking, and hybrid fusion weighting. citeturn19view0turn20view0  
- Performance-oriented changes like parallel reranking/embedding contexts and claims of reduced warm query latency via daemon mode. citeturn19view0

OpenClaw’s release notes for 2026.2.21 include a substantial QMD fix bundle (e.g., splitting multi-collection queries to avoid sparse-term drops, retrying boot updates on lock/timeout failures, and serializing embed runs to prevent CPU storms). Treat this as a strong signal that early QMD integrations are sensitive to concurrency and multi-collection query behavior. citeturn31view0

### Mem0

entity["company","Mem0 (AI memory platform)","persistent memory for agents"] positions itself as an extraction + consolidation + retrieval layer that lives outside the model context window, which is the core architectural response to compaction/truncation problems. citeturn13search0turn12view0turn10view2

For published benchmarks, Mem0 maintains an arXiv paper describing a “memory-centric architecture” evaluated on the LoCoMo benchmark, reporting improvements across question categories and large reductions in p95 latency and token costs relative to full-context approaches. citeturn13search0turn13search4

However, the broader “memory benchmark” space is contentious; a public issue in entity["organization","Zep (memory platform)","agent memory product"]’s papers repository disputes a Mem0-reported headline accuracy claim and attributes gaps to evaluation setup differences. This doesn’t automatically invalidate Mem0’s approach, but it does mean you should treat “benchmarked superiority” as conditional on configuration and measurement methodology. citeturn13search6

The OpenClaw plugin (from Mem0’s repo) is operationally simple but conceptually important:

- **Auto-recall** runs before the model responds, injecting relevant memories.  
- **Auto-capture** runs after the model responds, sending the exchange to Mem0 for extraction/updates/merging. citeturn12view0turn10view1  
- Memories are separated into **session-scoped** vs **user long-term** scopes, with a `scope` parameter in tools and a `longTerm` boolean in `memory_store`. citeturn12view0  
- Key knobs include `autoRecall`, `autoCapture`, `topK`, and `searchThreshold` (plus platform-only features like graph enablement and custom extraction instructions/categories). citeturn12view0

### Cognee

entity["company","Cognee (knowledge graph memory)","graph-native memory engine"] is framed as a knowledge engine that builds persistent memory via knowledge graphs and vector search. For OpenClaw, the plugin specifically syncs `MEMORY.md` and `memory/*.md` into Cognee and injects recall before runs; it uses hash-based change detection and tracks sync state under `~/.openclaw/memory/cognee/`. citeturn24view0turn14search1

The plugin’s documented config surface includes `baseUrl`, `apiKey`, `datasetName`, `searchType` (including `GRAPH_COMPLETION`, `CHUNKS`, `SUMMARIES`), and toggles for `autoRecall` and `autoIndex`. It also provides CLI commands (`openclaw cognee index/status`) that serve as first-class diagnostics hooks. citeturn24view0

Cognee’s research footprint includes an arXiv paper on optimizing the knowledge-graph/LLM interface across multi-hop QA benchmarks (HotPotQA, TwoWikiMultiHop, MuSiQue), emphasizing that retrieval quality is highly sensitive to chunking, graph construction, retrieval, and prompting hyperparameters. This is directly relevant to “memory systems” because it highlights how often “forgetting” is really “retrieval pipeline mis-tuning.” citeturn15search0turn15search3

A notable OpenClaw-specific failure mode is a reported plugin install/config mismatch: installing Cognee’s OpenClaw plugin can leave a config entry keyed differently from the plugin’s manifest id, creating a latent “plugin not found” failure that can break gateway reload and take channels offline. citeturn25view0

### Obsidian

entity["company","Obsidian (Markdown vault app)","local markdown note system"] stores notes as Markdown-formatted plain text files in a “vault,” which is simply a folder on the local file system. This is an extremely compatible substrate for OpenClaw’s file-first memory philosophy. citeturn17search0

But Obsidian introduces its own operational realities:

- A vault can be synchronized across devices using Obsidian Sync or third-party sync, and conflicts occur when the same file is edited before sync converges. citeturn17search2turn17search11  
- Obsidian’s own backup guidance distinguishes “sync” from “backup” and recommends a dedicated one-way backup process and a “primary” device concept for backups. citeturn17search21turn17search11  
- Using multiple sync systems on the same vault (e.g., Sync + Drive) can cause interference and problems (not unique to Obsidian; it’s inherent to competing sync mechanisms). citeturn17search18

In OpenClaw terms, “Obsidian memory” typically means either (a) making your OpenClaw workspace or memory corpus live inside an Obsidian vault, or (b) using an Obsidian-targeting skill that writes memory snippets into your vault (example: “memory-to-obsidian” skill). citeturn17search0turn16search21

## Common causes of forgetting and diagnostics steps

A practical way to reason about “forgetting” is to separate **persistence failures**, **retrieval failures**, and **context failures**. OpenClaw’s docs and issue reports map cleanly to this triage framing. citeturn9search2turn5view1turn7view0turn7view1

### Persistence failures: “It was never written (or written where you think)”

Common causes:

- The agent is a fresh instance and continuity is file-based; “mental notes” don’t survive restarts. This is explicit in OpenClaw’s own workspace template. citeturn33view0turn33view1  
- The gateway is not using the workspace you think it is (multiple workspace directories cause state drift). OpenClaw warns that older installs may have created extra workspace folders and recommends keeping a single active workspace; `openclaw doctor` warns about extra directories. citeturn6view0  
- Sandboxing or permissions block writes (e.g., memory flush skipped if the session is sandboxed with read-only/no workspace access). citeturn21view0turn6view0  
- Plugin-level persistence breaks: recent GitHub issues report severe “memory-core stops writing” failure modes after updates (SQLite and Markdown writes frozen), with no obvious recovery. This is serious because it can create silent data loss while the agent continues responding. citeturn7view1turn8view0

Diagnostics:

- Confirm workspace and file map: check `agents.defaults.workspace`, confirm `memory/` and `MEMORY.md` live where expected. citeturn6view0turn9search2  
- If the symptom is “my agent doesn’t follow my instructions,” verify `AGENTS.md`/`SOUL.md`/`USER.md` exist and are injected each run (and not truncated). Use `/context list` and `/context detail`. citeturn5view1turn5view0turn6view0  
- Validate that *writes happen*: check whether `memory/YYYY-MM-DD.md` timestamps move when conversations happen; if not, treat this as a persistence incident, not a retrieval one. The “complete persistence failure” issue includes a useful pattern: compare timestamps of `main.sqlite` and daily memory files across activity windows. citeturn7view1turn8view0

### Retrieval failures: “It was written, but recall can’t find it”

Common causes:

- Embeddings provider not configured or not available; OpenClaw auto-select rules can still end in “disabled until configured.” citeturn21view0  
- Index is **dirty** or stale after updates; one reported workaround is to reindex (“Memory index updated (main)”) which restores search. citeturn7view0turn8view3  
- The system is configured to index only default memory paths; additional corpora (Obsidian vaults, team docs) require explicit `memorySearch.extraPaths` or QMD paths. citeturn21view1turn23view1  
- Async indexing means “I just wrote it and can’t find it” is possible; OpenClaw notes that session indexing (and some sync paths) are best-effort and `memory_search` doesn’t block on indexing. citeturn22view3turn21view3  
- For QMD: missing binary, SQLite extension limitations, or sidecar failures can silently trigger fallback to builtin; you might think you’re using QMD when you aren’t unless you check diagnostics. citeturn21view1turn23view1

Diagnostics:

- Run context diagnostics: `/status` (token pressure, compactions) and `/context detail` (what’s actually being injected). citeturn5view1turn3view0  
- Run memory diagnostics via CLI: `openclaw memory status --deep` and use `--index` to reindex if store is dirty; `openclaw memory index --verbose` to see indexing phases. citeturn9search0  
- If using QMD backend, validate QMD health and configuration by confirming the QMD XDG directories exist and by following OpenClaw’s own “pre-download/warm” recipe. citeturn23view2turn23view1  
- If using Cognee, run `openclaw cognee status` and `openclaw cognee index` (plugin-provided observability). citeturn24view0  
- If using Mem0 plugin, verify plugin registration and exercise `openclaw mem0 search` against a known fact (plugin README documents CLI commands). citeturn12view0

### Context failures: “Recall exists, but the model doesn’t see or prioritize it”

Common causes:

- **Compaction** summarizes older conversation history into a lossy summary entry. If your “instructions” lived only in chat history (not in `AGENTS.md`/workspace files), compaction can effectively erase them. citeturn3view0turn33view0  
- **Bootstrap file truncation**: OpenClaw injects bootstrap files but truncates large ones per file and in total. If your core constraints are at the bottom of a bloated file, the agent may never see them. citeturn5view0turn5view1turn4search14  
- **Sub-agent prompt minimization**: OpenClaw can render smaller system prompts for sub-agents (`promptMode=minimal`), omitting memory recall/self-update and injecting fewer workspace files. This frequently explains “the helper agent forgot our rules.” citeturn5view0  
- **Session pruning** can remove tool results from the in-memory prompt. If “the thing it forgot” came from a tool result (e.g., a long web page or a big file read), pruning can make it disappear from the next call. citeturn32view0turn5view1  
- **Over-injection token pressure**: large `MEMORY.md` or `TOOLS.md` increases base prompt size and can drive more frequent compaction. OpenClaw calls this out explicitly. citeturn5view0turn5view1

Diagnostics:

- Inspect injection and truncation with `/context list` (raw vs injected sizes, truncation flags). citeturn5view1  
- Check whether the relevant instruction lives in `AGENTS.md`/`SOUL.md`/`USER.md` (guaranteed injection) versus a prior chat turn (subject to compaction). citeturn5view0turn33view0turn3view0  
- For heavy-tool workflows on Anthropic-family models, check if context pruning is enabled and whether the “forgotten” information was a tool result. citeturn32view0turn5view1

```mermaid
flowchart TD
  A[Symptom: agent forgot X] --> B{Was X written to disk?}
  B -- No / unsure --> B1[Ask agent to write X to MEMORY.md or today's daily file;\nverify timestamp changes]
  B -- Yes --> C{Can retrieval find it?}
  C -- No --> C1[Run memory index/status;\ncheck provider keys / index dirty;\nverify paths]
  C -- Yes --> D{Is X reaching the model context?}
  D -- No --> D1[/context detail:\ntruncation? compaction? subagent minimal?\nmove X into AGENTS.md / concise MEMORY.md]
  D -- Yes --> E{Is X being overridden/contradicted?}
  E -- Yes --> E1[Resolve conflicts in memory;\nuse curated MEMORY.md + recency strategy;\nconsider temporal decay/MMR]
  E -- No --> F[Model behavior issue:\nadd explicit instruction priority;\nadd regression tests]
```

## Proven fixes and optimizations

This section separates **documented/official fixes** (directly supported by OpenClaw docs or release notes), **community-observed fixes** (from issue trackers), and **optimizations with strong evidence** (from published papers/docs).

### Documented and official fixes

**Make persistence explicit with a pre-compaction memory flush.** OpenClaw supports a “silent” pre-compaction memory flush turn that prompts the agent to write durable notes before compaction runs; it is skipped if the workspace is not writable (sandbox RO/none). This directly targets “it forgot after a long chat” failure modes. citeturn21view0turn3view0

**Enable hybrid search and post-processing (MMR + temporal decay) for better recall quality.** OpenClaw’s memory docs provide explicit configuration for hybrid vector+BM25 weighting, MMR, and temporal decay, including a half-life model and guidance about evergreen files. These are first-party mitigations for “retrieval returns stale or redundant snippets.” citeturn22view0turn22view1turn22view2turn22view3

**Use the embedding cache when reindexing churn is high.** OpenClaw supports caching chunk embeddings in SQLite to avoid re-embedding unchanged text during frequent updates. This is a direct cost/latency optimization in reindex-heavy setups. citeturn22view3

**Use `openclaw memory` CLI to detect and repair dirty indexes.** The CLI docs explicitly describe: `memory status --deep --index` reindexes if the store is dirty, and `memory index --verbose` provides detailed logs. This is the cleanest “official” path to fixing stale index symptoms. citeturn9search0

**Upgrade to releases that include memory fixes relevant to your failure mode.** For example, OpenClaw’s 2026.2.21 release includes multiple QMD and builtin memory fixes, including preventing SQLite “database is not open” shutdown races and improvements to QMD multi-collection behavior and embed serialization to avoid CPU storms. citeturn31view0turn31view2

### Community-observed fixes with concrete evidence

**Reindex after updates when memory search returns empty results and the store is “dirty.”** A GitHub issue reports memory search empty after updating, with `Dirty: yes`, and the stated workaround is running a memory index update (“Memory index updated (main)”) which “refreshes the index and fixes the issue.” citeturn7view0turn8view3

**Be strict about plugin id/config key consistency for Cognee.** A reported bug shows that if the plugin’s manifest id and your `plugins.entries.*` key diverge (or partial installs leave a wrong key), a later config reload can shut down the gateway. The fix here is operational: ensure the entry key matches the manifest id and remove invalid entries before reload. citeturn25view0turn24view0

### Optimizations with strong supporting sources

**Adopt an “external memory” pattern to bypass compaction loss.** Mem0’s OpenClaw plugin and docs are explicitly motivated by the claim that in-context memory (including injected files) can be compressed/dropped, whereas memories stored externally can be re-injected each turn. Mem0’s paper provides empirical evaluation in that direction (though benchmark disputes exist). citeturn10view2turn12view0turn13search0turn13search6

**Use a knowledge-graph memory when relationship traversal matters more than similarity.** Cognee’s OpenClaw integration is specifically framed around graph traversal (“GRAPH_COMPLETION”), and Cognee’s paper argues meaningful performance variation is driven by hyperparameters in graph construction/retrieval/prompting—strong evidence that “graph memory” is not a binary switch but a tunable system that benefits from measurement. citeturn24view0turn15search0turn15search3

### Config snippets

OpenClaw config examples below are *minimal* and focus on the parts that directly affect memory reliability and recall quality.

```json5
// openclaw.json (conceptual example)
// Goal: make built-in memory recall less stale + more relevant
{
  agents: {
    defaults: {
      // Prevent "forgot before compaction" by writing durable notes first
      compaction: {
        memoryFlush: {
          enabled: true,
          softThresholdTokens: 4000,
          systemPrompt: "Session nearing compaction. Store durable memories now.",
          prompt: "Write lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store."
        }
      },

      memorySearch: {
        // Choose provider explicitly in real deployments if auto-selection is brittle
        // provider: "openai",
        // model: "text-embedding-3-small",

        cache: { enabled: true, maxEntries: 50000 },

        query: {
          hybrid: {
            enabled: true,
            vectorWeight: 0.7,
            textWeight: 0.3,
            candidateMultiplier: 4,
            mmr: { enabled: true, lambda: 0.7 },
            temporalDecay: { enabled: true, halfLifeDays: 30 }
          }
        }
      }
    }
  }
}
```

This configuration pattern is directly grounded in OpenClaw’s memory and compaction docs. citeturn21view0turn22view3turn22view0turn3view0

```json5
// openclaw.json (conceptual example)
// Goal: switch memory_search retrieval to QMD sidecar
{
  memory: {
    backend: "qmd",
    qmd: {
      includeDefaultMemory: true,
      update: { interval: "5m", debounceMs: 15000 },
      limits: { maxResults: 6, timeoutMs: 4000 }
      // paths: [{ name: "vault", path: "~/ObsidianVault", pattern: "**/*.md" }]
    }
  }
}
```

OpenClaw documents the QMD backend requirements, lifecycle, fallback behavior, and `memory.qmd.*` surface. citeturn23view1turn23view3

```json5
// plugins.entries snippet for Mem0 plugin (as documented by plugin README)
// Goal: enforce auto capture + auto recall outside the session
{
  "openclaw-mem0": {
    "enabled": true,
    "config": {
      "mode": "platform",       // or "open-source"
      "apiKey": "${MEM0_API_KEY}",
      "userId": "your-user-id",
      "autoRecall": true,
      "autoCapture": true,
      "topK": 5,
      "searchThreshold": 0.3
    }
  }
}
```

Mem0’s OpenClaw plugin README documents these options and defaults, including `topK` and `searchThreshold`. citeturn12view0turn10view1

```yaml
# Cognee OpenClaw plugin config (from Cognee docs)
plugins:
  entries:
    memory-cognee:
      enabled: true
      config:
        baseUrl: "http://localhost:8000"
        apiKey: "${COGNEE_API_KEY}"
        datasetName: "my-project"
        searchType: "GRAPH_COMPLETION"
        autoRecall: true
        autoIndex: true
```

This reflects Cognee’s documented OpenClaw integration, including `searchType` and auto toggles. citeturn24view0

### Testing procedures

A reliable test suite for “memory works” should validate **write → index → recall → injection**, not just one step.

1. **Write test**: Insert a distinctive fact into `MEMORY.md` (curated) or today’s daily log. Confirm the file changed on disk and is in the active workspace. citeturn9search2turn6view0  
2. **Index test**: Run `openclaw memory status --deep --index` (or `openclaw memory index`) and verify the indexed file count increases/updates and the store is not dirty. citeturn9search0turn7view0  
3. **Recall test**: Query with a paraphrase (semantic) and with an exact token (BM25). Enable hybrid/MMR/decay if paraphrase or staleness is a failure mode. citeturn22view0turn22view3  
4. **Injection test**: Use `/context detail` to confirm that the memory/instruction files you rely on are injected and not truncated in the system prompt. citeturn5view1turn5view0  
5. **Regression test**: Trigger a long session until compaction occurs, and verify that pre-compaction memory flush actually wrote durable notes (or explicitly confirm it was skipped due to RO workspace). citeturn3view0turn21view0turn6view0

## Recommended best practices and a troubleshooting checklist

OpenClaw’s own templates already encode a best practice that tends to get ignored: treat the workspace as home, treat memory as files, and assume you wake up fresh each session. citeturn33view0turn6view0

### Best practices

Keep *instruction persistence* and *memory persistence* separate:

- Put durable behavioral rules (“how to behave, how to use memory”) in `AGENTS.md` because it is designed as operating instructions and is loaded each session. citeturn6view0turn33view0  
- Keep `MEMORY.md` curated and small enough to avoid truncation/token blowups; if it becomes huge, your system prompt grows and compaction frequency rises. Use daily logs for raw narrative, and distill. citeturn5view0turn33view0turn3view0  
- Use `/context` regularly as an operational dashboard; in long-running agents, token pressure is an early warning indicator for impending compaction and “instruction drift.” citeturn5view1turn3view0  
- When you rely on retrieval, don’t assume it’s working: periodically run `openclaw memory status --deep` and reindex on “dirty,” especially after upgrades. citeturn9search0turn7view0turn31view0  
- If you adopt an external memory system (Mem0/Cognee), treat it as a production dependency: monitor its availability, and explicitly bound injected memory volume to avoid “two recall engines doubling token burn.” citeturn12view0turn24view0turn5view1  
- If you use Obsidian as the storage substrate, be deliberate about sync and backups: avoid multiple sync systems on the same vault, and choose a true backup strategy rather than assuming sync is sufficient. citeturn17search18turn17search21turn17search2

### Troubleshooting checklist

- **Workspace identity**
  - Confirm the gateway is using the workspace you think it is; remove/archival old workspaces to avoid drift. citeturn6view0  
- **Instruction injection**
  - `/context list` → check `AGENTS.md`/`SOUL.md`/`USER.md` injection status and truncation. citeturn5view1turn5view0  
- **Persistence**
  - Verify `memory/YYYY-MM-DD.md` updates during conversation; if not, treat as a persistence incident. citeturn9search2turn7view1  
- **Retrieval**
  - `openclaw memory status --deep --index` and `openclaw memory index --verbose` when recall is stale/empty. citeturn9search0turn7view0  
- **Context management**
  - Check compaction count and whether memory flush is enabled/skipped; reduce token pressure if compaction is frequent. citeturn3view0turn21view0turn5view1  
- **Backend/plugin health**
  - QMD: ensure `qmd` exists on PATH, prerequisites satisfied, and upgrade to releases with QMD fixes. citeturn23view1turn31view0  
  - Cognee: ensure plugin entry key matches manifest id; use `openclaw cognee status/index`. citeturn25view0turn24view0  
  - Mem0: validate API key/user scoping; tune `topK`/threshold to avoid recall noise. citeturn12view0turn10view1  
- **Data safety**
  - If using Obsidian Sync or third-party sync, have a conflict-resolution procedure and a real backup plan. citeturn17search2turn17search21

## Gaps and open research questions

OpenClaw’s docs provide unusually concrete implementation details (chunking targets, hybrid scoring sketch, MMR/decay formulas, QMD fallback rules), but several gaps remain.

One gap is **formal guarantees**. None of the OpenClaw memory backends provide formal retrieval-accuracy guarantees; even where scoring formulas are specified, accuracy is empirical and corpus-dependent. The docs acknowledge evolvability (“this area is still evolving”) and provide pragmatic knobs rather than hard guarantees. citeturn9search2turn22view0turn33view0

A second gap is **end-to-end reliability measurement**. Most “my agent forgot” reports conflate persistence and retrieval. The severe “memory-core stops writing” issue demonstrates a need for built-in health checks that detect *silent persistence failures* (writes not happening) rather than only “search looks empty.” OpenClaw has started improving doctor-style checks for memory embedding readiness, but persistence watchdogging remains an open operational need. citeturn7view1turn29view1turn31view0

A third gap is **benchmark standardization and reproducibility** in memory systems. Mem0’s paper reports strong LoCoMo results, but public disputes indicate that configuration and evaluation methodology can dominate outcomes. For practitioners, this argues for maintaining a local “memory regression test suite” (facts/preferences/temporal/multi-hop) and tracking performance across upgrades and backend swaps. citeturn13search0turn13search6

Finally, there is a still-open design question of **instruction persistence vs memory persistence**: OpenClaw’s bootstrap injection makes instructions “sticky,” but it also creates token pressure and compaction frequency risks when files grow. The system prompt and context docs make this trade-off explicit, but there is no universally best configuration—optimal settings likely depend on the agent’s long-running workload, tool-output volume, and whether external memory systems inject additional context. citeturn5view0turn5view1turn3view0turn32view0