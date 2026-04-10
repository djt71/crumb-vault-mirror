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

# Advanced Diagram Patterns

Extended layout patterns for complex Excalidraw diagrams. **Load only for advanced diagram types not covered in the main SKILL.md** (swimlanes, DFDs, detailed sequence components, multi-tier architecture).

For basic flowchart, architecture, sequence, mind map, and ERD patterns, see the Diagram-Type Patterns section in SKILL.md.

## Swimlane Flowcharts

Organize by responsibility using frames or colored regions:

```
┌─────────────────┬─────────────────┬─────────────────┐
│     User        │     System      │    Database     │
├─────────────────┼─────────────────┼─────────────────┤
│  ┌─────────┐    │                 │                 │
│  │ Request │────┼──►┌─────────┐   │                 │
│  └─────────┘    │   │ Process │───┼──►┌─────────┐   │
│                 │   └─────────┘   │   │  Query  │   │
│                 │                 │   └─────────┘   │
└─────────────────┴─────────────────┴─────────────────┘
```

**Implementation:**
- Large rectangles with `backgroundColor: "transparent"` and `strokeStyle: "dashed"` for lanes
- Lane headers at top with bold text (fontSize 24)
- Keep elements within their lanes
- Horizontal arrows cross lane boundaries

## Detailed Sequence Diagram Components

**Activation boxes** (thin rectangles on lifelines showing active processing):
```json
{
  "type": "rectangle",
  "width": 16,
  "height": 80,
  "backgroundColor": "#e9ecef",
  "strokeWidth": 1
}
```

**Return messages** use lighter stroke color to distinguish from requests:
```json
{
  "type": "arrow",
  "strokeStyle": "dashed",
  "strokeColor": "#868e96",
  "endArrowhead": "arrow"
}
```

**Layout rules:**
- 200px between participants
- 50–80px vertical spacing between messages
- Labels above arrows, not on them
- Number messages for complex flows: "1. Login", "2. Verify"

## Multi-Tier Architecture Patterns

### Layered Architecture

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │   Web   │  │ Mobile  │  │   API   │  │
│  └─────────┘  └─────────┘  └─────────┘  │
├─────────────────────────────────────────┤
│            Business Layer               │
│  ┌─────────────────────────────────┐    │
│  │         Service Logic           │    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│              Data Layer                 │
│  ┌─────────┐         ┌─────────┐        │
│  │   DB    │         │  Cache  │        │
│  └─────────┘         └─────────┘        │
└─────────────────────────────────────────┘
```

Layer colors (top to bottom): presentation `#a5d8ff`, business `#b2f2bb`, data `#d0bfff`.

### Microservices

```
                    ┌─────────────┐
                    │   Clients   │
                    └──────┬──────┘
                    ┌──────┴──────┐
                    │ API Gateway │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
    ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
    │  Service A  │ │  Service B  │ │  Service C  │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
    ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
    │    DB A     │ │    DB B     │ │    DB C     │
    └─────────────┘ └─────────────┘ └─────────────┘
```

### Component Shapes by Type
| Component | Shape | Color |
|-----------|-------|-------|
| User/Client | Ellipse | `#a5d8ff` |
| Service/API | Rectangle | `#b2f2bb` |
| Database | Ellipse (cylinder look) | `#d0bfff` |
| Queue/Message | Rectangle (yellow) | `#ffec99` |
| External System | Rectangle with dashed border | `#e9ecef` |
| Load Balancer | Diamond | `#99e9f2` |

## Data Flow Diagrams (DFD)

### Yourdon-Coad Notation
| Symbol | Meaning | Excalidraw Type |
|--------|---------|------------|
| Circle | Process | `ellipse` |
| Rectangle | External Entity | `rectangle` |
| Open Rectangle | Data Store | `rectangle` without one side (use lines) |
| Arrow | Data Flow | `arrow` |

### DFD Levels
- **Context (Level 0):** Single process, external entities only
- **Level 1:** Main processes, data stores appear
- **Level 2+:** Detailed sub-processes

### Layout Tips
- External entities at edges, processes in center
- Data stores between related processes
- Label every arrow with data name

## Entity Relationship Diagrams

### Cardinality Notation
Use text labels or crow's foot:
- `1` — One
- `N` or `*` — Many
- `0..1` — Zero or one
- `1..*` — One or more

### Layout
```
┌─────────────┐         ┌─────────────┐
│   ENTITY    │         │   ENTITY    │
├─────────────┤         ├─────────────┤
│ *key*       │─────────│ *key*       │
│ attribute1  │   1:N   │ attribute1  │
│ attribute2  │         │ attribute2  │
└─────────────┘         └─────────────┘
```

Key fields in bold or with `*` prefix.

## Alternative Color Palettes

The semantic colors in SKILL.md are the default. These alternatives suit specific visual contexts:

**Corporate/Formal** (presentations, client-facing):
- Primary: `#228be6`, Secondary: `#868e96`, Background: `#f8f9fa`

**Technical/Engineering** (internal docs, code diagrams):
- Primary: `#1e1e1e`, Background: `#e9ecef`, Accent: `#228be6`

**Friendly/Startup** (pitch decks, brainstorming):
- Primary: `#7950f2`, Secondary: `#20c997`, Accent: `#ff922b`

These replace the semantic palette entirely — don't mix them. Choose one palette per diagram.

## Mind Map Sizing Reference

| Level | Font Size | Shape Size | Stroke Width |
|-------|-----------|------------|--------------|
| Center | 28–36 | 180×100 | 4 |
| Level 1 | 20–24 | 140×70 | 2 |
| Level 2 | 16–18 | 100×50 | 2 |
| Level 3 | 14–16 | 80×40 | 1 |

Color strategy: bold center, distinct colors per Level 1 branch, lighter shades for Level 2+. Use curved lines (multiple points) for organic feel, thicker near center.
