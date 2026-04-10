---
project: book-scout
domain: software
type: specification
status: draft
created: 2026-02-28
updated: 2026-02-28
tags:
  - openclaw
  - tess
  - automation
  - research-library
---

# Book Scout — Specification

## 1. Problem Statement

Danny maintains a personal research library and wants to expand it with
public domain and open-licensed books across his interest areas (history,
philosophy, spirituality/religion, classic fiction, biography, and others
as they arise). Today, finding and downloading these books is a manual
process: search a site, evaluate licensing, download, organize. This
friction means the library grows slowly and opportunistically rather than
systematically.

Tess is the right actor for this work. She already handles external API
interaction (x-feed-intel), conversational requests via Telegram, and
structured handoffs to Crumb via the bridge. What she lacks is the
tooling to search a book archive, present candidates, execute downloads,
and catalog results.

## 2. Goals

1. **On-demand book discovery:** Danny messages Tess via Telegram with a
   subject, author, title, or other query. Tess searches Anna's Archive
   and presents matching candidates with available metadata (title,
   author, year, format, size, source library, rights information).

2. **Human-in-the-loop approval:** Danny reviews candidates in Telegram
   and selects which to download. Copyright/licensing assessment is an
   operator concern — Tess surfaces whatever rights metadata is
   available but does not gate on it.

3. **Automated download execution:** Approved books are downloaded via a
   background service. Tess monitors progress and notifies Danny on
   completion or failure.

4. **Organized storage:** Downloaded PDFs are filed into a structured
   research library directory on the Mac Studio, organized by a
   consistent scheme.

5. **Vault catalog integration:** For each acquired book, Tess dispatches
   a structured catalog entry to Crumb via the bridge. Crumb creates a
   source-index note in the vault, linking the book into the knowledge
   graph.

6. **Ongoing capability:** This is not a one-shot pipeline. It is a
   persistent Tess capability she can invoke any time Danny requests it.

## 3. Non-Goals

- Automated copyright adjudication. The operator decides.
- Processing books into knowledge notes (that's batch-book-pipeline).
- Full-text search of downloaded books.
- Torrent-based bulk collection downloads (the JSON API provides
  individual file access).
- Web scraping of the Anna's Archive website (explicitly against their
  policy; the JSON API is the intended programmatic path).

## 4. Architecture

### 4.1 Component Overview

```
Danny (Telegram)
  │
  ▼
Tess (voice agent — Haiku 4.5)
  │  Search, filter, present, approve, catalog dispatch
  │
  ├──► Anna's Archive JSON API
  │      Search by query → structured results with metadata
  │      Download URL retrieval by document ID
  │
  ├──► Download Service (launchd + aria2c or curl)
  │      Watched manifest directory
  │      Executes downloads from URLs
  │      Writes status files on completion/failure
  │
  ├──► Research Library (filesystem)
  │      ~/research-library/ on Mac Studio
  │      Organized by subject or author (TBD in PLAN)
  │
  └──► Crumb (via bridge dispatch)
         Receives structured catalog entry
         Creates source-index note in vault
         Links into knowledge graph + domain MOCs
```

### 4.2 Responsibility Split

| Function | Owner | Rationale |
|----------|-------|-----------|
| Search queries to AA API | Tess | Operational — external API interaction |
| Result filtering/ranking | Tess | Operational — same class as x-feed-intel triage |
| Candidate presentation | Tess | Operational — Telegram delivery |
| Copyright/license assessment | Danny | Operator concern — human judgment |
| Download approval | Danny | Human-in-the-loop gate |
| Manifest generation | Tess | Operational — structured output |
| Download execution | Download service | Infrastructure — dumb executor |
| Download monitoring | Tess | Operational — status polling + notification |
| PDF organization on disk | Tess | Operational — file management |
| Catalog entry dispatch | Tess | Operational — bridge protocol |
| Source-index note creation | Crumb | Governance — vault knowledge artifact |
| Vault-check compliance | Crumb | Governance — schema validation |
| BBP handoff (future) | Crumb | Governance — downstream pipeline routing |

### 4.3 Data Flow

