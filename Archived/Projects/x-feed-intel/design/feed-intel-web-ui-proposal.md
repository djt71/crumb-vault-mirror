---
type: reference
status: draft
project: x-feed-intel
domain: software
purpose: Design proposal for Crumb review — web-based digest UI for feed-intel-framework
created: 2026-02-23
updated: 2026-02-23
source: claude-ai peer review session
---

# Proposal: Web-Based Digest UI for Feed Intelligence Framework

## Context

Danny has reviewed the current digest format (x-feed-intel §5.7, framework §5.6) and wants to move the digest presentation from Telegram messages to a private web application. This applies at the framework level — all sources would render through the web UI, not just X.

Telegram remains the **notification channel** ("3 high priority items today → [View digest]") and the **command channel** for quick replies. The web page becomes the primary **reading and interaction surface**.

## Why This Makes Sense

- Telegram is poor for scanning structured content with 15+ items
- No ability to filter, sort, collapse sections, or search across past digests in a chat thread
- Typing `A01 promote` on a phone is clunky vs. tapping a button
- Digests scroll away in chat history — no persistent reference
- The 4,096-char Telegram limit and multi-message splitting is a workaround, not a design
- A web UI scales naturally as more sources come online (X, RSS, YouTube, etc.)

## What Changes

### Telegram becomes notification-only

Current Telegram digest message is replaced with a short notification:

```
📡 Feed Intel — Feb 23, 2026
3 🔴 high · 8 🟡 medium · 5 ⚪ low
Sources: X (12), RSS (4)
→ https://[digest-url]/2026-02-23
```

The reply-based control protocol (§5.8 in both specs) can remain as a secondary interaction path — Danny can still reply to the notification with `A01 promote` if he wants a quick action without opening the web page. But the web UI becomes the primary way to review and act on items.

### Web UI serves the digest

A private web application that renders the daily digest with:

- **Scannable layout:** High/medium/low sections, collapsible
- **Per-item actions:** Promote, ignore, save, add-topic — clickable buttons that hit a local API
- **Direct links:** Each item links to the original post/article
- **Source filtering:** Show all sources, or filter to just X, just RSS, etc.
- **Past digests:** Browse by date, not just today
- **Search:** Full-text search across past digest items (optional, leverages SQLite FTS)
- **Cost dashboard:** MTD spend per source, projected monthly, guardrail status
- **Mobile-friendly:** Danny needs to read this on his phone too

### Feedback API endpoint

Actions from the web UI need a backend to process them. Currently feedback flows through Telegram reply parsing (XFI-022 in x-feed-intel). The web UI needs an HTTP API that accepts the same commands:

```
POST /api/feedback
{ "item_id": "A01", "command": "promote", "digest_date": "2026-02-23" }
```

This endpoint writes to the same `feedback` table in SQLite. The Telegram feedback listener continues to work in parallel — both paths write to the same store. No conflict because feedback commands are idempotent.

## Architecture Questions for Crumb

### 1. Hosting and Access

The web UI must be private (only Danny) but accessible from anywhere (phone, laptop, not just local network). Options:

**A. Cloudflare Tunnel + Cloudflare Access**
- Tunnel exposes the local web server on the Studio to the internet via Cloudflare's network
- Cloudflare Access adds authentication (email OTP — Danny gets a code sent to his email, enters it, gets a session cookie)
- No port forwarding, no public IP needed
- Free tier covers this use case
- Pros: Zero-trust security, works from anywhere, no VPN client needed
- Cons: Depends on Cloudflare, requires a domain name

**B. Tailscale**
- Creates a private mesh network. The Studio and Danny's devices join the same tailnet.
- Web server listens on the Studio's Tailscale IP — only accessible from devices on the tailnet.
- Pros: Simple, zero-config, no domain needed, no third party in the request path
- Cons: Requires Tailscale client on every device Danny wants to access from; not accessible from a random browser (e.g., work computer without Tailscale)

**C. VPS + reverse proxy**
- Deploy the web server on a cheap VPS, or proxy from VPS to Studio
- Pros: Full control, standard hosting
- Cons: More infrastructure to manage, data either lives on the VPS (away from the pipeline) or needs sync

**D. Static site on Cloudflare Pages + API on Studio via Tunnel**
- Pre-rendered HTML digest pushed to Cloudflare Pages (free, global CDN)
- API endpoint on Studio exposed via Cloudflare Tunnel for feedback actions
- Pros: Fast static delivery, API stays colocated with data
- Cons: Split architecture, more complex deployment

**My lean:** Option A (Cloudflare Tunnel + Access) gives the best balance of security, accessibility, and simplicity. Danny can access it from any browser on any device by authenticating with his email. No VPN client required. The web server runs on the Studio colocated with the pipeline data.

### 2. Tech Stack

The pipeline is Node.js/TypeScript (OpenClaw stack). The web UI should match:

**Minimal approach:** Express server serving server-rendered HTML pages. No SPA framework needed — the data changes once a day. A simple template engine (EJS, Handlebars, or even template literals) renders the digest from SQLite data. CSS framework like Tailwind for styling. This is a read-heavy, low-interaction app — it doesn't need React.

**Slightly richer:** If Danny wants snappier interactions (inline promote/ignore without page reload), add lightweight client-side JS for the action buttons (fetch API calls to the feedback endpoint). Still no SPA — just progressive enhancement on server-rendered pages.

### 3. Where This Lives

Options:

**A. Inside the feed-intel-framework repo** — the web UI is a component of the framework, alongside shared infrastructure and adapters. Deployed from the same codebase.

**B. Separate repo** (e.g., `~/openclaw/feed-intel-web`) — the web UI is its own project that consumes the framework's SQLite database and serves the presentation layer.

