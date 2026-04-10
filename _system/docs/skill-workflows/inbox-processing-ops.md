---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Inbox Processing

Two inboxes feed the vault from different directions: `_inbox/` is Danny's manual drop zone
for files and documents; `_openclaw/inbox/` is the automated intake for FIF feed intel and
Tess quick-captures. Each has its own processing path.

## Two Inboxes

### _inbox/ (Crumb — manual intake)

**What goes here:** Files Danny drops manually — PDFs, PPTX/DOCX downloads, screenshots,
images, markdown notes, NotebookLM exports.

**How it's processed:** `/inbox-processor` skill. Also triggered at session startup when
files are detected. Operator says "process inbox", "check inbox", or "orphan sweep".

**What comes out:**
- Markdown files → classified vault notes with YAML frontmatter, routed to correct domain dir
- Binary files (PDF, DOCX, PPTX, images) → companion notes in `_attachments/[domain]/`
  or `Projects/[name]/attachments/`, binary moved alongside
- NLM exports → knowledge-notes in `Sources/[type]/`, source-index notes, MOC Core entries
- Orphan sweep → retroactively creates companion notes for untracked binaries

### _openclaw/inbox/ (Tess / FIF — automated intake)

**What goes here:** Two item types arrive automatically:
- `feed-intel-*.md` — FIF pipeline triage output (X posts, RSS articles, HN, arXiv)
- `capture-*.md` — Tess quick-captures written by the Tess bridge (URLs, research notes,
  read-later items) via the `quick-capture` skill

**How it's processed:**
- Feed intel → `/feed-pipeline` skill. Operator says "process feed items" or "feed pipeline".
  Also handles dashboard-queued promotions from Mission Control.
- Quick-captures → Crumb reads and processes at next session. Hint field (`research`, `file`,
  `read-later`, `review`) tells Crumb what action to take.
- Non-feed items (session context files, research notes dropped by Tess) → read directly,
  route as appropriate for the session.

**What comes out:**
- Tier 1 items → signal-notes in `Sources/signals/` + MOC Core placement
- Tier 2 items → action items appended to project run-logs
- Tier 3 items → no action, TTL cron purges after 14 days
- Review-queue → `_openclaw/inbox/review-queue-YYYY-MM-DD.md` for borderline items
- Quick-captures → research synthesis, vault notes, or reading-list entries depending on hint

## Processing Skills by Content Type

| Content | Skill | Trigger |
|---|---|---|
| General files (any type) dropped in `_inbox/` | `/inbox-processor` | "process inbox", session startup |
| Vendor decks / analyst PDFs needing intel extraction | `/deck-intel` | "process this deck", "extract intel" |
| Images and diagrams inside binaries | `/diagram-capture` | Called by deck-intel or inbox-processor; or directly for visual content |
| FIF feed intel items in `_openclaw/inbox/` | `/feed-pipeline` | "process feed items", "feed pipeline" |
| Tess quick-captures written to `_openclaw/inbox/` | `quick-capture` (Tess writes) + Crumb processes | Items arrive automatically; Crumb acts on hint |

**Composability note:** `diagram-capture` is a sub-skill. `deck-intel` calls it for image-heavy
slides; `inbox-processor` calls it for image files. It can also run standalone.

## Operator Actions

**Danny:**
- Drop files in `_inbox/` — Crumb detects at startup or when told "check inbox"
- Say "process inbox" to run a full batch, "orphan sweep" to catch untracked binaries
- Say "process feed items" or "feed pipeline" to work through FIF inbox
- Use Mission Control dashboard to flag feed items for promotion (dashboard-queued path)

**Tess (automated):**
- Feed intel arrives automatically via FIF adapters — no manual action
- Quick-captures: tell Tess "save this for Crumb", "capture this URL", "read later [link]"
  — Tess writes to `_openclaw/inbox/` with a processing hint; Crumb picks it up next session
