---
type: explanation
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# The Vault as Memory

The Crumb vault isn't just a note-taking system — it's the external memory that makes the entire system work. This explains why Obsidian, how Active Knowledge Memory (AKM) surfaces what matters, and where the approach has limits.

**Architecture source:** [[02-building-blocks]] §Vault Store, [[03-runtime-views]] §AKM Surfacing

---

## Why Obsidian

The vault is a directory of markdown files tracked by git. Obsidian provides the GUI (graph view, search, Excalidraw plugin), but the vault works without it — it's just markdown + git underneath. This is deliberate:

- **No vendor lock-in.** Markdown files are readable by any text editor, any LLM, any pipeline. If Obsidian disappeared tomorrow, the vault would still work.
- **Git gives version history for free.** Every change is tracked. Decisions can be audited. State can be recovered. The commit log is a chronological record of everything that happened.
- **Filesystem is the API.** Crumb reads and writes files. Tess reads and writes files. Scripts read and write files. No database layer, no API wrapper — just the filesystem. This makes the system inspectable, debuggable, and portable.

Wikilinks (`[[note-name]]`) create a web of connections between notes. Obsidian resolves these by filename regardless of directory, so moving files doesn't break links. This makes the vault's structure flexible — reorganization is cheap.

---

## How Knowledge Persists

Knowledge enters the vault through several pipelines:

| Entry Point | Pipeline | Output |
|-------------|----------|--------|
| NotebookLM digests | inbox-processor skill | Knowledge-notes in `Sources/` |
| Feed-intel items | feed-pipeline skill | Signal-notes in `Sources/signals/` |
| Manual drops | `_inbox/` → inbox-processor | Routed to appropriate location |
| Project work | Crumb sessions | Design artifacts, run-logs, compound patterns |
| Research | researcher skill | Research-notes in `Sources/research/` |

Every knowledge artifact gets `#kb/` tags (18 canonical Level 2 topics, open Level 3 subtopics) and a `topics` field that links it to Maps of Content (MOCs) in `Domains/`. This creates a three-layer structure:

1. **Individual notes** — atomic knowledge units with tags and metadata
2. **MOCs** — curated indexes that group notes by theme, with synthesis sections
3. **Domains** — the eight life domains (career, software, learning, etc.) that organize MOCs

---

## Active Knowledge Memory (AKM)

The vault has thousands of notes. Most aren't relevant to any given session. AKM solves this by surfacing the right knowledge at the right time.

AKM fires at three trigger points:

| Trigger | When | Items Surfaced |
|---------|------|---------------|
| Session start | Startup hook | 5 items |
| Skill activation | Before each skill | 3 items |
| New content | After creating `#kb/` notes | 5 items + compound connection scan |

The retrieval engine (`knowledge-retrieve.sh`) scores items by recency, relevance, and cross-domain potential. It explicitly looks for compound connections — notes from different domains that together suggest something neither says alone. These are flagged as `[cross-domain]` in the knowledge brief.

Additionally, two targeted signal scans surface captured external knowledge at key workflow points:

| Trigger | When | Scope |
|---------|------|-------|
| SPECIFY phase | Systems-analyst Step 1b | `Sources/signals/`, `Sources/insights/`, `Sources/research/` filtered by `#kb/` tags |
| PLAN phase | Action-architect Step 1b | Same directories, focused on implementation patterns |

These scans are budget-exempt. If the tag filter returns >15 results (common with broad tags like `kb/software-dev`), a keyword intersection filter ranks and caps results. The operator selects which items to read in full.

The new-content trigger also includes a compound connection scan: after creating any `#kb/` tagged note, Crumb scans signals, insights, and research for notes with overlapping tags and presents matches as potential compound connections.

AKM is a heuristic, not a search engine. It surfaces what's likely relevant, not what you asked for. Explicit vault searches (via obsidian-cli or Grep) handle targeted lookups.

---

## Compound Engineering as Memory Amplifier

The vault doesn't just store knowledge — it improves over time. Compound engineering is the mechanism:

At every phase transition, Crumb evaluates whether the current work revealed patterns, conventions, or solutions that are more valuable than the specific task. These get routed to durable locations:

- **Convention updates** → existing docs (file-conventions, CLAUDE.md)
- **Solution patterns** → `_system/docs/solutions/`
- **Primitive gaps** → proposal flow for new skills, overlays, or protocols
- **Cross-domain connections** → flagged for further investigation

This means each session makes the vault slightly more useful for future sessions. The knowledge compounds.

---

## Limitations

The vault-as-memory approach has real constraints:

**Context window pressure.** Every vault file Crumb reads consumes context tokens. With a 1M token window, this is generous but not unlimited. The context budget (≤5 source docs per skill invocation, 10 max) exists because quality degrades before the hard limit hits. Summary documents and the AKM retrieval engine are mitigations, not solutions.

**Staleness.** Knowledge notes don't update themselves. A signal-note about a tool's pricing captured six months ago may be wrong today. Summary staleness detection (comparing `source_updated` timestamps) catches some of this, but the fundamental issue is that external reality changes and the vault doesn't track it automatically.

**Binary limitations.** Git doesn't diff binaries. PDFs, images, and presentations are excluded from version tracking. Companion notes (markdown) carry the metadata and description, but the binary itself has no history. Backup mechanisms (Time Machine, iCloud) partially compensate.

**No real-time search.** AKM is triggered at specific points, not continuously. If you need specific information mid-session, you ask for it explicitly. The vault doesn't proactively interrupt with relevant knowledge (except at the three trigger points).

**Single-user design.** The vault assumes one operator. Multi-user access, conflict resolution, and shared editing are out of scope. The security model (filesystem permissions, credential isolation) is designed for the three-user setup on one machine, not for collaboration.

Despite these limits, the approach works because the alternatives are worse. Chat history is ephemeral. Memory APIs are opaque. Databases require schemas defined in advance. A directory of markdown files with mechanical enforcement is transparent, durable, flexible, and — critically — compoundable.
