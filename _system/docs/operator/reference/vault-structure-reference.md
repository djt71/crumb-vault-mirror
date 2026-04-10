---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Vault Structure Reference

Directory tree, path conventions, and vault-check rules for the Crumb vault.

**Architecture source:** [[02-building-blocks]] §Vault Store, [[05-cross-cutting-concepts]] §vault-check

---

## Directory Tree

```
crumb-vault/                           # Vault root (Obsidian vault + git repo)
├── CLAUDE.md                          # Governance surface (routing, protocols, boundaries)
├── Projects/                          # Active project scaffolds
│   └── <project-name>/
│       ├── project-state.yaml         # Machine-readable state (phase, domain, repo_path)
│       ├── design/                    # Specs, designs, action plans, tasks
│       │   ├── specification.md
│       │   ├── specification-summary.md
│       │   ├── action-plan.md
│       │   └── tasks.md
│       ├── progress/                  # Run logs, progress logs
│       │   ├── run-log.md
│       │   └── progress-log.md
│       ├── reviews/                   # Peer/code review outputs
│       │   └── raw/                   # Raw reviewer JSON responses
│       ├── research/                  # Project-specific research
│       └── attachments/               # Project-scoped binaries
├── Archived/
│   ├── Projects/                      # Archived project scaffolds (same structure)
│   └── KB/                            # Archived knowledge notes (flat, no subdirectories)
├── Domains/                           # Domain overviews and MOCs
│   ├── Career/
│   ├── Creative/
│   ├── Financial/
│   ├── Health/
│   ├── Learning/
│   ├── Relationships/
│   ├── Software/
│   └── Spiritual/
├── Sources/                           # Knowledge notes from external sources
│   ├── books/
│   ├── articles/
│   ├── podcasts/
│   ├── videos/
│   ├── courses/
│   ├── papers/
│   ├── other/
│   ├── signals/                       # Feed-pipeline lightweight captures
│   ├── research/                      # Research indexes and source directories
│   └── insights/                      # Curated synthesis
├── _system/                           # System infrastructure
│   ├── docs/
│   │   ├── crumb-design-spec-v2-4.md  # Master design spec (261KB)
│   │   ├── file-conventions.md        # File naming, frontmatter, type taxonomy
│   │   ├── architecture/              # Arc42-derived system docs (00–05)
│   │   ├── operator/                  # Diátaxis operator docs
│   │   │   ├── tutorials/
│   │   │   ├── how-to/
│   │   │   ├── reference/
│   │   │   └── explanation/
│   │   ├── llm-orientation/           # LLM orientation tracking
│   │   ├── overlays/                  # Expert lens files (8 overlays + index)
│   │   ├── protocols/                 # Cross-cutting workflow patterns (6 files)
│   │   ├── solutions/                 # Compound engineering patterns
│   │   ├── Ops/                       # Legacy operator docs (being migrated)
│   │   └── templates/                 # Artifact templates
│   ├── logs/                          # Operational logs (metrics, health, sync)
│   ├── scripts/                       # Automation scripts (27 files)
│   ├── reviews/                       # Non-project review outputs
│   ├── daily/                         # Daily attention plans
│   └── schemas/                       # Validation schemas
├── _inbox/                            # Manual file drop zone
├── _attachments/                      # Unaffiliated binary storage + companions
├── _openclaw/                         # Tess-Crumb communication layer
│   ├── inbox/                         # Tess → Crumb (bridge requests)
│   ├── outbox/                        # Crumb → Tess (bridge responses)
│   ├── state/                         # Apple integration snapshots
│   ├── feeds/                         # RSS/feed content
│   ├── data/                          # FIF SQLite, dashboard state
│   ├── config/                        # OpenClaw gateway config
│   ├── scripts/                       # Tess-owned operational scripts
│   ├── staging/                       # Deployment staging (plists, configs)
│   │   ├── m1/                        # Milestone 1 services
│   │   └── m2/                        # Milestone 2 services
│   ├── logs/                          # Tess operational logs
│   ├── transcripts/                   # Bridge dispatch transcripts
│   └── tess_scratch/                  # Ephemeral file exchange (gitignored)
├── .claude/                           # Claude Code configuration
│   ├── skills/                        # 22 skill packages (SKILL.md each)
│   ├── agents/                        # 3 subagent definitions
│   └── worktrees/                     # Session-scoped isolated worktrees
├── .git/                              # Git version control
└── .obsidian/                         # Obsidian editor config
```

