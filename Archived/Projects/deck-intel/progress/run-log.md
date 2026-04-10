---
type: run-log
project: deck-intel
status: active
created: 2026-03-03
updated: 2026-03-14
---

# deck-intel — Run Log

## 2026-03-03 — Session 1: Project creation + SPECIFY

- Created project scaffold
- Input: `_inbox/deck-intel-SKILL.md` — detailed draft skill definition for extracting structured intel from PPTX/PDF files
- Invoking systems-analyst to produce specification

**Context inventory (5 docs):**
1. `_inbox/deck-intel-SKILL.md` — draft skill definition (272 lines)
2. Spec §2.2.4 — knowledge-note schema
3. Spec §2.2.6 — source-index schema
4. `.claude/skills/inbox-processor/SKILL.md` — overlap/boundary analysis
5. `Projects/customer-intelligence/specification-summary.md` — downstream consumer

**User decisions (4 questions):**
- Campaign tracking: frontmatter field (`campaign:`), not tag namespace
- Binary management: delete source after synthesis, no companion notes
- CI linkage: manual via shared `#kb/` tags
- Sensitivity: no special handling

**Specification written:** specification.md + specification-summary.md
- 6 key design decisions (D1-D6)
- 5 tasks decomposed (DI-001 through DI-005)
- 2 open questions deferred to PLAN phase
- Overlay check: no new overlays needed, existing Business Advisor / Network Skills cover via `#kb/` routing

**Peer review dispatched:** 4/4 reviewers succeeded (GPT-5.2, Gemini 3 Pro, DeepSeek V3.2, Grok 4.1 Fast)
- 48 total findings across panel
- Strongest consensus: binary deletion needs safety gate (all 4 reviewers)
- 2 must-fix applied: deletion safety gate (D2), extraction error handling (new D7)
- 6 should-fix applied: MOC one-liner spec (D8), inbox-processor boundary clarification, campaign as list (D1), shelf life format (D10), task type reclassification, filename convention (D9)
- 10 findings declined (unverifiable internal refs — all confirmed, plus misreadings)
- 6 findings deferred to PLAN/IMPLEMENT
- Spec now at 10 design decisions (D1-D10), summary updated
- Review note: `Projects/deck-intel/reviews/2026-03-03-specification.md`

**Phase status:** SPECIFY complete, ready for PLAN phase transition on next session

**Compound observations:**
- Inbox-processor vs. deck-intel boundary is clean: catalog/route vs. synthesize/discard — worth documenting as a pattern if more specialized intake skills emerge
- "Delete source after synthesis" is a novel pattern in the vault — all other paths preserve binaries. Decision is sound (originals recoverable from source) but worth noting as precedent
- Deletion safety gate pattern (extraction check + write check + user confirm) is reusable for any destructive-after-synthesis workflow
- All 4 peer reviewers flagged "unverifiable internal references" — expected for a system with private vault artifacts. These aren't issues but they consistently consume ~25% of reviewer output. Consider a prompt addendum noting "internal system references are pre-verified" to reduce noise in future reviews

## 2026-03-14 — Session 2: SPECIFY → PLAN → TASK + DI-001 through DI-006

**Cross-project work in this session (non-deck-intel):**
- overnight-research.sh: reactive output routed to `Sources/research/`, multi-item processing (no LIMIT 1)
- Morning briefing prompt: fixed Telegram title, exception-based Discord, Tess personality sign-off
- Dispatch triage protocol created (`_system/docs/protocols/dispatch-triage-protocol.md`)
- Compound insight ci-2026-03-14-001 (1M context) processed; ci-002 (Context Gateway) skipped via triage
- A2A spec A6 reassessed — context ceilings become soft targets under 1M windows
- Side hustle research: all 7 vectors dispatched and completed via researcher skill

**Deck-intel specific:**

**Spec updates before approval:**
- D6 rewritten: diagram/image preservation via diagram-capture composable mode. Images saved to `_attachments/`, embedded inline with text descriptions. No Mermaid recreation. Image-heavy fallback (< 200 chars) triggers visual-only mode.
- D2 updated: deletion safety gate now 4-check (extraction + write + images + user confirm)
- DI-004 acceptance criteria updated for image preservation

