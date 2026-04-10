---
project: book-scout
domain: software
type: specification
skill_origin: systems-analyst
created: 2026-02-28
updated: 2026-02-28
tags:
  - openclaw
  - tess
  - automation
  - research-library
---

# Book Scout — Specification

> **Post-review revision (r1):** Applied 2 must-fix and 5 should-fix items from peer review round 1 (2026-02-28). See `reviews/2026-02-28-specification.md` for full findings.

## 1. Problem Statement

Danny maintains a personal research library and wants to grow it systematically with public-domain and open-licensed books across his interest areas (history, philosophy, spirituality/religion, classic fiction, biography). Today, acquiring books is manual: search, evaluate, download, organize, catalog. This friction means the library grows slowly and opportunistically.

Tess is the right actor. She already handles external API interaction (x-feed-intel), Telegram conversation, and structured handoffs to Crumb. She needs tooling to search a book archive, present candidates, execute downloads, and dispatch catalog entries to the vault.

## 2. Goals

1. **On-demand book discovery.** Danny messages Tess via Telegram with a subject, author, title, or query. Tess searches Anna's Archive and presents candidates with metadata (title, author, year, format, size, source library, rights info).

2. **Human-in-the-loop approval.** Danny reviews candidates in Telegram and selects which to download. Copyright/licensing assessment is an operator concern — Tess surfaces whatever rights metadata the API provides but does not gate on it.

3. **Automated download.** Approved books are downloaded by Tess's tool. She notifies Danny on completion or failure.

4. **Organized storage.** Downloaded files are stored in a structured research library directory under the tess user on Mac Studio, organized by subject.

5. **Vault catalog integration.** For each acquired book, a source-index note is created in the vault, linking the book into the knowledge graph. This is the handoff point for downstream processing (batch-book-pipeline).

6. **Ongoing capability.** This is a persistent Tess capability, not a one-shot pipeline.

## 3. Non-Goals

