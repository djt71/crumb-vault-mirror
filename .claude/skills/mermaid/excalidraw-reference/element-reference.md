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

# Excalidraw Element Reference

Deep-dive property reference for Excalidraw element types. **Load only when generating complex diagrams that need the complete property specification.** For most diagrams, the main SKILL.md has sufficient guidance.

## Common Properties (All Elements)

Every element includes these properties. Note: `boundElements` differs by type — see per-type snippets below.

**Non-text elements** (shapes, arrows, frames):
```json
{
  "id": "unique-id",
  "type": "rectangle",
  "x": 0, "y": 0,
  "width": 100, "height": 100,
  "angle": 0,
  "strokeColor": "#1e1e1e",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 1,
  "opacity": 100,
  "seed": 12345,
  "version": 1,
  "versionNonce": 12345,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": [],
  "link": null,
  "locked": false
}
```

**Text elements** — use `boundElements: null`:
```json
{
  "id": "label-text",
  "type": "text",
  "x": 25, "y": 30,
  "width": 50, "height": 25,
  "angle": 0,
  "strokeColor": "#1e1e1e",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 1,
  "opacity": 100,
  "seed": 67890,
  "version": 1,
  "versionNonce": 67890,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false
}
```

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique identifier. Use descriptive names like `"header-box"` |
| `type` | string | Element type (see types below) |
| `x`, `y` | number | Top-left coordinate |
| `width`, `height` | number | Dimensions in pixels |
| `angle` | number | Rotation in radians (0 = no rotation) |
| `strokeColor` | string | Border/line color (hex) |
| `backgroundColor` | string | Fill color (hex or `"transparent"`) |
| `fillStyle` | string | `"solid"`, `"hachure"`, `"cross-hatch"` |
| `strokeWidth` | number | `1` (thin), `2` (medium), `4` (bold) |
| `strokeStyle` | string | `"solid"`, `"dashed"`, `"dotted"` |
| `roughness` | number | `0` (architect), `1` (artist), `2` (cartoonist) |
| `opacity` | number | 0–100 (100 = fully opaque) |
| `seed` | number | Random seed for hand-drawn rendering (must be unique per element) |
| `version` | number | Element version (start at 1) |
| `versionNonce` | number | Random nonce for version (must be unique per element) |
| `isDeleted` | boolean | Soft delete flag (always `false`) |
| `groupIds` | array | Group IDs this element belongs to (innermost first for nested groups) |
| `boundElements` | array/null | Elements bound to this (arrows, text). Use `[]` for shapes, arrows, and frames; `null` for text elements |
| `link` | string/null | URL link attached to element |
| `locked` | boolean | Prevent editing |

## Type-Specific Properties

### Rectangle
| Property | Type | Description |
|----------|------|-------------|
| `roundness` | object/null | `{ "type": 3 }` for rounded corners, `null` for sharp |

### Ellipse
No additional properties. Set `width` equal to `height` for a perfect circle.

### Diamond
No additional properties. Useful for decision nodes in flowcharts.

### Text
| Property | Type | Values |
|----------|------|--------|
| `text` | string | Displayed text (supports `\n` for newlines) |
| `fontSize` | number | Common: `16`, `20`, `28`, `36` |
| `fontFamily` | number | `1` (Virgil/hand), `2` (Helvetica), `3` (Cascadia/code) |
| `textAlign` | string | `"left"`, `"center"`, `"right"` |
| `verticalAlign` | string | `"top"`, `"middle"` |
| `containerId` | string/null | ID of container element (for bound text) |
| `originalText` | string | Must match `text` |
| `autoResize` | boolean | Auto-resize container to fit |
| `lineHeight` | number | Line spacing multiplier (default: 1.25) |

### Arrow / Line

| Property | Type | Description |
|----------|------|-------------|
| `points` | array | Array of `[x, y]` points relative to element origin. First point always `[0, 0]`. |
| `startArrowhead` | string/null | `null`, `"arrow"`, `"bar"`, `"dot"`, `"triangle"` |
| `endArrowhead` | string/null | Same values. Lines default both to `null`. |
| `startBinding` | object/null | `{ "elementId": "id", "focus": 0, "gap": 5 }` |
| `endBinding` | object/null | Same structure. `focus` ranges -1 to 1 (edge position). |

**Arrow `width`/`height` must equal the bounding box of `points`.**

Point patterns:
```
Horizontal: [[0, 0], [200, 0]]       → width: 200, height: 0
Vertical:   [[0, 0], [0, 150]]       → width: 0, height: 150
L-shaped:   [[0, 0], [100, 0], [100, 100]]  → width: 100, height: 100
Curved:     [[0, 0], [50, -30], [100, 0]]   → width: 100, height: 30
```

### Freedraw
| Property | Type | Description |
|----------|------|-------------|
| `points` | array | Dense array of `[x, y]` points |
| `pressures` | array | Pressure values 0–1 for each point |
| `simulatePressure` | boolean | Simulate pen pressure |

### Frame
| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Frame label displayed at top |

Child elements reference the frame via `frameId` property.

### Image
| Property | Type | Description |
|----------|------|-------------|
| `fileId` | string | Key into top-level `files` object |
| `status` | string | `"saved"` |
| `scale` | array | `[1, 1]` for original size |

Image data goes in the top-level `files` object:
```json
{
  "files": {
    "file-abc123": {
      "id": "file-abc123",
      "mimeType": "image/png",
      "dataURL": "data:image/png;base64,..."
    }
  }
}
```

## Groups

Give elements matching `groupIds` to group them:
```json
{ "groupIds": ["group-1"] }
```

Nested groups use multiple IDs (innermost first):
```json
{ "groupIds": ["inner-group", "outer-group"] }
```
