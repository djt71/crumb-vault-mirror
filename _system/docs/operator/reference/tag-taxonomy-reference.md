---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-04-07
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Tag Taxonomy Reference

Complete hierarchy of `#kb/` tags, system tags, and governance rules.

**Architecture source:** [[05-cross-cutting-concepts]] §Tag Taxonomy

---

## Knowledge Base Tags (`#kb/`)

### Level 2 — Canonical (18 tags, locked)

These are the only Level 2 tags. Do not create new ones without operator approval.

| Tag | Domain | Example Content |
|-----|--------|-----------------|
| `kb/biography` | Learning | Biographical profiles, life stories |
| `kb/business` | Career | Business models, strategy, pricing, markets |
| `kb/customer-engagement` | Career | Customer interaction patterns, account management |
| `kb/fiction` | Learning | Novels, short stories, narrative craft |
| `kb/gardening` | Lifestyle | Gardening techniques, plant care, locale-specific horticulture |
| `kb/history` | Learning | Historical events, periods, historiography |
| `kb/inspiration` | Creative | Motivational content, creative fuel |
| `kb/lifestyle` | Lifestyle | Daily living, home and property routines, household craft |
| `kb/networking` | Software | Network protocols, DNS, DHCP, infrastructure |
| `kb/philosophy` | Learning | Philosophical frameworks, ethics, epistemology |
| `kb/poetry` | Learning | Poetry works and analysis |
| `kb/politics` | Learning | Political systems, policy, governance |
| `kb/psychology` | Learning | Cognitive science, behavioral patterns |
| `kb/religion` | Spiritual | Religious traditions, theology, practice |
| `kb/security` | Software | Security architecture, threat modeling, hardening |
| `kb/software-dev` | Software | Programming, architecture, tools, practices |
| `kb/training-delivery` | Career | Teaching, facilitation, curriculum design |
| `kb/writing` | Creative | Writing craft, style, revision techniques |

### Level 3 — Open (subtags)

Level 3 subtags can be created freely through compound engineering:

| Example | Parent | Purpose |
|---------|--------|---------|
| `kb/networking/dns` | `kb/networking` | DNS-specific content |
| `kb/business/pricing` | `kb/business` | Pricing strategy |
| `kb/security/zero-trust` | `kb/security` | Zero trust architecture |
| `kb/philosophy/stoicism` | `kb/philosophy` | Stoic philosophy |

**Three levels is the hard cap:** `#kb/topic/subtopic` maximum. No `kb/a/b/c`.

### Subordination Rule

When a candidate Level 2 tag is clearly a subtopic of an existing Level 2, use Level 3 instead. Cross-domain topics use dual tagging.

**Example:** DNS is a subtopic of networking → `kb/networking/dns` (not `kb/dns`). DNS security content → `kb/networking/dns` + `kb/security`.

---

## System Tags

| Tag | Purpose | Used By |
|-----|---------|---------|
| `system/architecture` | Arc42 architecture documents | `_system/docs/architecture/` |
| `system/operator` | Diátaxis operator documents | `_system/docs/operator/` |
| `system/llm-orientation` | LLM orientation artifacts | `_system/docs/llm-orientation/` |

System tags do not go through vault-check `#kb/` validation — they pass through without restriction.

---

## Enforcement

| Rule | Check | Level |
|------|-------|-------|
| Level 2 tag must be canonical | vault-check §9 | Error |
| `#kb/`-tagged notes require `topics` field | vault-check §19 | Error |
| `topics` values must resolve to existing MOC files | vault-check §18 | Error |

---

## Four Sync Points

The canonical Level 2 tag list is maintained in four locations. All must agree:

1. `_system/docs/file-conventions.md` — primary definition
2. `CLAUDE.md` — governance surface
3. Design spec §5.5 — specification reference
4. `_system/scripts/vault-check.sh` line ~695 — enforcement

When adding or retiring a tag, update all four.

---

## Tag-to-MOC Mapping

`_system/docs/kb-to-topic.yaml` maps each `#kb/` tag to its parent MOC slug. This is the single source of truth for the tag→MOC relationship.

The inbox-processor and feed-pipeline skills consult this file when routing knowledge notes to MOCs.
