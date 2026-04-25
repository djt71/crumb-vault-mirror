---
type: run-log
project: obsidian-applenotes-import
domain: software
status: active
created: 2026-04-25
updated: 2026-04-25
---

# Obsidian Apple Notes Import — Run Log

## 2026-04-25 — Project creation

**Goal:** Obsidian plugin that lists Apple Notes, allows selective import to vault, and soft-deletes the original from Apple Notes.

**Decisions captured at creation (pre-SPECIFY):**
- Apple Notes access strategy: **AppleScript via osascript** (supported surface, survives macOS updates, slower but acceptable). SQLite/protobuf approach explicitly rejected for v1.
- Deletion model: **soft delete** — AppleScript `delete` moves to Recently Deleted (30-day retention). No hard delete in v1.
- Repo location: `~/code/obsidian-applenotes-import/` (general dev folder, not openclaw-affiliated).
- Project name: `obsidian-applenotes-import`.

**Scaffold:**
- Vault: `Projects/obsidian-applenotes-import/` with `project-state.yaml`, `progress/run-log.md`, `progress/progress-log.md`, `design/`
- External repo: `~/code/obsidian-applenotes-import/` (git init, `.gitignore`, README stub, initial commit)
- `repo_path` and `build_command: npm run build` recorded in project-state.yaml

**Next:** Enter SPECIFY phase via `systems-analyst` skill. Spec must cover access strategy, import format (HTML→markdown, attachments), UI (modal list with selection), soft-delete safety model (verify-before-delete, dry-run), and macOS permission requirements (Automation prompt for Notes).

## 2026-04-25 — SPECIFY phase output

**Inputs read (context inventory, against budget):**
1. `project-state.yaml`
2. `design/research-brief-plugin-platform.md` (verified Obsidian platform context, pulled live from `obsidianmd/obsidian-developer-docs` and `obsidianmd/obsidian-sample-plugin` HEAD)
3. `_system/docs/overlays/overlay-index.md` — checked, no overlay activates
4. `_system/docs/solutions/` directory listing — scanned 26 entries, no AppleScript/Obsidian-plugin prior art
5. `_system/docs/file-conventions.md` (header) — frontmatter requirements

Ambient KB brief returned irrelevant (DNS/MCP/agent research) — dropped, did not load.

**Operator clarifications (2026-04-25):**
All 5 proposed defaults approved (LD-05 through LD-09 in spec).

**Outputs:**
- `design/specification.md` (full spec — 23 tasks across 8 milestones, scope: MAJOR)
- `design/specification-summary.md`

**Critical levers identified (5):** verify-before-delete contract, import index integrity, body-conversion fidelity, TCC failure UX, submission compliance.

**Critical risks called out (2):** AppleScript hard-delete (mitigated by OAI-007 probe), verify-before-delete weakness (OAI-017 with adversarial tests).

**Manifest constraint flagged:** plugin id cannot contain "obsidian" → proposed `applenotes-import`.

**Scope: MAJOR.** Peer review recommended before PLAN per systems-analyst §6.

**Next:** Operator decides — peer review now, or skip to PLAN.

## 2026-04-25 — Round-1 peer review (4-model panel)

**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning. All 4 succeeded; safety gate clean.

**Review note:** [`reviews/2026-04-25-specification.md`](../reviews/2026-04-25-specification.md)

**Headline:** Strong convergence on data-safety design and pre-PLAN gating gaps. Structural shape of spec drew uniform praise — must-fixes are depth/specificity, not architecture rewrite.

**Synthesis output:**
- 10 consensus must-fix actions (A1–A10)
- 18 should-fix actions (A11–A28)
- 4 declined findings (with reason categories: incorrect / overkill / constraint / out-of-scope)
- 7 strengths reinforced across reviewers

**Operator decision (2026-04-25):** Apply all 10 must-fix + all 18 should-fix; run round-2 diff review.

## 2026-04-25 — A1 / G1 probe (AppleScript soft-delete)

**Action:** Wrote and ran osascript probe to validate the highest-stakes assumption (A4): does AppleScript `delete` send Notes to Recently Deleted (soft) or hard-delete?

**Outcome:** ✅ **VALIDATED.** Note id remains queryable after delete; note found in "Recently Deleted" folder. macOS 26.3.1 baseline. Probe artifacts:
- [`design/probes/a4-soft-delete.applescript`](../design/probes/a4-soft-delete.applescript)
- [`design/probes/a4-probe-result.md`](../design/probes/a4-probe-result.md)

## 2026-04-25 — SPECIFY phase output (revision 2)

**Inputs read (context inventory, against budget):**
1. Round-1 review note (consensus findings + action items)
2. Original `specification.md` rev 1
3. Original `specification-summary.md` rev 1

**Outputs:**
- `design/specification.md` — revision 2 (full rewrite incorporating 10 must-fix + 18 should-fix actions)
- `design/specification-summary.md` — revision 2
- `design/probes/a4-soft-delete.applescript` (G1 evidence)
- `design/probes/a4-probe-result.md` (G1 evidence)

**Key structural changes:**
- New "Pre-PLAN Validation Gate" section (G1✅, G2⏳, G3⏳, G4⏳)
- Verify-before-delete redefined as **composite contract** (md + attachments + index)
- M6 split into 5 finer safety-critical tasks (OAI-016a..e)
- OAI-008 split into 008a (probe+decide) → 008b (implement)
- New AC11 (batch transaction model)
- Conversion warning tiers introduced (severe→delete-block, moderate→logs, debug-only→inline)
- Index corruption strategy: safe-degraded mode + frontmatter rebuild (not silent reset)
- TCC probe moved to first-command (not load); structured denial detection
- Platform gate skips command registration entirely off-platform
- Attachment support matrix added
- Decision-doc location moved to repo-local `design/decisions/`
- Risk register updated: A4 cleared (validated); critical risks now composite-verify and index-corruption

**Scope:** still MAJOR. 27 tasks across 8 milestones (was 23).

**Next:** Round-2 peer review (full mode against revision 2; prior_review links round-1 for round counter).
