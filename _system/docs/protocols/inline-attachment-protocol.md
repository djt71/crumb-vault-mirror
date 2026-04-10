---
project: null
domain: software
type: reference
skill_origin: null
status: active
created: 2026-02-18
updated: 2026-02-18
tags:
  - crumb
  - binary-attachments
---

# Inline Attachment Protocol (Path A)

## Purpose

This protocol governs how binary artifacts are ingested during a governed Claude Code session — when a skill or the orchestrator produces, captures, or receives a binary file as part of project work. It bypasses `_inbox/` entirely because the session already has full context (project, domain, task).

This is a cross-cutting protocol, not a skill. Any skill or workflow step that produces a binary artifact follows this protocol.

## When This Protocol Applies

- A screenshot is captured as convergence evidence during IMPLEMENT
- A diagram is generated or exported during PLAN or DESIGN
- A tool export is produced during a task (e.g., DNS zone export, database dump)
- A user provides a file during a project session ("here's the document from the client")
- Any binary artifact is created or received while a project context is active

## Procedure

### 1. Save the binary

Save to `Projects/[project-name]/attachments/` using the filename convention from §2.2.2:

- Screenshots: `screenshot-[project]-[task]-[slug]-YYYYMMDD-HHMM.[ext]`
- Diagrams: `diagram-[project]-[slug]-v[NN].[ext]`
- Inbound documents: `inbound-[source]-[slug]-YYYYMMDD.[ext]`
- Generated exports: `export-[project]-[slug]-YYYYMMDD.[ext]`

Create the `attachments/` directory if it doesn't exist.

### 2. Extract content (if applicable)

For text-extractable files (PDF, DOCX, PPTX, XLSX):
```bash
markitdown <filepath>
```

For images: run `markitdown <filepath>` for EXIF metadata. Place in `## Notes`.

### 3. Create companion note

Write the companion note colocated with the binary, using the canonical schema from the inbox-processor skill's Output Constraints section. Key differences from inbox processing:

- `skill_origin: inline-attachment` (not `inbox-processor`)
- `attachment.source: generated` (for tool/session outputs) or `external` (for user-provided files)
- `project`: always populated (session context provides this)
- `description`: always populated (session context provides enough for a meaningful description)
- `related.task_ids`: populate if the binary is evidence for a specific task
- `related.docs`: populate if the binary is referenced by design docs, specs, etc.
- Omit `status` (project-scoped)

Because the session has full context, companion notes from Path A should be higher quality than inbox drops — descriptions should be meaningful, not stubs.

### 4. Log the attachment

Log in the current run-log entry under `**Files Modified:**`:
```
- Projects/[project]/attachments/[filename] — [brief description]
- Projects/[project]/attachments/[filename]-companion.md — companion note
```

If the binary is evidence for a specific acceptance criterion, note the companion note path in the task's run-log context.

## File Size Gate

If the file exceeds 10MB, flag to user before saving: "This file is [X]MB. Confirm you want to store it, or consider compressing or linking to external storage."

## Crash Resilience

Follow the same write order as the inbox processor: write companion note first, then save/move the binary. If the process is interrupted, Path D (orphan sweep) catches any binary without a companion note.

## What This Protocol Does NOT Do

- Does not process `_inbox/` — that's the inbox-processor skill
- Does not handle files without project context — those go through `_inbox/` (Paths B/C)
- Does not handle orphan detection — that's Path D in the inbox-processor skill
- Does not prompt for domain or project — the session already knows both