**Search flow (single query):**
1. Danny sends query via Telegram (e.g., "find me books on Stoic
   philosophy" or "find Meditations by Marcus Aurelius")
2. Tess parses intent, constructs API search request
3. Tess calls Anna's Archive JSON API `/search` endpoint
4. API returns structured results (title, author, year, format, size,
   source library, MD5, ID, any available rights/license metadata)
5. Tess formats top N candidates as a Telegram message with numbered list
6. Danny replies with selection (e.g., "1, 3, 5" or "all" or "skip")

**Search flow (bulk list):**
1. Danny sends a multi-line list of titles via Telegram
2. Tess parses the list (one title per line, optional author)
3. Tess echoes parsed count for confirmation, then searches each title
   sequentially against the API
4. Tess groups results into three categories: found (best match),
   multiple editions (needs operator pick), not found
5. Tess presents consolidated report in Telegram
6. Danny approves the batch with optional per-item overrides

**Download flow:**
7. Tess retrieves download URLs for selected items via API
8. Tess writes a manifest file (JSON) to the download service's watched
   directory, containing: download URLs, target filenames, metadata
9. Download service picks up manifest, executes downloads
10. Download service writes per-file status (complete/failed/in-progress)
    to a status directory
11. Tess polls status directory (or watches via file events)
12. Tess notifies Danny via Telegram: "Downloaded 3/3: [titles]" or
    "2/3 complete, 1 failed: [title] — [reason]"

**Catalog flow:**
13. For each successfully downloaded book, Tess constructs a catalog
    dispatch payload (title, author, year, source_id, file path, format,
    source library, MD5, rights metadata if any)
14. Tess sends dispatch to `_openclaw/inbox/` via bridge protocol
15. Crumb processes inbox, creates source-index note in vault at
    `Sources/books/[source_id].md`
16. Crumb links source-index note to relevant domain MOC if applicable

## 5. External Dependencies

### 5.1 Anna's Archive JSON API

- **Authentication:** API key (obtained via donation)
- **Credential storage:** macOS Keychain (consistent with x-feed-intel,
  feed-intel-framework)
- **Endpoints used:**
  - Search: query by terms, returns metadata + document IDs
  - Download: retrieve download URL by document ID
- **Rate limits:** TBD — document in Phase 0 research
- **Cost:** Donation-based access, no per-request cost
- **Availability:** Multiple mirror domains (`.li`, `.gs`, `.org`);
  configurable base URL for resilience

### 5.2 Download Client

- **Recommended:** `aria2c` — robust, supports HTTP/HTTPS, resume on
  failure, multiple concurrent downloads, JSON-RPC control interface,
  available via Homebrew
- **Alternative:** `curl` with wrapper script (simpler but no resume,
  no concurrency management)
- **Decision:** Defer to PLAN phase after evaluating aria2c availability
  and control interface fit

### 5.3 Crumb Bridge

- **Protocol:** Existing dispatch protocol (Phase 2 bridge)
- **Operation type:** New operation to register: `catalog-book` (or
  extend existing operation — evaluate in PLAN)
- **Payload schema:** Structured JSON with book metadata fields

## 6. Tess Tool Design

Tess needs a new tool (or tool set) registered in her OpenClaw config.
This tool encapsulates the Anna's Archive API interaction and manifest
generation.

### 6.1 Tool Capabilities

| Capability | Input | Output |
|------------|-------|--------|
| `book_search` | Query string, optional filters (format, year range, language) | Structured result list (max 20) |
| `book_download` | List of document IDs from search results | Manifest file written to download service watched dir |
| `download_status` | None (or manifest ID) | Per-file status from download service |

### 6.2 Implementation Options

**Option A: Native OpenClaw tool (Node.js)**
Implement as a tool module in the OpenClaw workspace. Tess invokes it
directly. Consistent with existing tool patterns.

**Option B: External script + tool wrapper**
A standalone script (Node.js or Python) that Tess invokes via a shell
tool. More isolated but adds a layer.

**Option C: MCP server**
Run the existing `annas-mcp` Go binary (or a custom equivalent) as an
MCP server. Tess connects via MCP protocol.

**Recommendation:** Option A (native tool) for search/manifest
generation. The API interaction is straightforward HTTP — no need for
MCP overhead or external process management. The download execution
remains a separate launchd service regardless.

**Decision:** Defer to PLAN phase.

## 7. Download Service Design

A dedicated launchd service that watches a manifest directory and
executes downloads.

### 7.1 Architecture

```
~/book-scout/manifests/        ← Tess writes manifest JSON here
~/book-scout/downloads/        ← Active downloads land here
~/book-scout/status/           ← Per-manifest status JSON written here
~/research-library/            ← Completed files moved here after success
```

### 7.2 Manifest Schema (draft)

```json
{
  "manifest_id": "BSM-20260228-001",
  "created_at": "2026-02-28T14:30:00Z",
  "items": [
    {
      "id": "aa_doc_id_here",
      "title": "Meditations",
      "author": "Marcus Aurelius",
      "year": 180,
      "format": "pdf",
      "size_bytes": 2400000,
      "download_url": "https://...",
      "target_filename": "marcus-aurelius-meditations.pdf",
      "md5": "abc123...",
      "rights_info": "public domain",
      "source_library": "libgen"
    }
  ]
}
```

### 7.3 Status Schema (draft)

```json
{
  "manifest_id": "BSM-20260228-001",
  "updated_at": "2026-02-28T14:35:00Z",
  "items": [
    {
      "id": "aa_doc_id_here",
      "status": "complete",
      "file_path": "/Users/tess/research-library/philosophy/marcus-aurelius-meditations.pdf",
      "downloaded_at": "2026-02-28T14:34:22Z",
      "bytes_downloaded": 2400000,
      "md5_verified": true
    }
  ]
}
```

### 7.4 Service Behavior

- Watches `~/book-scout/manifests/` for new `.json` files
- For each manifest: iterates items, downloads sequentially (or with
  bounded concurrency via aria2c)
- Writes/updates status file in `~/book-scout/status/` as each item
  completes or fails
- On item success: verifies MD5 if provided, moves file from
  `downloads/` to `~/research-library/[subject]/`
- On item failure: logs error in status, retries up to N times with
  backoff
- Managed by launchd (WatchPaths or interval-based polling)

## 8. Research Library Structure

PDF storage lives outside the vault at `~/research-library/` on the
Mac Studio. Only catalog metadata (source-index notes) lives in the
vault.

### 8.1 Organization (draft — refine in PLAN)

```
~/research-library/
  philosophy/
  history/
  fiction/
  biography/
  spirituality/
  science/
  unsorted/          ← default if no subject classification
```

Subject assignment: Tess proposes based on search metadata and query
context. Danny can override via Telegram reply. Files that can't be
classified go to `unsorted/`.

### 8.2 Naming Convention

`[author-lastname]-[short-title].pdf`

Examples:
- `aurelius-meditations.pdf`
- `plato-republic.pdf`
- `dostoevsky-brothers-karamazov.pdf`

Collisions appended with year: `smith-wealth-of-nations-1776.pdf`

## 9. Vault Integration

### 9.1 Catalog Dispatch Payload

Tess dispatches to `_openclaw/inbox/` using the bridge protocol:

```json
{
  "operation": "catalog-book",
  "params": {
    "source_id": "aurelius-meditations",
    "title": "Meditations",
    "author": "Marcus Aurelius",
    "year": 180,
    "format": "pdf",
    "file_path": "/Users/tess/research-library/philosophy/aurelius-meditations.pdf",
    "subjects": ["philosophy", "stoicism"],
    "source_library": "libgen",
    "aa_id": "md5:abc123...",
    "md5": "abc123...",
    "rights_info": "public domain",
    "acquired_at": "2026-02-28T14:34:22Z"
  }
}
```

### 9.2 Source-Index Note (Crumb creates)

```markdown
---
type: source-index
source_id: aurelius-meditations
title: "Meditations"
author: "Marcus Aurelius"
year: 180
format: pdf
file_path: "/Users/tess/research-library/philosophy/aurelius-meditations.pdf"
source_library: libgen
acquired_via: book-scout
acquired_at: 2026-02-28
rights_info: public domain
tags:
  - kb/philosophy
topics:
  - moc-philosophy
domain: learning
status: acquired
skill_origin: book-scout
created: 2026-02-28
---

# Meditations — Marcus Aurelius

Source file: `philosophy/aurelius-meditations.pdf`

Acquired via Book Scout from LibGen (Anna's Archive).
```

The `status: acquired` field distinguishes books that have been
downloaded but not yet processed by batch-book-pipeline. BBP can
query for `status: acquired` to find unprocessed books. After BBP
processing, Crumb updates status to `processed` and adds links to
the generated digest notes.

## 10. Telegram Interaction Design

Book Scout supports two input modes: **single query** (topic search or
individual title) and **bulk list** (multiple titles for batch lookup).

### 10.1 Single Query — Topic Search

```
Danny: find me books on Stoic philosophy

Tess: Found 8 results for "Stoic philosophy":

1. 📖 Meditations — Marcus Aurelius (180 CE)
   PDF · 1.2 MB · LibGen · Public Domain

2. 📖 Letters from a Stoic — Seneca (65 CE)
   PDF · 890 KB · Internet Archive · Public Domain

3. 📖 Discourses — Epictetus (~108 CE)
   PDF · 2.1 MB · LibGen · Public Domain

4. 📖 The Stoics Reader — Inwood & Gerson (2008)
   PDF · 4.5 MB · Z-Library · ⚠️ No license info

...

Reply with numbers to download (e.g. "1 2 3"), "all", or "skip".
```

### 10.2 Single Query — Specific Title

```
Danny: find Meditations by Marcus Aurelius

Tess: Found 3 editions of "Meditations" by Marcus Aurelius:

1. 📖 Meditations (Hays translation, 2002)
   PDF · 1.8 MB · Z-Library · ⚠️ No license info

2. 📖 Meditations (Long translation, 1862)
   PDF · 1.2 MB · LibGen · Public Domain

3. 📖 Meditations (Casaubon translation, 1634)
   PDF · 940 KB · Internet Archive · Public Domain

Reply with number to download, or "skip".
```

### 10.3 Bulk List Input

Danny provides a multi-line list of titles. Tess searches each,
presents a consolidated report, and collects a single approval.

The list can come from any source — manually typed, pasted from a
notes app, or extracted from bookshelf photos via an external vision
tool.

```
Danny:
find these:
Meditations - Marcus Aurelius
Letters from a Stoic - Seneca
The Enchiridion - Epictetus
Republic - Plato
Nicomachean Ethics - Aristotle
The Consolation of Philosophy - Boethius

Tess: Searching 6 titles...

✅ Found (best match):
 1. Meditations — Marcus Aurelius (Long, 1862)
    PDF · 1.2 MB · LibGen · Public Domain
 2. Letters from a Stoic — Seneca (Campbell, 1969)
    PDF · 890 KB · Internet Archive · Public Domain
 3. The Enchiridion — Epictetus (Higginson, 1890)
    PDF · 340 KB · LibGen · Public Domain
 4. Republic — Plato (Jowett, 1871)
    PDF · 2.1 MB · Internet Archive · Public Domain
 5. Nicomachean Ethics — Aristotle (Ross, 1925)
    PDF · 1.6 MB · LibGen · Public Domain

⚠️ Multiple editions (needs your pick):
 6. The Consolation of Philosophy — Boethius
    a) Cooper translation (1902) · PDF · 780 KB · Public Domain
    b) Watts translation (1969) · PDF · 1.1 MB · ⚠️ No license info

❌ Not found:
 (none)

Reply "all" to download 1-5 + pick for 6, or specify numbers.
```

```
Danny: all, 6a

Tess: Queued 6 books for download. I'll notify you when ready.
```

**Bulk list parsing rules:**
- One title per line
- Optional author after `-`, `—`, `by`, or `,`
- Blank lines and leading/trailing whitespace ignored
- Lines starting with `#` treated as comments (ignored)
- Tess echoes the parsed list count for confirmation before searching

**Bulk list behavior:**
- Tess searches titles sequentially against the API
- Results grouped into three categories: found (single best match),
  multiple editions (operator picks), and not found
- Single approval step for the whole batch, with per-item overrides
- Downloads queued as a single manifest for the batch
- Progress notifications batched (not per-book)

### 10.4 Approval & Download

```
Danny: 1 2 3

Tess: Queued 3 books for download:
  • Meditations — Marcus Aurelius
  • Letters from a Stoic — Seneca
  • Discourses — Epictetus
I'll notify you when they're ready.

[... time passes ...]

Tess: ✅ 3/3 downloads complete:
  • Meditations → philosophy/aurelius-meditations.pdf
  • Letters from a Stoic → philosophy/seneca-letters-from-a-stoic.pdf
  • Discourses → philosophy/epictetus-discourses.pdf
Catalog entries dispatched to Crumb.
```

### 10.5 Failure Handling

```
Tess: ⚠️ 2/3 downloads complete, 1 failed:
  ✅ Meditations → philosophy/aurelius-meditations.pdf
  ✅ Letters from a Stoic → philosophy/seneca-letters-from-a-stoic.pdf
  ❌ Discourses — download timed out after 3 retries

Reply "retry 3" to try again, or "skip 3" to move on.
```

## 11. Open Questions

| ID | Question | Impact | Resolution Path |
|----|----------|--------|-----------------|
| U1 | Anna's Archive JSON API exact endpoints and response schema | Blocks tool implementation | Phase 0 research: obtain API key, document endpoints |
| U2 | API rate limits and throttling behavior | Affects search UX and download pacing | Phase 0 research with live API |
| U3 | Rights metadata completeness — what fields does the API actually return? | Affects how much licensing info Tess can surface | Phase 0 research |
| U4 | aria2c availability on Mac Studio + JSON-RPC control fit | Affects download service design | Phase 0 research |
| U5 | OpenClaw tool registration pattern for HTTP-calling tools | Affects Tess tool implementation | Review existing x-feed-intel tool patterns |
| U6 | Bridge operation allowlist — can `catalog-book` be added without bridge spec revision? | Affects vault integration | Review bridge operation extension mechanism |
| U7 | Research library disk budget — how much space is available? | Affects whether to filter by file size | Check Studio storage |
| U8 | Download URL lifetime — are AA download URLs stable or time-limited? | Affects manifest-to-download latency tolerance | Phase 0 research |

## 12. Threat Model (Book-Scout-Specific)

| ID | Threat | Rating | Mitigation |
|----|--------|--------|------------|
| BST-1 | API key exposure in logs or manifests | MEDIUM | Keychain storage, key never written to manifest files, tool reads at invocation time |
| BST-2 | Malicious file download (PDF exploit) | LOW | MD5 verification against API-reported hash; files stored outside vault; operator reviews before opening |
| BST-3 | Download service runs as wrong user | LOW | launchd plist specifies UserName; file permissions on library dir |
| BST-4 | Bridge injection via crafted book metadata | MEDIUM | Catalog dispatch uses structured JSON with field validation; Crumb validates on receipt |
| BST-5 | API quota exhaustion | LOW | Rate limiting in tool; budget telemetry if API has costs |
| BST-6 | Stale download URLs in manifest | MEDIUM | Manifest processed promptly; retry fetches fresh URL on failure |

## 13. Cost Model

| Component | Cost | Frequency |
|-----------|------|-----------|
| Anna's Archive API key | One-time donation (amount TBD) | Once |
| API usage | Free with key | Per search |
| Download bandwidth | ISP | Per download |
| Disk storage | Existing Studio storage | Per book (~1-10 MB each) |
| Tess LLM cost (search parsing) | ~$0.001/query (Haiku 4.5) | Per search |
| Bridge dispatch | Negligible | Per book |

Total ongoing cost: effectively zero beyond the initial donation.

## 14. Relationship to Other Projects

- **batch-book-pipeline:** Downstream consumer. BBP processes PDFs that
  Book Scout acquires. Handoff point: `status: acquired` in source-index
  note. BBP updates to `status: processed` after generating digests.
  The projects remain independent — Book Scout does not depend on BBP
  and vice versa.

- **x-feed-intel / feed-intel-framework:** Architectural sibling. Same
  pattern of Tess-owned external API pipeline with Telegram interaction
  and vault routing. Book Scout can learn from FIF's adapter pattern if
  future sources beyond Anna's Archive are added.

- **crumb-tess-bridge:** Infrastructure dependency. Book Scout uses the
  bridge dispatch protocol for catalog entries. May need a new operation
  type registered.

- **knowledge-navigation:** Source-index notes created by Book Scout
  participate in the MOC system and `#kb/` tag network.

## 15. Milestones (High-Level — Detailed in PLAN)

| Milestone | Scope |
|-----------|-------|
| M0: Research & API Validation | Obtain API key, document endpoints, validate search + download flow manually, evaluate aria2c |
| M1: Tess Tool | Implement search + manifest generation tool for Tess |
| M2: Download Service | launchd service, manifest watcher, download execution, status reporting |
| M3: Telegram Interaction | Search command, result presentation, approval flow, status notifications |
| M4: Vault Integration | Bridge dispatch, Crumb catalog processing, source-index note creation |
| M5: Hardening | Retry logic, error handling, telemetry, documentation |

## 16. Next Actions

1. Peer review this specification (standard 4-reviewer panel)
2. Resolve U1–U3 (API research) — can begin immediately, requires
   obtaining API key via donation
3. Resolve U4–U6 (infrastructure research) — can begin immediately
4. Advance to PLAN phase after review findings addressed
