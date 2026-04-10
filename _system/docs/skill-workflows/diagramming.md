---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Diagramming

Three skills for different diagram contexts: Mermaid for vault-native inline diagrams, Excalidraw for freeform visual artifacts, and Lucidchart for anything that needs to leave the vault.

## Skills in This Workflow

### /mermaid
**Invoke:** "diagram this", "visualize this", "mermaid", "chart", or any diagram request without other qualifiers.
**Inputs:** Description of what to visualize; diagram type inferred or explicit.
**Outputs:** Mermaid fenced code block embedded inline in a markdown file, or standalone `[topic]-diagram.md` in `_inbox/`.
**What happens:**
- Selects diagram type (flowchart, sequence, ERD, state, gantt, mind map, kanban, etc.)
- Generates syntax-valid mermaid block; validates node IDs, direction, edge label format
- Saves inline to the relevant note or as a standalone file in `_inbox/`

### /excalidraw
**Invoke:** "draw this", "sketch this", "excalidraw", "wireframe", or when freeform spatial layout or hand-drawn aesthetic is needed.
**Inputs:** Description of what to visualize; diagram type and style (formal vs. casual) inferred or stated.
**Outputs:** `.excalidraw` JSON file saved to `Projects/[project]/attachments/` (project sessions) or `_inbox/`.
**What happens:**
- Plans layout and grid positions before generating JSON
- Produces valid `.excalidraw` file with bidirectional bindings and unique seeds
- Runs `validate-excalidraw.py` to verify structural integrity before delivery

### /lucidchart
**Invoke:** "push to Lucid", "make this shareable", "I need this for a customer", "lucidchart", or `/lucidchart`.
**Inputs:** Description of what to visualize; confirmation that diagram needs external sharing. API key in `~/.config/crumb/.env`.
**Outputs:** `.lucid` ZIP pushed to Lucidchart API; returns `editUrl` + `viewUrl`. Vault reference note saved with document ID and URLs.
**What happens:**
- Generates Standard Import JSON with explicit coordinates; packages as `.lucid` ZIP
- Pushes to Lucidchart REST API; parses response for URLs
- Creates vault reference note; instructs user to open `viewUrl` first (triggers propagation)

## When to Use Which

| Situation | Skill |
|---|---|
| Diagram stays in the vault, text-heavy, version-controlled | **mermaid** (default) |
| Inline visualization during analysis or planning | **mermaid** |
| Freeform layout, wireframes, UI mocks, hand-drawn look | **excalidraw** |
| Standalone visual artifact is the deliverable | **excalidraw** |
| Customer deliverable, external stakeholder, shareable URL needed | **lucidchart** |
| Team collaboration in Lucidchart, or converting a vault diagram for external use | **lucidchart** |

**Tie-breakers:** Mind maps → mermaid for text outlines, excalidraw for spatial brainstorming. ERDs → mermaid unless freeform layout needed. When unclear and no external sharing is implied, default to mermaid.
