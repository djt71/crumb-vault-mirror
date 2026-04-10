---
type: design-doc
project: crumb-tess-bridge
domain: software
status: draft
created: 2026-02-24
updated: 2026-02-24
tags:
  - openclaw
  - tess
---

# Tess Quick-Capture — Feature Scope

*Scoping document for a defined capture pathway from Telegram to the Crumb vault, separate from the bridge protocol.*

---

## Problem Statement

Tess can write files to `_openclaw/inbox/` via OpenClaw's skill system. When Danny sends a natural language request like "send this to Crumb for research," Tess's voice agent composes a plausible JSON file and writes it to the inbox. But:

1. The bridge watcher picks up all `.json` files indiscriminately and routes them to `bridge-processor.js`, which rejects them with `INVALID_SCHEMA` (no `operation`, no `schema_version`, no `request_id`)
2. This wastes rate limit budget on files the processor will always reject
3. Tess's voice agent improvises the capture schema on every invocation — no defined contract means unpredictable file structure
4. The user gets a confident acknowledgment ("Sent to Crumb") but nothing actually gets processed

Meanwhile, x-feed-intel already has a working non-bridge inbox pattern: `.md` files written to `_openclaw/inbox/` with `type: x-feed-intel` frontmatter. The bridge watcher ignores these (not `.json`). Crumb processes them during interactive sessions. This pattern works and should be reused.

## Design Principle: Two Paths, Two Purposes

The bridge protocol and quick-capture serve fundamentally different purposes and must remain separate:

| | Bridge Protocol | Quick-Capture |
|---|---|---|
| **Purpose** | Execute governed operations | Stage items for later processing |
| **Ceremony** | Echo → confirm → hash → validate → execute | Write → done |
| **Processing** | Automated (watcher + dispatch engine) | Queued for next Crumb session |
| **Governance** | Full CLAUDE.md, stage-level verification | Human review during processing |
| **Risk** | Medium-High (vault writes, task execution) | Low (creates a note for human triage) |
| **Schema** | Bridge JSON (strict, validated, versioned) | Markdown with YAML frontmatter (vault-native) |

An LLM should never generate bridge-schema JSON. The bridge protocol's security model depends on strict command parsing with no free-form NLU. Quick-capture is the correct path for natural language requests that amount to "save this for later."

## Proposed Solution

### 1. Defined OpenClaw Skill for Tess

Create an OpenClaw skill (`quick-capture`) that Tess's voice agent invokes when the user wants to stage something for Crumb. The skill defines:

- **Trigger patterns:** "send this to Crumb," "save this for later," "research this," "add this to the vault," "file this for me," or any request to pass a URL, article, idea, or note to Crumb
- **Output format:** Markdown file with YAML frontmatter (not JSON)
- **Output location:** `_openclaw/inbox/`
- **Filename pattern:** `capture-{YYYYMMDD}-{HHMMSS}.md` (distinguishable from bridge `.json` files and `feed-intel-*.md` files)

### 2. Capture File Schema

```yaml
---
type: quick-capture
source: telegram
captured_by: tess
captured_at: 2026-02-24T19:30:27Z
suggested_domain: learning
suggested_tags:
  - kb/design
processing_hint: research    # research | file | review | read-later
---

## What Does a Tool Owe You? — Dear Hermes article

User requested research on this article about tool obligations and design philosophy.

**URL:** https://dearhermes.com/read/kfniw9y/what-does-a-tool-owe-you

**Processing instructions:** Research this article and add findings/summary to vault. Include key takeaways about tool design philosophy and user expectations.
```

Key decisions in this schema:

- **`.md` not `.json`** — bridge watcher ignores it (only scans `.json`). Zero changes to bridge infrastructure.
- **`type: quick-capture`** — new type in the vault taxonomy. Distinct from `x-feed-intel` (pipeline-generated) and `knowledge-note` (fully processed). Represents user-initiated captures staged for processing.
- **`processing_hint`** — lightweight signal for what the user wants done. Not a command — Crumb decides how to actually process it during the interactive session. Enum values:
  - `research` — read the URL/content, synthesize findings, route to vault
  - `file` — just put it somewhere appropriate in the vault
  - `review` — read and provide assessment/commentary
  - `read-later` — queue for the user's reading list (low priority)
  - **Boundary note:** `research` and `review` will overlap in practice ("research this article" vs. "review this article" are near-identical from a user perspective). Until researcher-skill is built, Crumb should treat both similarly — fetch, synthesize, route. Differentiation can sharpen once there's a dedicated research pipeline to route into.
- **`suggested_domain` and `suggested_tags`** — Tess's best guess. Crumb overrides during processing if wrong. Prefix `suggested_` makes it clear these are proposals, not authoritative.
- **Body is free-form markdown** — Tess writes the user's request context, the URL, and any processing instructions in natural prose. No rigid structure to get wrong.

### 3. Bridge Watcher: No Changes Required for `.md` Routing

The watcher's `scan_inbox()` function only picks up `.json` files:

```python
if name.startswith('.') or name.startswith('tmp') or not name.endswith('.json'):
    continue
```

Markdown capture files are invisible to it. The three `feed-intel-*.md` files already demonstrate this pattern working in production.

