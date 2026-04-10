---
project: book-scout
domain: software
type: design
status: active
created: 2026-02-28
updated: 2026-02-28
tags:
  - openclaw
  - tess
  - automation
  - research-library
---

# Anna's Archive API Research — BSC-001

## Key Finding: No JSON Search API

The spec assumed a JSON search API (assumptions A1-A6). In reality:

- **Search:** HTML-only. No JSON search endpoint exists (tested `/dyn/api/search.json` — 404).
- **Download URL retrieval:** JSON API exists and works. `/dyn/api/fast_download.json`
- **This does NOT kill the project.** Search requires HTML parsing, which is how all existing implementations work (annas-mcp Go project uses colly web scraper). The download API is the critical path and it works perfectly.

**Official confirmation:** AA blog post ([llms-txt.html](https://annas-archive.li/blog/llms-txt.html)) states: *"We don't yet have a search API."* Their recommendation is `aa_derived_mirror_metadata` (344-484 GB bulk download) — not viable for a personal tool with occasional searches. HTML parsing with browser User-Agent is the established pattern across all existing integrations (annas-mcp, archive_of_anna, Dart SDK). CAPTCHAs exist for mass scraping prevention; occasional personal use with proper User-Agent works reliably.

## Endpoints

### Search (HTML)

```
GET https://{domain}/search?q={query}&content={type}&ext={format}
```

**Parameters:**
| Param | Required | Values | Notes |
|-------|----------|--------|-------|
| `q` | yes | URL-encoded query string | Free-text search |
| `content` | no | `book_any`, `book_fiction`, `book_nonfiction`, `book_comic`, `journal`, `magazine`, `standards` | Default: all types |
| `ext` | no | `pdf`, `epub`, `mobi`, `djvu`, etc. | Format filter — present but does NOT exclusively filter (mixed formats still returned) |
| `index` | no | `meta` (default), `journals`, `digital_lending` | Collection index |
| `lang` | no | Language code | Language filter |

**Response:** HTML page. Search results are `<a href="/md5/{hash}">` elements with adjacent metadata divs.

**Result metadata structure** (extracted from HTML):
- **Title:** Text of `a[href^='/md5/']` link within `div.max-w-full`
- **Authors:** Adjacent link with `span.icon-[mdi--user-edit]`
- **Publisher:** Adjacent link with `span.icon-[mdi--company]`
- **Metadata line:** Format: `{language} [{code}] · {FORMAT} · {size} · {year} · {type_emoji} · {sources}`
  - Example: `English [en] · PDF · 24.0MB · 1956 · 📘 Book (non-fiction) · 🚀/lgli/lgrs/nexusstc/zlib`
- **MD5 hash:** From link href `/md5/{hash}`
- **Cover image:** `img` within the result link

**Typical result count:** ~50 per page.

**Required HTTP headers:**
- `User-Agent`: Must be a realistic browser UA string. DDoS-Guard blocks non-browser UAs.
  - Working value: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36`

### Download URL Retrieval (JSON API)

```
GET https://{domain}/dyn/api/fast_download.json?md5={hash}&key={secret_key}&domain_index={n}&path_index={n}
```

**Parameters:**
| Param | Required | Type | Notes |
|-------|----------|------|-------|
| `md5` | yes | string | MD5 hash of the file (from search results) |
| `key` | yes | string | API key (from Keychain) |
| `domain_index` | no | int (0+) | Download server selection |
| `path_index` | no | int (0+) | Collection selection (if file in multiple collections) |

**Successful response (HTTP 200/204):**
```json
{
  "download_url": "https://server.org/path/to/file.pdf",
  "account_fast_download_info": {
    "downloads_left": 49,
    "downloads_per_day": 50,
    "recently_downloaded_md5s": ["332492e7757d3429a9eff9e30b7852ff"],
    "downloads_done_today": 1
  }
}
```

**Error response (HTTP 400/4xx):**
```json
{
  "download_url": null,
  "error": "Invalid md5"
}
```

**Self-documenting:** The response includes a `///download_url` field with full API documentation on every call.

## Rate Limits

- **50 downloads per day** (resets daily)
- Per-unique-MD5 counting: requesting the same MD5 multiple times does NOT re-decrement the counter
- `account_fast_download_info` in every response reports current quota status
- Search endpoint: no observed rate limit (but DDoS-Guard may throttle aggressive scraping)

## Download Servers (domain_index)

| domain_index | Server | Protocol | macOS curl | Status |
|---|---|---|---|---|
| 0 | asuycdg6.org | HTTPS | FAIL (TLS 1.3 required, LibreSSL 3.3.6 can't connect) | Avoid |
| 1 | 45.3.63.27:6060 | HTTP | OK | Working |
| 2 | hxd7ms.org | HTTPS | OK | Working |
| 3 | 195.128.249.105:6060 | HTTP | OK | Working |
| 4 | asuycdg5.org | HTTPS | OK | Working |

**Recommendation:** Use `domain_index=2` (HTTPS, working) as primary, with 1/3/4 as fallbacks. Avoid `domain_index=0`.

## Mirror Domains

| Domain | Status |
|---|---|
| annas-archive.li | Working (HTTP 200) |
| annas-archive.pm | Timeout |
| annas-archive.in | Timeout |

**Recommendation:** Use `annas-archive.li` as primary. Mirror availability varies.

## Download URL Characteristics

- **Content-Type:** `application/pdf` confirmed
- **Accept-Ranges: bytes** — supports range requests (resume capability)
- **Token-based:** URLs contain time-limited tokens (embedded in path)
- **Direct HTTP:** No CAPTCHA, no JavaScript, no session cookies required
- **PDF header verified:** First bytes are `%PDF-1.5` — standard PDF

## Assumption Validation

| Assumption | Result | Impact |
|---|---|---|
| A1: JSON search API exists | **FALSE** — HTML only | Search tool must parse HTML (cheerio/jsdom in Node.js) |
| A2: Response includes title, author, year, format, size, source library, MD5 | **TRUE** — all available in HTML | No change |
| A3: Rights/license metadata available | **PARTIAL** — type (fiction/nonfiction) visible, no explicit license field | `rights_info` will be limited to what's parseable |
| A4: Download URLs are direct HTTP | **TRUE** — direct, no session negotiation | No change |
| A5: curl sufficient for downloads | **TRUE** — works with correct domain_index | Use domain_index≥1 |
| A6: Rate limits permissive for interactive use | **TRUE** — 50/day is ample for personal use | No change |

## Curl Commands (Reproducible)

**Search:**
```bash
curl -s "https://annas-archive.li/search?q=meditations+marcus+aurelius&content=book_any" \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

**Download URL retrieval:**
```bash
curl -s "https://annas-archive.li/dyn/api/fast_download.json?md5={HASH}&key={API_KEY}&domain_index=2"
```

**File download:**
```bash
curl -o output.pdf "{DOWNLOAD_URL}" \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
```

## Kill/Pivot Decision

**PROCEED.** The project is viable with one architectural change:

- **Change:** BSC-003 (search tool) must use HTML scraping instead of JSON API. Add `cheerio` as a Node.js dependency for HTML parsing. This is a well-understood pattern and consistent with all existing AA integrations.
- **Risk acceptance:** HTML scraping is fragile (page structure changes break it). Mitigation: isolate parsing logic, make selectors configurable.
- **No other spec assumptions are invalidated.** Download flow works exactly as designed.
