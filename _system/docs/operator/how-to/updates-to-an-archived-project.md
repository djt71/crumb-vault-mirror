---
type: reference
status: active
domain: software
created: 2026-02-24
updated: 2026-03-14
tags:
  - system/operator
---

**The pattern:**

1. Operator identifies enhancements to a completed project's deliverables
2. Work is scoped as maintenance (same artifacts, same architecture, no new infrastructure)
3. Project is reopened from archive with a run-log entry documenting maintenance scope
4. Enhancement spec added as a design artifact (permitted under maintenance carve-out)
5. Work executes, project re-archives when done

**What makes this maintenance vs. a new project:**

- You're revising existing deliverables in their current locations, not building new systems
- The architectural decisions from the original project still hold (sentinel contract, routing, Sources/)
- No new dependencies or interfaces introduced
- The enhancement spec explicitly references and extends the original spec's artifacts

**The lesson from this case:**

The original archival was premature — validation was incomplete (2/6 fixtures, 1/5 e2e runs) and known gaps were deferred. A pre-archive checklist could have caught this. But the reopening mechanism worked cleanly because the durable deliverables were in stable locations (_system/docs/templates/notebooklm/, inbox-processor skill) and the project's design docs were available for reference.