**SPECIFY → PLAN transition:**
- Q1 resolved: knowledge note body uses deck-intel structure (Key Intelligence → Actionable Items → Shelf Life → Source Notes), not NLM structure
- Q2 resolved: subdirectory organization deferred until navigation pain materializes
- Action plan written: 3 milestones (M1 Skill Build, M2 Single File Validation, M3 Batch + Polish)
- Tasks written: 8 tasks (DI-001 through DI-008)
- Spec summary updated: `status: draft` → `active`, task IDs aligned

**Peer review of action plan:** 4/4 reviewers, 50 findings
- 3 must-fix applied: disposable copies for testing, diagram-capture composable verification, spec summary metadata
- 4 should-fix applied: campaign/filename in ACs, batch ceiling 3-5, deletion negative test, D1-D10 enumerated checklist
- Synthesis in `Projects/deck-intel/reviews/2026-03-14-action-plan.md`

**PLAN → TASK transition:**

**DI-001 (Install dependencies):** DONE
- PyMuPDF 1.27.2 installed (`import fitz` works)
- LibreOffice 26.2.1 already installed (headless mode verified)

**DI-002 (Verify markitdown + diagram-capture):** DONE
- markitdown: 76,886 chars from PPTX with speaker notes, text from PDF
- Embedded image extraction: 180 images from PPTX via zipfile
- Rendered slides: 44 pages via LibreOffice → PyMuPDF PNG rendering at 150 DPI

**DI-003 (Write SKILL.md):** DONE
- Updated existing SKILL.md (not from scratch — prior version existed from session 1)
- All spec decisions D1-D10 incorporated with enumerated mapping
- diagram-capture composable integration in Step 4
- 4-check deletion safety gate in Step 9
- Campaign as YAML list, no source-index notes, MOC idempotency

**DI-004 (Overlay index):** DONE — verified during PLAN phase, no changes needed

**DI-005 (Validate with real PPTX):** DONE
- Test file: Infoblox Universal DDI Customer Presentation (45 slides, disposable copy)
- markitdown: 76,886 chars, speaker notes captured throughout
- Images: 3 substantive diagrams preserved to `_attachments/` (product suite stack, UDDI before/after architecture, four pillars framework)
- Knowledge note: `Sources/other/infoblox-universal-ddi-customer-pres-digest.md`
- MOC one-liner added to `moc-networking` (Vendor Architecture section, idempotent)
- Deletion safety gate: 4/4 checks passed, test copy deleted
- Noise filtering: 45 slides → ~2 pages structured intel

**DI-006 (Validate with real PDF):** DONE
- Test file: Infoblox Battlecard - Universal DDI Management (2 pages, disposable copy)
- markitdown: 9,467 chars
- Images: 6 decorative headers (all skipped — no substantive images path exercised)
- Knowledge note: `Sources/other/infoblox-uddi-mgmt-battlecard-digest.md`
- MOC: not added (already covered by DI-005's more comprehensive entry)
- Deletion safety gate: 3/3 applicable checks passed, test copy deleted

**Remaining:** DI-007 (batch 3-5 files), DI-008 (polish). Negative deletion test not yet exercised.

**Compound observations:**
- Diagram preservation as images (not Mermaid) was the right call — the rendered PPTX slides captured architecture diagrams perfectly while Mermaid would have lost spatial semantics
- The battlecard (PDF) exercised the "no substantive images" path cleanly — the skill correctly identified all 6 images as decorative headers and skipped them
- Speaker notes in Infoblox decks contain most of the technical substance — the extraction categories (product/competitive/customer-facing/actionable) map well to the actual content structure
- Cross-referencing between the two notes (customer pres → battlecard) happened naturally via wikilinks in Source Notes — the pattern works without automated linking

**Model routing:** All work on Opus (session default). No Sonnet delegation — DI-003 SKILL.md write and synthesis steps required judgment-tier work. Research dispatches (side hustle vectors) ran on Opus subagents.
