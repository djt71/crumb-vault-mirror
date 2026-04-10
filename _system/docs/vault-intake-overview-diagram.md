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

# Vault Intake Processing Overview

How items flow from source through processing to vault. Edge labels show drop locations.

See [[vault-intake-map]] for full path-by-path detail.

```mermaid
flowchart LR
    subgraph src [Sources]
        you([You])
        tess([Tess])
        fip([Feed-Intel Pipeline])
        br([Bridge Protocol])
    end

    subgraph proc [Processing]
        ip{{inbox-processor}}
        cp{{capture processing}}
        cs{{compound scan}}
        kbr{{KB review}}
        vc{{vault-check}}
        bw{{bridge-watcher}}
    end

    vault[(Vault)]

    you -->|"_inbox/"| ip --> vault
    tess -->|"capture-*.md"| cp --> vault
    fip -->|"feed-intel-*.md"| kbr --> vault
    fip -->|"research/*.md"| cs --> vault
    fip -->|"kb-review/"| kbr
    fip -.->|"Telegram digest"| you
    you -->|"direct drop"| vc --> vault
    br -->|"*.json dispatch"| bw --> vault
```

Dotted line: Telegram digest doesn't require a CC session — you interact via feedback commands directly. Downstream effects (research, save) re-enter the system through the feed-intel paths above.