**My lean:** Option A. The web UI is tightly coupled to the data model (it reads from the same SQLite DB, uses the same triage schema, writes to the same feedback table). Separating it adds deployment complexity without meaningful architectural benefit. It's a component, not an independent service.

### 4. Relationship to Current Specs

This proposal touches both specs:

**x-feed-intel spec (v0.4.3):**
- §5.7 (Daily Digest) — Telegram message format becomes notification-only; digest presentation moves to web UI
- §5.8 (Reply-Based Control Protocol) — remains as secondary path; web UI adds HTTP API as primary feedback channel
- XFI-019 (digest formatting) and XFI-022 (feedback listener) tasks — scope changes

**feed-intel-framework spec (v0.3):**
- §5.6 (Per-Source Digests) — major rewrite to describe web-based presentation instead of Telegram messages
- §5.7 (Reply-Based Control Protocol) — gains HTTP API as primary feedback path
- New section needed for web UI architecture, hosting, and auth
- Phasing — web UI needs to be sequenced. Options:
  - Build with x-feed-intel Phase 1 (before framework extraction)
  - Build during Phase 1b (when framework is extracted)
  - Build as a separate workstream in parallel

### 5. Sequencing

The web UI could be:

**Option 1: Part of x-feed-intel M2/M3** — build the web UI for X-only first, then generalize during framework extraction. This gets Danny the better reading experience sooner but means building it twice (X-specific, then multi-source).

**Option 2: Framework-level from the start** — build the web UI when the framework is extracted (Phase 1b). Multi-source from day one. But Danny reads Telegram digests until then.

**Option 3: Hybrid** — x-feed-intel ships with Telegram digest as specced (M1 tasks are nearly done). The web UI is a new project that starts after M0 closes, reading from the same SQLite DB. When the framework extraction happens, the web UI naturally generalizes because it already reads from the shared data model.

**My lean:** Option 3. Don't delay x-feed-intel M1 by re-scoping the digest. Build the web UI as a parallel workstream that consumes the x-feed-intel pipeline's data. It becomes the framework's presentation layer naturally during Phase 1b extraction.

## New Feedback Action: Investigate

The current feedback protocol supports `promote`, `ignore`, `save`, and `add-topic`. Danny wants a fifth action: **investigate** — "this looks like it could be a project or a significant capability change; I want Tess and Crumb to go deeper."

This is distinct from:
- **promote** — "this is relevant to current Crumb architecture, stage it for review"
- **save** — "persist this as knowledge"
- **investigate** — "there might be a project here, or a significant change to how we work — research it"

### Proposed Flow

1. Danny taps **Investigate** on a digest item in the web UI
2. Optionally adds a note (free text): context on what caught his eye, what question he wants answered, or blank for "just look into this"
3. Item is staged to `_openclaw/feeds/investigate/` with frontmatter:
   ```yaml
   type: investigation-request
   canonical_id: "x:1234567890"
   source_item: "feed-intel-x-1234567890.md"  # if already routed
   requested_at: "2026-02-23T14:30:00Z"
   operator_note: "Could this replace our current context checkpoint approach?"
   status: pending  # pending | researching | complete | declined
   ```
4. Tess picks up pending investigation requests (could be part of the attention clock, or a separate sweep)
5. Tess does initial research:
   - Fetches the full content (thread expansion, linked articles, related posts)
   - Pulls related items from the pipeline's history (same author, same topic, similar `url_hash`)
   - Writes a brief assessment: what is this, why it might matter, how it relates to current projects/architecture, open questions
6. Assessment is written back to the same file (status → `complete`) or to `_openclaw/inbox/` as an investigation brief with `type: investigation-brief`
7. During a Crumb session, Danny and Crumb review the brief. Outcomes:
   - **New project** → Crumb initiates Project Creation Protocol
   - **Fold into existing project** → Crumb adds to relevant project's backlog/spec
   - **Capture as KB** → Route to permanent KB location
   - **Discard** → Mark as declined, log reasoning

### Design Questions

- **Where does the investigation request live?** `_openclaw/feeds/investigate/` (new Tess-owned directory, parallel to `kb-review/`) keeps it within the feed-intel directory structure. Alternatively, route directly to `_openclaw/inbox/` with a distinct type — but that mixes investigation requests with promote-routed items.
- **Who does the research?** Tess is the natural owner (she operates the pipeline, has API access, can fetch content). Crumb reviews the output during governed sessions. This follows the existing boundary: Tess gathers and prepares, Crumb decides.
- **Automation vs. manual trigger:** Investigation requests are always operator-initiated (Danny taps the button). Tess never auto-investigates. This keeps the investigation queue small and intentional.
- **Does this affect the feedback table schema?** Yes — `investigate` becomes a new `command` value in the `feedback` table. The `argument` field stores the operator note.

## Decision Points for Danny + Crumb

1. **Hosting model:** Cloudflare Tunnel + Access, Tailscale, VPS, or other?
2. **Tech stack:** Server-rendered Express + templates, or something richer?
3. **Repo location:** Inside framework repo or separate?
4. **Sequencing:** Part of x-feed-intel, framework-only, or parallel hybrid?
5. **Scope of Telegram changes:** Notification-only, or keep the full digest in Telegram as a fallback alongside the web UI?
6. **Does Crumb see architectural concerns** with the web UI reading directly from the pipeline's SQLite DB, or should there be an API abstraction layer?
7. **Investigate action:** Does the proposed flow (stage → Tess research → brief → Crumb review) fit the existing agent boundary model? Should investigation requests go to `_openclaw/feeds/investigate/` or `_openclaw/inbox/`?