---

## Ownership Map

| Directory | Primary Writer | Notes |
|-----------|---------------|-------|
| `Projects/` | Crumb | Full governed workflow |
| `Domains/` | Crumb | MOCs and domain overviews |
| `Sources/` | Crumb | Knowledge notes, signal notes |
| `_system/docs/` | Crumb | Design spec, architecture, operator docs |
| `_system/logs/` | Scripts + Crumb | Metrics from LaunchAgents; session-log from Crumb |
| `_system/scripts/` | Crumb | Automation scripts |
| `.claude/` | Crumb | Skills, agents, worktrees |
| `_inbox/` | Danny (drops) | Crumb processes and routes |
| `_attachments/` | Crumb | Binary storage via inbox-processor |
| `_openclaw/inbox/` | Tess (writes) | Crumb reads for dispatch |
| `_openclaw/outbox/` | Crumb (writes) | Tess reads for delivery |
| `_openclaw/state/` | LaunchAgents | Apple data snapshots |
| `_openclaw/feeds/` | Tess | RSS/feed content |

---

## Path Conventions

### File Naming
- **kebab-case always:** `frontend-design.md`, `api-spec.md`
- **Summaries:** `*-summary.md` colocated with parent
- **Run logs:** `run-log.md` (active), `run-log-{label}.md` (archived)
- **Session logs:** `session-log.md` (current), `session-log-YYYY-MM.md` (archived)
- **MOCs:** `moc-*.md` (globally unique basenames)

### Binary Naming Patterns
| Type | Pattern |
|------|---------|
| Screenshots | `screenshot-[project]-[task]-[slug]-YYYYMMDD-HHMM.[ext]` |
| Diagrams | `diagram-[project]-[slug]-v[NN].[ext]` |
| Inbound | `inbound-[source]-[slug]-YYYYMMDD.[ext]` |
| Exports | `export-[project]-[slug]-YYYYMMDD.[ext]` |
| Personal | `[slug]-YYYYMMDD.[ext]` |

### Wikilinks
- **Bare:** `[[filename]]` — preferred for unique basenames
- **Path-prefixed:** `[[Projects/foo/design/specification]]` — only for ambiguous basenames

---

## Frontmatter Requirements

### Project Documents (under `Projects/` or `Archived/Projects/`)

```yaml
project: project-name          # required
domain: software               # required (one of 8 domains)
type: specification            # required (see type taxonomy)
skill_origin: systems-analyst  # optional
created: 2026-03-14            # required
updated: 2026-03-14            # required
tags:                          # optional
  - system/architecture
topics:                        # required if #kb/ tags present
  - moc-crumb-architecture
```

**No `status` field** — lifecycle is directory-based (`Projects/` = active).

### Non-Project Documents (everything else)

```yaml
project: null                  # required (null for global docs)
domain: software               # required
type: reference                # required
status: active                 # required (active | archived | draft)
created: 2026-03-14            # required
updated: 2026-03-14            # required
tags:                          # optional
  - system/operator
topics:                        # required if #kb/ tags present
  - moc-crumb-architecture
```

### Summary Documents (add to above)

```yaml
source_updated: 2026-03-14    # parent's updated timestamp (staleness detection)
```

---

## Tag Taxonomy

### System Tags
- `system/architecture` — Arc42 architecture docs
- `system/operator` — Diátaxis operator docs
- `system/llm-orientation` — LLM orientation artifacts

### Knowledge Base Tags (`#kb/`)
**18 canonical Level 2 tags** (locked — do not create new ones without approval):

`religion` · `philosophy` · `gardening` · `history` · `inspiration` · `poetry` · `writing` · `business` · `networking` · `security` · `software-dev` · `customer-engagement` · `training-delivery` · `fiction` · `biography` · `politics` · `psychology` · `lifestyle`

