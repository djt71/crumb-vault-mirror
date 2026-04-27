---
type: run-log
project: obsidian-applenotes-import
domain: software
status: active
created: 2026-04-25
updated: 2026-04-27
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

## 2026-04-25 — Round-2 peer review (4-model panel, full mode)

**Reviewers:** Same panel. All 4 succeeded; safety gate produced 1 soft warning (benign "proprietary" token reference).

**Review note:** [`reviews/2026-04-25-specification-r2.md`](../reviews/2026-04-25-specification-r2.md)

**Verdicts:** Google READY FOR PLAN, DeepSeek READY FOR PLAN, OpenAI ONE MORE ROUND, Grok ONE MORE ROUND.

**Headline:** Verdict split is calibration, not direction. All 4 reviewers confirmed every round-1 must-fix correctly applied. The "ONE MORE ROUND" verdicts target depth additions, not architecture concerns. **One real spec bug surfaced**: sequencing contradiction in OAI-016a/b (verify gate claims to include "index persisted+readback" but pipeline placed persist AFTER verify).

**Synthesis output:**
- 15 must-fix actions (B1–B15) — including 1 sequencing bug, 1 platform-gate ribbon-icon bug, 1 dependency-graph diagram bug, 12 genuine depth gaps (G2/G3 thresholds, repair conflict policy, mobile handling, temp cleanup, M6 boundaries, etc.)
- 14 should-fix actions (B16–B29)
- 3 declined findings (knowledge-cutoff false positives on macOS version + eslint plugin name; one "N=5 trials" overkill)

**Operator decision (2026-04-25):** apply B1–B29; declare SPECIFY done; do NOT dispatch round 3.

## 2026-04-25 — SPECIFY phase output (revision 3) + B4 citation pin (G4 resolved)

**Inputs read (context inventory, against budget):**
1. Round-2 review note (consensus + unique findings + action items)
2. `specification.md` rev 2
3. `specification-summary.md` rev 2

**External fetches:**
- `obsidianmd/obsidian-developer-docs` HEAD: `2ed97bd04e82773d81eac967382819431da3b098` (2026-03-16)
- `obsidianmd/obsidian-sample-plugin` HEAD: `dc2fa22c4d279199fb07a205a0c11eb155641f3d` (2025-12-30)
- `Manifest.md` blob: `eeac634ac771a85e5c22ee3b35754c5d5614b076`
- `Submission requirements...md` blob: `ce93a442f4b6edf0c3aef10958c785ed1722ba9c`
- `eslint-plugin-obsidianmd` template pin: `0.1.9`; npm latest: `0.2.4` (verified 2026-04-25)

**Outputs:**
- `design/specification.md` — revision 3 (full rewrite incorporating B1–B29)
- `design/specification-summary.md` — revision 3
- `design/research-brief-plugin-platform.md` — citations pinned (B4 / G4 resolved)
- `design/probes/a4-probe-result.md` — `sw_vers` output inlined (B15)

**Key structural changes in rev 3:**
- Sequencing bug fixed (B1): canonical pipeline now `… write md → persist index → composite verify → delete → receipt` consistent across System Map, AC5, OAI-016a, OAI-016b
- G2 acceptance criteria concrete (B2): byte-identical id across 3 restarts + 1 edit + 1 folder move; cross-account allowed (downgrade dedupe); same-account change → return SPECIFY
- G3 acceptance criteria per-class (B3): required types ≥95% each; best-effort types probe-determined; FDA UX gate
- G4 resolved (B4): citation pin section added to research-brief
- OAI-020 platform gate skips ALL UI registration (B5): commands + ribbon + settings tab modal
- OAI-012 vault listeners (B6): `vault.on('rename')` + `vault.on('delete')` keep index synced
- Sequential batch execution explicit (B7) in OAI-016d
- Temp file pattern + post-note cleanup contract (B8) in OAI-011 + OAI-016d
- Mobile early-return in onload (B9): AC7 + OAI-002 + OAI-020 acceptance
- M6 task boundaries tightened (B10): 016a pure orchestration, 016b pure verify, 016c pure delete-gate; function contracts stated
- Dependency-graph diagram fixed (B11): M7-OAI-019 placement explicit
- OAI-013 dep loosened (B12): no longer depends on OAI-019; TCC dep moved to OAI-015
- minAppVersion strategy (B13): "must resolve to concrete X.Y.Z before TASK lock"
- G1 probe summary inlined in spec Pre-PLAN gate (B14)
- `sw_vers` inlined in probe-result (B15)
- Conversion tier escalation rules concrete (B16): severe = required-attachment-fail OR substantive content-loss
- Debug-mode raw HTML moved out of note body (B17): receipt-only
- Plus B18–B29 (release asset inspection, AC1/A1 unification, parser robustness, UI clarifications, etc.)

