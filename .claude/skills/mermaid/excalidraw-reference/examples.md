---
type: reference
domain: software
status: active
skill_origin: excalidraw
created: 2026-02-20
updated: 2026-02-20
tags:
  - reference
  - excalidraw
  - diagramming
---

# Excalidraw Diagram Examples

Working JSON templates for common diagram types. **Load only when you need a complete JSON template to work from.** For most diagrams, the main SKILL.md has sufficient guidance.

**When using these templates:** You MUST generate new random integers for all `id`, `seed`, and `versionNonce` fields. The values below (1001, 1002, etc.) are placeholders for readability. Copying them verbatim will cause collisions if multiple diagrams are created in the same project.

## Complete Flowchart

A decision flowchart with Start → Decision → Yes/No branches. Demonstrates: ellipse, diamond, rectangle, arrow bindings, text containers, edge labels.

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [
    {
      "type": "ellipse",
      "id": "start",
      "x": 200, "y": 50, "width": 100, "height": 60,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "#b2f2bb",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1001, "version": 1, "versionNonce": 1001,
      "isDeleted": false, "groupIds": [],
      "boundElements": [
        { "id": "text-start", "type": "text" },
        { "id": "arrow-1", "type": "arrow" }
      ],
      "link": null, "locked": false
    },
    {
      "type": "text",
      "id": "text-start",
      "x": 225, "y": 68, "width": 50, "height": 25,
      "text": "Start", "fontSize": 20, "fontFamily": 2,
      "textAlign": "center", "verticalAlign": "middle",
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1002, "version": 1, "versionNonce": 1002,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "containerId": "start", "originalText": "Start",
      "autoResize": true, "lineHeight": 1.25
    },
    {
      "type": "diamond",
      "id": "decision",
      "x": 175, "y": 180, "width": 150, "height": 120,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "#ffec99",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1003, "version": 1, "versionNonce": 1003,
      "isDeleted": false, "groupIds": [],
      "boundElements": [
        { "id": "text-decision", "type": "text" },
        { "id": "arrow-1", "type": "arrow" },
        { "id": "arrow-yes", "type": "arrow" },
        { "id": "arrow-no", "type": "arrow" }
      ],
      "link": null, "locked": false
    },
    {
      "type": "text",
      "id": "text-decision",
      "x": 210, "y": 225, "width": 80, "height": 25,
      "text": "Ready?", "fontSize": 20, "fontFamily": 2,
      "textAlign": "center", "verticalAlign": "middle",
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1004, "version": 1, "versionNonce": 1004,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "containerId": "decision", "originalText": "Ready?",
      "autoResize": true, "lineHeight": 1.25
    },
    {
      "type": "rectangle",
      "id": "process-yes",
      "x": 50, "y": 380, "width": 140, "height": 80,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "#a5d8ff",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1005, "version": 1, "versionNonce": 1005,
      "isDeleted": false, "groupIds": [],
      "boundElements": [
        { "id": "text-yes", "type": "text" },
        { "id": "arrow-yes", "type": "arrow" }
      ],
      "link": null, "locked": false,
      "roundness": { "type": 3 }
    },
    {
      "type": "text",
      "id": "text-yes",
      "x": 75, "y": 407, "width": 90, "height": 25,
      "text": "Do Thing", "fontSize": 20, "fontFamily": 2,
      "textAlign": "center", "verticalAlign": "middle",
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1006, "version": 1, "versionNonce": 1006,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "containerId": "process-yes", "originalText": "Do Thing",
      "autoResize": true, "lineHeight": 1.25
    },
    {
      "type": "rectangle",
      "id": "process-no",
      "x": 310, "y": 380, "width": 140, "height": 80,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "#ffc9c9",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1007, "version": 1, "versionNonce": 1007,
      "isDeleted": false, "groupIds": [],
      "boundElements": [
        { "id": "text-no", "type": "text" },
        { "id": "arrow-no", "type": "arrow" }
      ],
      "link": null, "locked": false,
      "roundness": { "type": 3 }
    },
    {
      "type": "text",
      "id": "text-no",
      "x": 355, "y": 407, "width": 50, "height": 25,
      "text": "Wait", "fontSize": 20, "fontFamily": 2,
      "textAlign": "center", "verticalAlign": "middle",
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1008, "version": 1, "versionNonce": 1008,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "containerId": "process-no", "originalText": "Wait",
      "autoResize": true, "lineHeight": 1.25
    },
    {
      "type": "arrow",
      "id": "arrow-1",
      "x": 250, "y": 115, "width": 0, "height": 60,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1009, "version": 1, "versionNonce": 1009,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "points": [[0, 0], [0, 60]],
      "startArrowhead": null, "endArrowhead": "arrow",
      "startBinding": { "elementId": "start", "focus": 0, "gap": 5 },
      "endBinding": { "elementId": "decision", "focus": 0, "gap": 5 }
    },
    {
      "type": "arrow",
      "id": "arrow-yes",
      "x": 200, "y": 300, "width": 80, "height": 75,
      "angle": 0, "strokeColor": "#2f9e44", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1010, "version": 1, "versionNonce": 1010,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "points": [[0, 0], [-80, 75]],
      "startArrowhead": null, "endArrowhead": "arrow",
      "startBinding": { "elementId": "decision", "focus": -0.5, "gap": 5 },
      "endBinding": { "elementId": "process-yes", "focus": 0, "gap": 5 }
    },
    {
      "type": "arrow",
      "id": "arrow-no",
      "x": 300, "y": 300, "width": 80, "height": 75,
      "angle": 0, "strokeColor": "#e03131", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1011, "version": 1, "versionNonce": 1011,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "points": [[0, 0], [80, 75]],
      "startArrowhead": null, "endArrowhead": "arrow",
      "startBinding": { "elementId": "decision", "focus": 0.5, "gap": 5 },
      "endBinding": { "elementId": "process-no", "focus": 0, "gap": 5 }
    },
    {
      "type": "text",
      "id": "label-yes",
      "x": 130, "y": 320, "width": 40, "height": 25,
      "text": "Yes", "fontSize": 16, "fontFamily": 2,
      "textAlign": "center", "verticalAlign": "middle",
      "angle": 0, "strokeColor": "#2f9e44", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1012, "version": 1, "versionNonce": 1012,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "containerId": null, "originalText": "Yes",
      "autoResize": true, "lineHeight": 1.25
    },
    {
      "type": "text",
      "id": "label-no",
      "x": 330, "y": 320, "width": 30, "height": 25,
      "text": "No", "fontSize": 16, "fontFamily": 2,
      "textAlign": "center", "verticalAlign": "middle",
      "angle": 0, "strokeColor": "#e03131", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 0, "opacity": 100,
      "seed": 1013, "version": 1, "versionNonce": 1013,
      "isDeleted": false, "groupIds": [], "boundElements": null,
      "link": null, "locked": false,
      "containerId": null, "originalText": "No",
      "autoResize": true, "lineHeight": 1.25
    }
  ],
  "appState": { "viewBackgroundColor": "#ffffff", "gridSize": null },
  "files": {}
}
```

**What this demonstrates:**
- Ellipse (start node) with bound text
- Diamond (decision) with bound text and multiple bound arrows
- Rectangles with rounded corners and bound text
- Arrows with bindings, colored by semantic meaning (green = yes, red = no)
- Standalone text labels for edge annotations
- Formal style: `roughness: 0`, `fontFamily: 2` (Helvetica)

**Note on edge label colors:** The "Yes"/"No" labels use semantic stroke colors (`#2f9e44`, `#e03131`) because they sit on the white background, not inside filled shapes. Text inside colored containers must always use `#1e1e1e` (light mode) or `#c9d1d9` (dark mode) — never the stroke color of the container.

