---
type: reference
status: active
created: 2026-02-27
updated: 2026-02-27
domain: software
tags:
  - crumb-architecture
  - automation
topics:
  - moc-crumb-architecture
  - moc-crumb-operations
---

# Startup Detection Flow

What the session startup script auto-detects vs what falls through.

See [[vault-intake-map]] for full path-by-path detail.

```mermaid
flowchart TD
    start([Session Start]) --> ss[startup script runs]
    ss -->|"glob capture-*.md"| cap{Found?}
    cap -->|Yes| rpt1[Report captures]
    cap -->|No| skip1[Continue]
    ss -->|"scan compound_insight:"| ci{Found?}
    ci -->|Yes| rpt2[Report insights]
    ci -->|No| skip2[Continue]
    ss -.->|"NOT SCANNED"| gap1["feed-intel-*.md"]
    ss -.->|"NOT SCANNED"| gap2["kb-review/"]
    ss -.->|"NOT SCANNED"| gap3["_inbox/ (by design)"]
```

Dotted arrows indicate detection gaps — items in these locations sit unnoticed until manually checked.