**Scope:** still MAJOR. 27 tasks across 8 milestones (unchanged count; structure refined).

## 2026-04-25 — SPECIFY artifact frozen (rev 3); pending pre-PLAN gates

**Status:** SPECIFY artifact complete. Phase remains SPECIFY in `project-state.yaml` until pre-PLAN gates G2 and G3 resolve.

**Pre-PLAN gates outstanding:**
- ⏳ **G2 / A2** — note id stability probe (concrete acceptance criteria in spec)
- ⏳ **G3 / A7** — attachment extraction approach decision (concrete per-class criteria in spec)
- ✅ **G1 / A4** — soft-delete validated 2026-04-25
- ✅ **G4** — citations pinned 2026-04-25

## 2026-04-25 — G2 probe (note id stability) — VALIDATED

**Action:** Wrote osascript probe `design/probes/g2-id-stability.applescript` exercising id stability across 3 Notes app restarts + title edit + body edit + folder move (within same account).

**Outcome:** ✅ **VALIDATED.** id byte-identical across all in-spec scenarios.

**Bonus findings (probe-derived implementation notes, captured in spec rev 4):**
1. **Apple Notes auto-renames notes from body's first heading** — AppleScript code must address notes by id (`whose id is X`), never by name. This invalidated my initial probe's by-name re-find logic; folder-move sub-probe re-run with id-based handle succeeded.
2. **`folder of note` raises error -1728** — must iterate folders to determine membership, can't query directly.
3. **AppleScript `move`** works when handles are obtained fresh via id selectors.

**Probe artifacts:** `design/probes/g2-id-stability.applescript`, `design/probes/g2-probe-result.md`.

## 2026-04-25 — G3 probe attempt — CANNOT VALIDATE EMPIRICALLY

**Action:** Surveyed user's Apple Notes library + Group Container to identify attachment-bearing notes for dual-approach probe.

**Findings:**
- User's Apple Notes library contains 3 notes total (all probe leftovers); **0 attachment-bearing notes**.
- The spec's filesystem-cache hypothesis (`~/Library/Group Containers/group.com.apple.notes/Media/`) **does not exist on macOS 26.x**. Actual storage on this version: `NoteStore.sqlite` (likely encrypted blobs) + empty CloudKit `Assets/` cache.
- iCloud Notes account configured (`tessservo@icloud.com`) but no notes synced to this Mac.

**Three options surfaced to operator:**
- A: defer G3 to PLAN spike with corpus prerequisite
- B: build a test corpus now (iPhone, ~30-60 min)
- C: drop attachments from v1 entirely (defer to v1.1)

**Operator decision (2026-04-25):** **Option C** — "i don't need attachments to come over from Apple Notes, let's keep it simple."

**Sub-decision:** Behavior for source notes that have attachments — Option 1 of 3: import body-only, drop attachment objects with markdown comment placeholder, soft-delete uniformly. README warns about post-retention attachment loss.

## 2026-04-25 — SPECIFY artifact rev 4 — attachments deferred to v1.1

**Inputs:**
1. G2 probe result (validated)
2. G3 probe result (cannot-validate; operator chose drop-attachments)
3. specification.md rev 3

**Outputs:**
- `design/specification.md` rev 4 (full rewrite removing attachment surface)
- `design/specification-summary.md` rev 4
- `design/probes/g2-id-stability.applescript`
- `design/probes/g2-probe-result.md`