> **Note:** §6 below recommends a separate defensive fix for non-bridge `.json` files.
> That's a distinct concern — protecting rate limit budget against improvised JSON writes,
> not a prerequisite for quick-capture `.md` routing.

### 4. Crumb-Side Processing

Quick-captures are processed during interactive Crumb sessions, not automatically. Two approaches, to be decided during implementation:

**Option A: Extend the inbox-processor skill.** Add a detection path for `type: quick-capture` files in `_openclaw/inbox/`. The inbox-processor already handles classification, user prompting, frontmatter generation, and vault routing. Quick-captures would be a new classification branch alongside "NLM export," "standard markdown," and "binary file."

**Option B: Standalone capture-processor step in session startup.** The `startup` skill checks `_openclaw/inbox/` for `capture-*.md` files and reports them: "Tess left 2 items for you: [title 1], [title 2]. Process now or defer?" If process now, Crumb reads each capture, executes the processing hint (research, file, review), and moves the capture file to `.processed/` when done.

**Recommendation: Option B.** The inbox-processor handles `_inbox/` (the user's manual drop zone). Quick-captures come from `_openclaw/inbox/` (Tess's drop zone). These are different directories with different ownership models. Mixing them in one skill adds complexity for no real benefit. A lightweight startup check keeps the paths clean and gives you visibility without forcing immediate action.

**`.processed/` cleanup policy:** Unprocessed captures don't expire (see Resolved Questions §1). But processed captures in `_openclaw/inbox/.processed/` are dead weight — the vault copy is the authoritative artifact. Purge `.processed/` files older than 30 days via vault-check or a manual sweep cadence. This aligns with the bridge's existing 30-day retention for dispatch state and stage outputs (CTB-027).

### 5. Vault Taxonomy Update

Add `quick-capture` to the type taxonomy in `_system/docs/file-conventions.md`:

| Type | Used For |
|---|---|
| `quick-capture` | User-initiated captures from Telegram via Tess, staged in `_openclaw/inbox/` for Crumb processing |

### 6. Rate Limit Protection

The current bridge watcher wastes rate limit budget rejecting non-bridge `.json` files. Two options:

**Option A (minimal):** Tess's quick-capture skill writes `.md`, not `.json`. Problem solved for captures. But if Tess's voice agent ever improvises a `.json` write again outside the skill, the same issue recurs.

**Option B (defensive):** Additionally, modify the watcher's `_parse_operation()` to short-circuit on files without an `operation` field — move them to a `_openclaw/inbox/.unrecognized/` directory and log a warning instead of feeding them to the bridge processor. This protects rate limit budget against any future non-bridge JSON files.

**Recommendation: Both.** Option A is the primary fix (captures are `.md`). Option B is a 10-line defensive change that prevents the class of problem, not just this instance. Option B should be an explicit task (CTB-035), not a buried recommendation.

## What This Does NOT Cover

- **Automatic processing** — captures always queue for human-supervised Crumb sessions. No daemon, no auto-dispatch.
- **Bridge protocol changes** — zero modifications to the bridge schema, watcher routing, or dispatch engine.
- **Research skill** — the `processing_hint: research` tells Crumb what the user wants, but actual research execution depends on the researcher-skill project (currently in SPECIFY). Until that's built, Crumb processes research captures using its general capabilities.
- **File transfer from Telegram** — if Danny sends a PDF or image via Telegram, that's a different problem (binary file handling through OpenClaw). Mentioned in the action plan summary as a Phase 3 candidate.
- **Bidirectional updates** — Tess doesn't get notified when Crumb finishes processing a capture. That's fine for now; Danny sees the results in his next terminal session.

## Scope Summary

| Component | Work | Risk | Effort |
|---|---|---|---|
| OpenClaw skill definition (`quick-capture`) | New skill file in Tess's workspace | Low | Small — skill template + trigger patterns + output format |
| Capture file schema | Define frontmatter + body convention | Low | Small — documented above |
| Vault taxonomy update | Add `quick-capture` to type enum | Low | Trivial — one line in file-conventions.md |
| Session startup check | Detect and report captures in `_openclaw/inbox/` | Low | Small — glob for `capture-*.md`, display titles |
| Capture processing procedure | Read capture → execute hint → route to vault → move to `.processed/` | Medium | Medium — depends on processing_hint complexity |
| Watcher defensive fix | Short-circuit non-bridge JSON files | Low | Trivial — ~10 lines in `_parse_operation()` or `dispatch_file()` |

## Resolved Questions

1. **URL validation at capture time?** No. Keep the skill simple — Crumb handles validation during processing. If enrichment (OG tags, page title) proves valuable later, that's a v2 addition.
2. **Capture expiry?** No. Stale captures are a low-cost problem (cluttered inbox, noticeable during startup check). Auto-deleting things the user asked to save is a worse failure mode. Manual sweep if needed.
3. **Pre-write confirmation echo?** No. Post-write confirmation is sufficient. Tess writes the capture, then confirms what she captured in Telegram. Captures are reversible (delete or ignore during processing), so pre-write ceremony adds friction without meaningful safety benefit.