---

## Architecture Skeleton (3-Tier)

Minimal structure — Client → Server → Database with bidirectional arrows. Expand by adding elements following the same pattern.

**Key structure:**
- 3 rounded rectangles (160×120), spaced 270px apart horizontally
- 2 bidirectional arrows (`startArrowhead: "arrow"`, `endArrowhead: "arrow"`)
- Text labels grouped with their containers via `groupIds`
- Protocol labels as standalone text (monospace font)

**Element count:** 3 shapes + 3 titles + 3 descriptions + 2 arrows + 2 arrow labels = 13 elements

**Layout grid:**
```
x=50          x=320         x=590
┌──────┐      ┌──────┐      ┌──────┐
│Client│─HTTP─│Server│─SQL──│  DB  │   y=100
└──────┘      └──────┘      └──────┘
```

**Pattern:** Each component is a group (rectangle + title text + description text with matching `groupIds`). Arrows are ungrouped with standalone protocol labels above them.

---

## Sequence Skeleton (Auth Flow)

Minimal structure — 3 participants with lifelines and 4 messages. Expand by adding messages following the same vertical spacing.

**Key structure:**
- 3 participant boxes (100×50) at top, 200px apart
- 3 dashed lifelines (vertical lines, `strokeStyle: "dashed"`, `roughness: 0`)
- 4 message arrows alternating direction (requests solid, responses dashed)
- Message labels as standalone text above arrows

**Element count:** 3 boxes + 3 box labels + 3 lifelines + 4 arrows + 4 arrow labels = 17 elements

**Layout grid:**
```
x=50    x=250   x=450
[User]  [Auth]  [DB]       y=50
  │       │       │
  │──1.───►       │        y=150
  │       │──2.──►│        y=200
  │       │◄──3.──│        y=250
  │◄──4.──│       │        y=300
  │       │       │
```

**Pattern:** Messages spaced 50px vertically. Requests go right (solid arrows), responses go left (dashed arrows, `strokeColor: "#2f9e44"`). Number each message in labels.

---

## Tips

1. **Start simple** — create shapes first, then text, then arrows
2. **Plan positions on paper** before writing JSON
3. **Unique seeds** — every element needs a unique `seed` and `versionNonce`
4. **Use formal style** for all templates: `roughness: 0`, `fontFamily: 2`
5. **Text color** — always `#1e1e1e` inside colored boxes
6. **Test incrementally** — paste into excalidraw.com to verify after each addition