**Key changes in rev 4:**
- LD-07 reversed: attachments NOT in v1; body-only import; placeholder comment for dropped attachment objects; soft-delete uniformly
- LD-09 frontmatter: `imported_attachments` removed; `source_had_attachments` (count) added for v1.1 forward-compat
- AC3 rewritten: notes with attachments → body-only with placeholder
- AC5 simplified: composite verify covers md + index (3 checks, was 5 in rev 3)
- AC11 simplified: no attachment write/cleanup paths
- New AC12: README + confirm-dialog must surface attachment-loss warning prominently
- OAI-008a + OAI-008b removed (attachment probe + extractor): task count 27 → 25
- OAI-009 simplified: drop attachment objects with placeholder; tier-tracking unchanged
- OAI-011 simplified: markdown only, no `createBinary`, no attachment temp dirs
- OAI-013 modal: "has N attachments — body only" badge (informational, doesn't block selection)
- OAI-014 confirm dialog: warns when any selected note has attachments
- OAI-016a/b/d simplified: no attachment write/verify/cleanup
- G3 removed from Pre-PLAN gates
- Risk register: attachment-extraction risks dropped; new risk added (user trust erosion from undocumented attachment loss; mitigation: AC12)
- New risk: v1.1 attachment migration timing — if v1.1 ships >30d after v1 import, attachments unrecoverable
- Settings: "attachments folder" removed
- Probe-derived implementation notes section added (id-based handles, folder-of-note quirk)

**All pre-PLAN gates resolved.** SPECIFY artifact frozen at rev 4.

## 2026-04-25 — SPECIFY done; PLAN-ready

**Status:** SPECIFY artifact complete. All pre-PLAN gates resolved. Phase transition SPECIFY → PLAN is operator-controlled.

**Compound reflection (cumulative across 4 SPECIFY revisions):**
- **Pattern: pre-PLAN probes can produce scope-changing decisions, not just validation.** G3's empirical-validation barrier (no test corpus) led to a v1 simplification — an outcome the spec's pre-PLAN gate framework didn't explicitly anticipate but accommodated cleanly via the "if gate fails, return to SPECIFY" policy. The framework worked: instead of forcing a corpus build, the operator chose the simpler scope.
- **Insight: 4 spec revisions across one calendar day produced a materially better artifact than rev 1.** Cumulative review action count: 28 (round 1) + 29 (round 2) + 1 product-scope simplification (rev 4) = ~58 individual changes. Rev 1's underspecified attachment story would have been a real PLAN/IMPLEMENT pain point if discovered late.
- **Probe-derived bonus findings (auto-rename, folder-of-note quirk) added value beyond their stated purpose.** Both will likely save IMPLEMENT-time debugging cycles. Pattern worth reusing: pre-PLAN probes should have explicit "capture incidental findings" expectation, not just hit/miss criteria.
- **Reviewer knowledge-cutoff false positives are predictable noise.** Two reviewers (Google, Grok) flagged macOS 26.3.1 as anachronistic in round 2; the underlying concern (probe metadata self-evidence) was real but the alarm itself was wrong. Future synthesis should pre-empt by inlining `sw_vers`-style self-evidence for any post-cutoff factual claims.

**Next:** Operator transitions phase SPECIFY → PLAN per Phase Transition Gate protocol, OR pauses for session-end commit. Current vault delta is substantial (4 spec revisions, 2 probe artifacts, 2 review notes, run-log + progress-log + project-state) and warrants a single coherent commit before PLAN begins.

**Compound reflection (round-2):**
- Pattern: cross-model verdict split (2 READY / 2 ONE MORE ROUND) with no architecture concerns is a useful "ready" signal — calibration variance dominates substantive variance once major issues are addressed.
- Insight: knowledge-cutoff dates in reviewer training produce predictable false-positive "unverifiable claim" findings on dates and version numbers from the post-cutoff present. Mitigation: inline self-evidence (e.g., `sw_vers` capture, pinned commit SHAs) for any post-cutoff factual claim.
- Insight: turndown silently drops unknown HTML tags by default (caught by Google + OpenAI); custom node-filters are required to surface the warning UX the spec promised. This was a real implementation gap masquerading as a strategy choice.

**Next:** Operator runs G2 + G3 probes (or directs Claude to run them), then phase transitions SPECIFY → PLAN.

### Phase Transition: SPECIFY → PLAN
- Date: 2026-04-27
- SPECIFY phase outputs:
  - `design/specification.md` rev 4 (frozen)
  - `design/specification-summary.md` rev 4
  - `design/research-brief-plugin-platform.md` (citations pinned)
  - `design/probes/a4-soft-delete.applescript` + `design/probes/a4-probe-result.md` (G1)
  - `design/probes/g2-id-stability.applescript` + `design/probes/g2-probe-result.md` (G2)
  - `reviews/2026-04-25-specification.md` (round 1) + `reviews/2026-04-25-specification-r2.md` (round 2)
- Goal progress: all SPECIFY acceptance criteria **met**.
  - Approved spec produced (rev 4 frozen, MAJOR scope, 25 tasks / 8 milestones)
  - All pre-PLAN gates resolved (G1✅ G2✅ G4✅; G3 removed via v1.1 attachment deferral)
  - Peer review discipline applied (2 rounds, 53 actions absorbed + 1 product simplification)
  - Probe-derived implementation notes captured for IMPLEMENT-stage consumption
- Compound: cumulative compound reflection already recorded in the 2026-04-25 "SPECIFY done; PLAN-ready" entry above (4 patterns: pre-PLAN probes can produce scope-changing decisions; multi-revision specs materially improve quality; probes yield bonus implementation findings; reviewer knowledge-cutoff false positives are predictable). No new compoundable insights from the transition itself.
- Context usage before checkpoint: ~30% (well under 50% threshold)
- Action taken: none (no compact/clear needed)
- Key artifacts for PLAN phase to load:
  - `design/specification-summary.md` (loaded)
  - `design/specification.md` rev 4 — Constraints, Requirements, Interfaces sections (action-architect step 1 will pull targeted reads)
  - `design/research-brief-plugin-platform.md` (Obsidian platform constraints for design decisions)