**Level 3 subtags** are open (e.g., `kb/networking/dns`, `kb/business/pricing`). Three levels is the hard cap.

**Subordination rule:** If a candidate L2 is clearly a subtopic of an existing L2, use L3. Cross-domain topics use dual tagging.

**Four sync points:** `file-conventions.md`, `CLAUDE.md`, design spec §5.5, `vault-check.sh` line 695.

---

## Type Taxonomy (Key Types)

| Type | Purpose | Location |
|------|---------|----------|
| `specification` | Problem definitions, requirements | `Projects/*/design/` |
| `design` | Technical designs | `Projects/*/design/` |
| `tasks` | Action plans, task tables | `Projects/*/design/` |
| `run-log` | Session work logs | `Projects/*/progress/` |
| `summary` | Compressed parent docs | Colocated with parent |
| `reference` | System config, conventions | `_system/docs/` |
| `knowledge-note` | Source digests/extracts | `Sources/*/` |
| `source-index` | Per-source landing pages | `Sources/*/` |
| `signal-note` | Feed-pipeline captures | `Sources/signals/` |
| `moc-orientation` | MOC synthesis + navigation | `Domains/*/` |
| `attachment-companion` | Binary file companions | Colocated with binary |
| `overlay` | Expert lens files | `_system/docs/overlays/` |
| `runbook` | Operational procedures | `_system/docs/operator/how-to/` |

Full 31-type taxonomy in `_system/docs/file-conventions.md` §Type Taxonomy.

---

## vault-check Rules Summary

30 deterministic validation checks in `_system/scripts/vault-check.sh`. Pre-commit hook blocks on errors.

| # | Check | Category | Level |
|---|-------|----------|-------|
| §1 | Required frontmatter fields | Schema | Error |
| §2 | Summary staleness (source_updated vs parent updated) | Staleness | Warning |
| §3 | Frontmatter field types and values | Schema | Error |
| §4 | Run-log has required blocks (context, work done, compound) | Structural | Warning |
| §5 | Compound evaluation present at phase transitions | Structural | Warning |
| §6 | Project scaffold completeness (project-state.yaml, design/, progress/) | Structural | Error |
| §7 | project-state.yaml required fields | Structural | Error |
| §8 | Task completion evidence (acceptance criteria checked) | Task | Warning |
| §9 | `#kb/` tag validation (L2 canonical check) | KB | Error |
| §10 | active_task consistency | Task | Warning |
| §11 | project-state last_committed freshness | Staleness | Warning |
| §12 | Binary without companion note | Binary | Warning |
| §13 | Companion without binary | Binary | Warning |
| §14 | Binary in wrong location | Binary | Warning |
| §15 | Binary size threshold (>10MB) | Binary | Warning |
| §16 | Archived project in wrong directory | Lifecycle | Error |
| §17 | MOC required frontmatter (scope, last_reviewed, etc.) | KB | Warning |
| §18 | topics field resolves to existing MOC files | KB | Error |
| §19 | `#kb/`-tagged notes require topics field | KB | Error |
| §20 | Knowledge-note required source fields | Schema | Error |
| §21 | MOC synthesis density (debt scoring) | KB | Warning |
| §22 | DONE project guard (no new design artifacts) | Task | Error |
| §23 | Code review gate (completed code tasks need review entry) | Task | Warning |
| §24 | Run-log size threshold (~1000 lines) | Staleness | Warning |
| §25 | Source-index required fields | Schema | Error |
| §26 | Signal-note required fields | Schema | Error |
| §27 | Companion note schema (attachment block) | Schema | Warning |
| §28 | Primitive registry consistency | Structural | Error |
| §29 | Orphan detection (notes not linked from any MOC or project) | KB | Warning |
| §30 | Duplicate source_id detection | KB | Error |

**Modes:**
- `--pre-commit` — scoped to staged files only (~0.3s)
- `--full` or no flag — complete vault scan (~90s)

**Exit codes:** 0 = clean, 1 = warnings only, 2 = errors found (blocks commit)