- Automated copyright adjudication. The operator decides.
- Processing books into knowledge notes (that's batch-book-pipeline).
- Full-text search of downloaded books.
- Torrent-based bulk collection downloads.
- Web scraping of the Anna's Archive website (against their policy; the JSON API is the intended programmatic path).
- Real-time bridge dispatch for catalog entries. The bridge's confirmation/echo protocol is designed for interactive operations; catalog handoff is fire-and-forget (see §4.4).

## 4. Architecture

### 4.1 Component Overview

```
Danny (Telegram)
  │
  ▼
Tess (voice agent — Haiku 4.5)
  │  Search, filter, present, approve, download, catalog dispatch
  │
  ├──► Anna's Archive JSON API
  │      Search by query → structured results with metadata
  │      Download URL retrieval by document ID
  │
  ├──► Research Library (filesystem)
  │      /Users/tess/research-library/
  │      Organized by subject
  │
  └──► Catalog Handoff (file drop)
         Structured JSON to _openclaw/tess_scratch/catalog/
         Crumb processes via inbox sweep → source-index note
```

### 4.2 Architectural Decisions

**AD-1: Inline download, no separate service.**
The draft proposed a manifest-based download service (launchd + aria2c watcher). For a personal research library with occasional use, this is over-engineered. Instead: Tess's tool handles download inline using `curl` (or `aria2c` if already installed). Benefits: eliminates manifest/status file infrastructure, eliminates a launchd service, keeps the flow simple. If download volumes later justify separation, the tool's download function can be extracted — but that's a future decision, not a spec requirement.

**Download constraints (inline):**
- **Per-file size cap:** Files >100 MB require explicit operator confirmation before download. Tess reports the size and asks.
- **Per-item timeout:** 300 seconds (5 min) per file. Configurable in tool config.
- **Partial file handling:** Download to `{target}.partial`, rename to final name on success. On failure or timeout, `.partial` file is cleaned up.
- **Bulk sequencing:** Downloads execute sequentially, one file at a time. Tess reports progress after each file ("1/5 complete..."). This keeps the Telegram conversation responsive.
- **Bulk batch size:** Max 10 files per single `book_download` invocation. Larger batches: Tess prompts to split ("25 files — download in batches of 10?").

**AD-2: File-based catalog handoff, not bridge dispatch.**
The bridge (crumb-tess-bridge) uses a hard-coded operation allowlist requiring spec-level changes and code changes to add new operations. Catalog entry is a one-directional, fire-and-forget handoff — it doesn't need the bridge's confirmation echo or governance protocol. Instead: Tess writes structured JSON to `_openclaw/tess_scratch/catalog/`, and Crumb processes it during inbox sweep or on-demand. This avoids reopening the bridge project (DONE phase) and uses existing infrastructure (`tess_scratch` is already a bidirectional scratch space with group permissions).

**AD-3: Research library under tess user.**
`/Users/tess/research-library/` — owned by tess, no cross-user permission complexity. Crumb reads via crumbvault group perms for catalog processing. Vault can be used as temporary staging during processing but must be cleaned up afterward.

### 4.3 Responsibility Split

| Function | Owner | Rationale |
|----------|-------|-----------|
| Search queries to AA API | Tess | Operational — external API interaction |
| Result filtering/ranking | Tess | Operational — same class as x-feed-intel triage |
| Candidate presentation | Tess | Operational — Telegram delivery |
| Copyright/license assessment | Danny | Operator concern — human judgment |
| Download approval | Danny | Human-in-the-loop gate |
| Download execution | Tess (tool) | Operational — inline curl/aria2c |
| File organization on disk | Tess (tool) | Operational — file management |
| Catalog JSON generation | Tess (tool) | Operational — structured output |
| Source-index note creation | Crumb | Governance — vault knowledge artifact |
| Vault-check compliance | Crumb | Governance — schema validation |
| BBP handoff (future) | Crumb | Governance — downstream pipeline routing |

### 4.4 Data Flow

**Search flow (single query):**
1. Danny sends query via Telegram ("find me books on Stoic philosophy")
2. Tess parses intent, constructs API search request
3. Tess calls Anna's Archive JSON API search endpoint
4. API returns structured results (title, author, year, format, size, source library, MD5, ID, rights metadata)
5. Tess formats top N candidates as a Telegram message with numbered list
6. Danny replies with selection ("1, 3, 5" or "all" or "skip")

**Search flow (bulk list):**
1. Danny sends a multi-line list of titles via Telegram
2. Tess parses the list (one title per line, optional author after `-`, `—`, `by`, or `,`)
3. Tess echoes parsed count for confirmation, then searches each title sequentially
4. Tess groups results: found (best match), multiple editions (needs pick), not found
5. Tess presents consolidated report in Telegram
6. Danny approves the batch with optional per-item overrides

**Download flow:**
7. Tess retrieves download URLs for selected items via API
8. Tess downloads each file inline (curl/aria2c), placing in `/Users/tess/research-library/[subject]/`
9. Tess verifies MD5 against API-reported hash (if available)
10. Tess notifies Danny: "Downloaded 3/3: [titles]" or "2/3 complete, 1 failed: [title] — [reason]"

**Catalog flow:**
11. For each downloaded book, Tess writes a catalog JSON to `_openclaw/tess_scratch/catalog/[source_id].json`
12. Crumb processes catalog entries (on-demand or during inbox sweep)
13. Crumb creates source-index note at `Sources/books/[source_id]-index.md`
14. Crumb links source-index note to relevant domain MOC via `#kb/` tags

### 4.5 Telegram Interaction Design

Two input modes: **single query** and **bulk list**.

**Single — topic search:**
```
Danny: find me books on Stoic philosophy

Tess: Found 8 results for "Stoic philosophy":

1. Meditations — Marcus Aurelius (180 CE)
   PDF · 1.2 MB · LibGen · Public Domain

2. Letters from a Stoic — Seneca (65 CE)
   PDF · 890 KB · Internet Archive · Public Domain

3. Discourses — Epictetus (~108 CE)
   PDF · 2.1 MB · LibGen · Public Domain

4. The Stoics Reader — Inwood & Gerson (2008)
   PDF · 4.5 MB · Z-Library · No license info

Reply with numbers to download (e.g. "1 2 3"), "all", or "skip".
```

**Single — specific title:**
```
Danny: find Meditations by Marcus Aurelius

Tess: Found 3 editions of "Meditations" by Marcus Aurelius:

1. Meditations (Hays translation, 2002)
   PDF · 1.8 MB · Z-Library · No license info

2. Meditations (Long translation, 1862)
   PDF · 1.2 MB · LibGen · Public Domain

3. Meditations (Casaubon translation, 1634)
   PDF · 940 KB · Internet Archive · Public Domain

Reply with number to download, or "skip".
```

**Bulk list:**
```
Danny:
find these:
Meditations - Marcus Aurelius
Letters from a Stoic - Seneca
The Enchiridion - Epictetus
Republic - Plato

Tess: Searching 4 titles...

Found (best match):
 1. Meditations — Marcus Aurelius (Long, 1862)
    PDF · 1.2 MB · LibGen · Public Domain
 2. Letters from a Stoic — Seneca (Campbell, 1969)
    PDF · 890 KB · Internet Archive · Public Domain
 3. The Enchiridion — Epictetus (Higginson, 1890)
    PDF · 340 KB · LibGen · Public Domain
 4. Republic — Plato (Jowett, 1871)
    PDF · 2.1 MB · Internet Archive · Public Domain

Reply "all" to download, or specify numbers.
```

**Download completion:**
```
Tess: 3/3 downloads complete:
  Meditations → philosophy/aurelius-meditations.pdf
  Letters from a Stoic → philosophy/seneca-letters-from-a-stoic.pdf
  Discourses → philosophy/epictetus-discourses.pdf
Catalog entries written.
```

**Failure handling:**
```
Tess: 2/3 downloads complete, 1 failed:
  Meditations → philosophy/aurelius-meditations.pdf
  Letters from a Stoic → philosophy/seneca-letters-from-a-stoic.pdf
  Discourses — download timed out after 3 retries

Reply "retry 3" to try again, or "skip 3".
```

**Bulk list parsing rules:**
- One title per line
- Optional author after `-`, `—`, `by`, or `,`
- Blank lines and leading/trailing whitespace ignored
- Lines starting with `#` treated as comments
- Tess echoes parsed count before searching

### 4.6 Catalog Handoff Protocol

The file-based handoff at `_openclaw/tess_scratch/catalog/` is the primary integration seam between Tess and Crumb. It must be robust against partial writes, duplicates, and unprocessed accumulation.

**Directory layout:**
```
_openclaw/tess_scratch/catalog/
  inbox/          ← Tess writes new catalog JSONs here
  processed/      ← Crumb moves successfully processed JSONs here
  failed/         ← Crumb moves JSONs that fail validation here
```

**Atomic write protocol (Tess side):**
1. Tess writes to a temporary file: `inbox/.tmp-{source_id}-{timestamp}.json`
2. On write completion, renames to: `inbox/{source_id}.json`
3. Atomic rename ensures Crumb never reads a partial file

**Deduplication (Tess side):**
- Before writing, check if `inbox/{source_id}.json` or `processed/{source_id}.json` already exists
- If exists in `inbox/`: skip (already queued)
- If exists in `processed/`: skip and notify Danny ("already in library")
- Dedup key: `source_id` (derived from `author-lastname-short-title`, same algorithm as file-conventions.md)

**Processing (Crumb side):**
1. Crumb reads all `.json` files in `inbox/` (not `.tmp-*` files)
2. For each: validate JSON schema, create source-index note in `Sources/books/`
3. On success: move JSON from `inbox/` to `processed/`
4. On validation failure: move to `failed/` with error logged to run-log
5. Run vault-check on created source-index notes

**Crumb sweep trigger:**
- **On-demand:** User tells Crumb to process catalog entries ("process book catalog", "check for new books")
- **Session start:** Crumb checks `inbox/` during startup sequence if book-scout is an active project
- Not automated via cron — the volume doesn't justify it

**Stale file cleanup:**
- Files in `processed/` older than 30 days: safe to delete (source-index note is the durable artifact)
- Files in `failed/`: retained until manually reviewed and resolved
- Crumb flags stale `inbox/` files (>7 days unprocessed) during audit

## 5. External Dependencies

### 5.1 Anna's Archive API

> **Updated post-M0 (r2):** API research completed. Search is HTML-only (no JSON search endpoint). Download URL retrieval is a JSON API.

- **Authentication:** API key (obtained via donation). Stored in macOS Keychain: `book-scout.annas-archive-api-key` (account: tess).
- **Search endpoint:** `GET https://{domain}/search?q={query}&content=book_any` → **HTML response** (requires HTML parsing). No JSON search API exists.
- **Download URL endpoint:** `GET https://{domain}/dyn/api/fast_download.json?md5={hash}&key={key}&domain_index={n}` → JSON response with `download_url` and quota info.
- **Rate limits:** 50 downloads/day (per-unique-MD5). Search: no observed rate limit.
- **Cost:** Donation-based access, no per-request cost.
- **Availability:** `annas-archive.li` is the working mirror (`.pm`, `.in` timeout). Download servers: domain_index 1-4 work; domain_index 0 fails (TLS incompatibility with macOS LibreSSL).
- **Required headers:** Browser User-Agent string required for search (DDoS-Guard). Download API does not require special headers.
- **Full details:** See `design/api-research.md`.

### 5.2 Download Client

`curl` as the baseline — universally available, simple, sufficient for sequential single-file downloads. `aria2c` as an optional upgrade if resume-on-failure or concurrent downloads prove necessary. Decision: **start with curl, upgrade if needed.** Not worth adding a dependency for initial implementation.

### 5.3 Crumb Vault Integration

- **Catalog handoff:** Tess writes structured JSON to `_openclaw/tess_scratch/catalog/`.
- **Crumb processing:** Inbox-processor skill (or manual Crumb processing) reads catalog JSONs, creates source-index notes in `Sources/books/`.
- **Source-index note schema:** Per `_system/docs/file-conventions.md` §Source Index Notes. Populated with book metadata; child knowledge notes added later by BBP.
- **No bridge dependency.** This avoids reopening crumb-tess-bridge (DONE phase).

## 6. Catalog JSON Schema

Tess writes one JSON per downloaded book to `_openclaw/tess_scratch/catalog/inbox/`:

```json
{
  "source_id": "aurelius-meditations",
  "title": "Meditations",
  "author": "Marcus Aurelius",
  "year": 180,
  "format": "pdf",
  "language": "en",
  "edition": "Long translation, 1862",
  "file_size_bytes": 1258000,
  "file_path": "/Users/tess/research-library/philosophy/aurelius-meditations.pdf",
  "subjects": ["philosophy"],
  "source_library": "libgen",
  "aa_doc_id": "md5:abc123def456",
  "md5": "abc123def456789...",
  "rights_info": "public domain",
  "acquired_at": "2026-02-28T14:34:22Z"
}
```

**Field definitions:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `source_id` | string | yes | Stable slug per file-conventions.md algorithm: `kebab(author-surname + short-title)`, max 60 chars, `[a-z0-9-]` |
| `title` | string | yes | Full title as returned by API |
| `author` | string | yes | Primary author |
| `year` | int/null | no | Publication year (original or edition) |
| `format` | string | yes | File extension without dot: `pdf`, `epub`, `djvu`, `mobi`, etc. |
| `language` | string | no | ISO 639-1 code (e.g., `en`, `fr`, `la`). From API if available. |
| `edition` | string | no | Translator, edition, or publication info. From API if available. |
| `file_size_bytes` | int | no | File size in bytes. From API or post-download stat. |
| `file_path` | string | yes | Absolute path to downloaded file |
| `subjects` | string[] | yes | Library subject(s) assigned by Tess (see §7 mapping) |
| `source_library` | string | yes | AA source library (libgen, ia, zlib, etc.) |
| `aa_doc_id` | string | yes | Anna's Archive document identifier (format TBD in M0) |
| `md5` | string | no | MD5 hash from API for verification |
| `rights_info` | string | no | Rights/license metadata from API, if available |
| `acquired_at` | string | yes | ISO 8601 timestamp of download completion |

### 6.1 Source-Index Note (Crumb creates)

Crumb creates a source-index note from the catalog JSON, following the **canonical schema from `_system/docs/file-conventions.md` §Source Index Notes**:

```yaml
---
# Canonical source-index fields (file-conventions.md)
project: null                          # source-index notes are non-project
domain: learning                       # learning domain (not software — the NOTE is a learning artifact)
type: source-index
skill_origin: book-scout               # book-scout, not inbox-processor
status: active                         # required for non-project docs
created: 2026-02-28                    # from acquired_at date
updated: 2026-02-28
tags:
  - kb/philosophy                      # derived from subjects via §7 mapping
source:
  source_id: aurelius-meditations      # from catalog JSON
  title: "Meditations"                 # from catalog JSON
  author: "Marcus Aurelius"            # from catalog JSON
  source_type: book                    # always "book" for book-scout
  canonical_url: null                  # AA URL if stable, else null
topics:
  - moc-philosophy                     # derived from subjects via §7 mapping
---

# Meditations — Marcus Aurelius

**Type:** book | **Year:** 180 CE | **Acquired:** 2026-02-28

## Overview

<!-- 2-4 sentence summary — populated by BBP digest or manual annotation -->

## Notes

<!-- Knowledge notes linked here after BBP processing -->

## Reading Path

<!-- Optional navigation order for multi-chapter books -->

## Connections

<!-- Cross-references populated by BBP or manual annotation -->
```

**Body metadata block (below title, above Overview):**
```
Source file: `philosophy/aurelius-meditations.pdf`
Library: `/Users/tess/research-library/philosophy/aurelius-meditations.pdf`
Source: LibGen via Anna's Archive | Format: PDF | Size: 1.2 MB
Edition: Long translation, 1862 | Language: en
Rights: Public domain
AA ID: md5:abc123def456
```

**Schema reconciliation notes:**
- `domain: learning` is correct — the source-index note is a *learning* artifact even though the book-scout *project* is software domain. These are different things.
- `status: active` is required because source-index notes live in `Sources/books/` (non-project location). File-conventions.md: "Required fields (non-project): project, domain, type, status, created, updated."
- `date_ingested` is NOT a source-index field — it belongs to the knowledge-note schema. The `created` date serves as ingestion date.
- `canonical_url` is included per the canonical schema (set to AA URL if URLs are stable, null otherwise — determine in M0).
- Body sections follow the canonical structure: Header, Overview, Notes, Reading Path, Connections.

BBP discovers unprocessed books by querying source-index notes in `Sources/books/` where the Notes section contains no knowledge-note links.

## 7. Research Library Structure

`/Users/tess/research-library/` — owned by tess user.

```
/Users/tess/research-library/
  philosophy/
  history/
  fiction/
  biography/
  spirituality/
  science/
  unsorted/          ← default if no subject classification
```

**Naming convention:** `[author-lastname]-[short-title].pdf`
- `aurelius-meditations.pdf`
- `plato-republic.pdf`
- `dostoevsky-brothers-karamazov.pdf`
- Collisions: append year (`smith-wealth-of-nations-1776.pdf`)

**Subject assignment:** Tess proposes based on search metadata and query context. Danny can override via Telegram reply. Unclassifiable files → `unsorted/`.

### 7.1 Subject → Tag → Topic Mapping

This table maps library subject directories to canonical `#kb/` tags and MOC topics. Tess uses it when generating catalog JSON; Crumb uses it when creating source-index notes.

| Library Subject | `#kb/` Tag | `topics` Value | Notes |
|-----------------|-----------|----------------|-------|
| `philosophy` | `kb/philosophy` | `moc-philosophy` | Includes ethics, logic, epistemology |
| `history` | `kb/history` | `moc-history` | Political, military, social history |
| `fiction` | `kb/writing` | `moc-writing` | Classic and literary fiction |
| `biography` | `kb/history` | `moc-history` | Biographies map to history by default; override if subject-specific |
| `spirituality` | `kb/religion` | `moc-religion` | Includes theology, mysticism, religious texts |
| `science` | `kb/philosophy` | `moc-philosophy` | Natural philosophy, history of science. Revisit if `kb/science` is later canonized. |
| `unsorted` | — | — | No tags assigned; operator classifies during Crumb processing |

**Rules:**
- One subject per book (primary). Multiple `#kb/` tags are allowed if a book spans domains (e.g., a biography of a philosopher could get both `kb/history` and `kb/philosophy`).
- Tess assigns the primary subject from the mapping. Danny can override or add secondary tags via Telegram.
- If a book doesn't fit any subject, use `unsorted/` — Crumb flags it during catalog processing for manual classification.
- New subjects require: (1) creating the library directory, (2) adding a row to this table, (3) confirming the `#kb/` tag is canonical per file-conventions.md.

## 8. Tess Tool Design

### 8.1 Tool Capabilities

| Capability | Input | Output |
|------------|-------|--------|
| `book_search` | Query string, optional filters (format, year range, language) | Structured result list (max 20) |
| `book_download` | List of items (from search results) with target paths | Downloaded files + catalog JSONs |

Two tools, not three. No separate `download_status` — downloads are inline, Tess reports results directly.

**Format preference:** PDF is the preferred format. When searching, filter or rank results to prioritize PDF. When multiple editions exist, prefer PDF over EPUB, DJVU, or MOBI. If a title is only available in non-PDF format, surface it but flag the format clearly so Danny can decide. This aligns with batch-book-pipeline (PDF-only processing) and avoids format conversion complexity.

### 8.2 Implementation Approach

> **Updated post-M0 (r2):** Search uses HTML scraping, not JSON API.

**Native OpenClaw tool (Node.js)** — consistent with existing tool patterns (x-feed-intel). No MCP server overhead, no external script wrapper.

The tool:
- Reads API key from Keychain at invocation time (never stored in config or manifests)
- **Search:** Makes HTTP request to AA search page, parses HTML response with `cheerio` (Node.js HTML parser) to extract structured results. Browser User-Agent required (DDoS-Guard).
- **Download URL:** Calls JSON API (`/dyn/api/fast_download.json`) with MD5 hash and API key
- For downloads: executes curl subprocess, verifies MD5, moves file to target path
- Writes catalog JSON to `_openclaw/tess_scratch/catalog/`

**Dependencies:** `cheerio` (HTML parsing for search results). No other external dependencies.

### 8.3 Implementation Options Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Native OpenClaw tool (Node.js) | Consistent patterns, direct invocation, simple | Coupled to OpenClaw | **Selected** |
| External script + tool wrapper | Isolated, testable independently | Extra layer, deployment complexity | Rejected |
| MCP server (annas-mcp Go binary) | Protocol-standard, existing binary exists | MCP overhead, process management, Go dependency | Rejected |

## 9. Facts, Assumptions, and Unknowns

### Facts
- F1: ~~Anna's Archive offers a JSON API for programmatic access (donation-gated).~~ **Updated (M0):** AA offers a JSON API for *download URL retrieval only*. Search is HTML-only. See `design/api-research.md`.
- F2: ~~Danny's API key donation is in progress.~~ **Resolved (M0):** API key obtained, stored in Keychain as `book-scout.annas-archive-api-key`.
- F3: The Mac Studio runs macOS with multi-user setup (tess, openclaw, danny).
- F4: `_openclaw/tess_scratch/` exists as a bidirectional scratch space with group-write permissions.
- F5: The crumb-tess-bridge is DONE with a hard-coded operation allowlist; adding operations requires spec + code changes.
- F6: Source-index notes are already defined in file-conventions.md with a complete schema.
- F7: Batch-book-pipeline processes acquired books into knowledge digests (downstream, independent).
- F8: OpenClaw tools follow a Node.js module pattern (consistent with x-feed-intel).
- F9: Tess runs on Haiku 4.5.

### Assumptions
- A1: ~~The AA JSON API provides search-by-query and download-URL-by-ID endpoints.~~ **INVALIDATED (M0).** Search is HTML-only. Download URL retrieval is JSON. BSC-003 uses HTML scraping (cheerio) for search.
- A2: ~~API responses include: title, author, year, format, file size, source library, MD5 hash.~~ **VALIDATED (M0).** All fields available in HTML search results.
- A3: ~~Rights/license metadata is available in API responses (at least partially).~~ **PARTIALLY VALIDATED (M0).** Book type (fiction/nonfiction) available. No explicit license field — `rights_info` will be limited.
- A4: ~~Download URLs are direct HTTP links (not requiring session/cookie negotiation).~~ **VALIDATED (M0).** Direct HTTP, token-based URLs.
- A5: ~~curl is sufficient for downloads (no CAPTCHA, no JavaScript rendering).~~ **VALIDATED (M0).** Works with domain_index≥1.
- A6: ~~API rate limits are permissive enough for interactive search (responses within seconds).~~ **VALIDATED (M0).** 50 downloads/day, search unlimited.
- A7: The OpenClaw tool registration pattern supports HTTP-calling tools without special config. **Validate in M1 — check existing FIF/x-feed-intel patterns.**

### Unknowns
- U1: ~~Exact API endpoints, request format, and response schema.~~ **RESOLVED (M0).** See `design/api-research.md`.
- U2: ~~API rate limits and throttling behavior.~~ **RESOLVED (M0).** 50 downloads/day per-unique-MD5.
- U3: ~~Download URL lifetime — stable or time-limited?~~ **RESOLVED (M0).** Token-based, time-limited. Download immediately after URL retrieval.
- U4: ~~Whether AA API returns rights metadata and in what format.~~ **RESOLVED (M0).** Book type (fiction/nonfiction) in metadata. No explicit license field.
- U5: ~~Disk budget for research library (available space on Mac Studio).~~ **RESOLVED (M0).** 820 GB free.
- U6: ~~Whether `aria2c` is installed on Mac Studio.~~ **RESOLVED (M0).** Not installed. curl is sufficient per AD-1.
- U7: OpenClaw tool registration pattern for HTTP-calling tools. **Resolve in M1 (BSC-003).**

## 10. Threat Model

| ID | Threat | Rating | Mitigation |
|----|--------|--------|------------|
| BST-1 | API key exposure in logs or tool output | MEDIUM | Keychain storage, key read at invocation time, never logged or written to files |
| BST-2 | Malicious file download (PDF exploit) | LOW | MD5 verification against API hash; files stored outside vault; operator reviews before opening |
| BST-3 | Path traversal via crafted metadata | MEDIUM | Tool validates all file paths against `/Users/tess/research-library/` prefix; rejects anything outside |
| BST-4 | Catalog injection via crafted book metadata | MEDIUM | Catalog JSON uses strict field validation; Crumb validates on processing; source-index notes use fixed template |
| BST-5 | API quota exhaustion | LOW | Rate limiting in tool; usage telemetry if API has limits |
| BST-6 | Stale download URLs | LOW | Download immediately after approval; retry fetches fresh URL on failure |
| BST-7 | Disk space exhaustion | MEDIUM | Pre-download space check: tool queries available disk before each download; warns if <1 GB free; aborts if <500 MB. Per-file size cap (100 MB) prevents single-file surprises. BSC-002 documents baseline disk budget. |

## 11. Cost Model

| Component | Cost | Frequency |
|-----------|------|-----------|
| Anna's Archive API key | One-time donation (amount TBD) | Once |
| API usage | Free with key | Per search |
| Download bandwidth | ISP | Per download |
| Disk storage | Existing Studio storage | Per book (~1-10 MB each) |
| Tess LLM cost (tool invocation) | ~$0.001/query (Haiku 4.5) | Per search |

Total ongoing cost: effectively zero beyond the initial donation.

## 12. Relationship to Other Projects

- **batch-book-pipeline:** Downstream consumer. BBP processes PDFs that Book Scout acquires. Handoff: source-index note exists without child knowledge notes → BBP picks it up. The projects are independent.

- **x-feed-intel / feed-intel-framework:** Architectural sibling. Same pattern: Tess-owned external API tool with Telegram interaction. Book Scout's tool follows FIF's adapter pattern.

- **crumb-tess-bridge:** Not a dependency. Catalog handoff uses file-based approach (tess_scratch) rather than bridge operations. Bridge remains unchanged.

- **knowledge-navigation:** Source-index notes created by Book Scout participate in the MOC system and `#kb/` tag network.

## 13. Domain Classification & Workflow

- **Domain:** software (system tooling for Tess + vault integration)
- **Project class:** system (produces code outside the vault — OpenClaw tool)
- **Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Rationale:** Multiple components (API tool, download logic, catalog handoff, Crumb processing), cross-system integration (OpenClaw, vault, filesystem), external API dependency.

## 14. Task Decomposition

### Milestone 0: Research & API Validation (gated on API key arrival)

**BSC-001** — API endpoint research and documentation
- Risk: medium (entire project depends on API shape)
- Tag: `#research`
- Acceptance: API endpoints documented with request/response schemas; search and download flows validated manually (curl); rate limits documented; download URL lifetime characterized
- **Kill/pivot criteria:** If M0 research reveals any of: (a) no JSON API exists, (b) API requires scraping/CAPTCHA, (c) download URLs require browser session — then HALT and present options to operator: pivot to alternative source (Open Library API, Internet Archive API), descope to manual-assist mode (Tess searches but operator downloads), or cancel project.
- Depends: API key arrival

**BSC-002** — Environment validation
- Risk: low
- Tag: `#research`
- Acceptance: curl verified for AA downloads; aria2c availability checked; disk space confirmed; `/Users/tess/research-library/` directory created with correct permissions; `_openclaw/tess_scratch/catalog/` directory created
- Depends: —

### Milestone 1: Tess Tool — Search

**BSC-003** — Implement `book_search` tool
- Risk: medium
- Tag: `#code`
- Acceptance: Tool registered in OpenClaw config; searches AA API by query; returns structured results (title, author, year, format, size, source library, rights info); handles API errors gracefully; API key read from Keychain
- Depends: BSC-001

**BSC-004** — Search result formatting for Telegram
- Risk: low
- Tag: `#code`
- Acceptance: Results formatted as numbered list within Telegram character limits; single-query and bulk-list modes supported; edition grouping for specific-title searches
- Depends: BSC-003

### Milestone 2: Tess Tool — Download

**BSC-005** — Implement `book_download` tool
- Risk: medium
- Tag: `#code`
- Acceptance: Downloads files via curl to `/Users/tess/research-library/[subject]/`; verifies MD5 when available; handles download failures with retry (up to 3); writes catalog JSON to `_openclaw/tess_scratch/catalog/`; reports success/failure per item
- Depends: BSC-001, BSC-003

**BSC-006** — Download notification and failure handling
- Risk: low
- Tag: `#code`
- Acceptance: Tess reports download results to Danny via Telegram (success count, file paths, failures with reasons); retry command supported for failed items
- Depends: BSC-005

### Milestone 3: Vault Integration

**BSC-007** — Crumb catalog processor
- Risk: medium
- Tag: `#code`
- Acceptance: Crumb reads catalog JSONs from `_openclaw/tess_scratch/catalog/`; creates source-index notes in `Sources/books/` per file-conventions.md schema; assigns `#kb/` tags and `topics` based on subject; vault-check passes; processed catalog JSONs are cleaned up
- Depends: BSC-005

**BSC-008** — BBP handoff validation
- Risk: low
- Tag: `#research`
- Acceptance: BBP can discover source-index notes without child knowledge notes; BBP can locate the PDF via `file_path` in source-index metadata; end-to-end flow validated: Book Scout acquires → source-index created → BBP processes → knowledge notes linked
- Depends: BSC-007

### Milestone 4: Hardening

**BSC-009** — Error handling and edge cases
- Risk: low
- Tag: `#code`
- Acceptance: Graceful handling of: API timeout, invalid API response, download URL expiration, disk full, duplicate book detection (same source_id already in vault), Telegram message length overflow for large result sets
- Depends: BSC-003, BSC-005, BSC-007

**BSC-010** — SOUL.md integration and documentation
- Risk: low
- Tag: `#writing`
- Acceptance: Tess SOUL.md updated with Book Scout capability description and usage patterns; tool invocation documented; catalog handoff protocol documented for Crumb operators
- Depends: BSC-009

## 15. External Code Repository

Per `project_class: system`, this project produces code outside the vault (OpenClaw tool). External repo gate applies — confirm code directory and initialize repo during PLAN phase. Convention: `~/openclaw/book-scout/` or extension of existing OpenClaw workspace (evaluate based on FIF's tool registration pattern).

## 16. Open Questions (Residual)

| ID | Question | Impact | Resolution |
|----|----------|--------|------------|
| U1 | AA API exact endpoints and response schema | Blocks M1 | BSC-001 (M0 research) |
| U2 | API rate limits | Affects search UX | BSC-001 |
| U3 | Download URL lifetime | Affects retry strategy | BSC-001 |
| U4 | Rights metadata fields | Affects info surfaced to user | BSC-001 |
| U5 | Disk budget on Mac Studio | Affects size filtering | BSC-002 |
| U6 | aria2c availability | Affects download resilience | BSC-002 |
| U7 | OpenClaw tool registration for HTTP tools | Affects BSC-003 implementation | BSC-003 (check FIF patterns) |
