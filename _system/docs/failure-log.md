---
type: log
domain: null
skill_origin: null
status: active
created: 2026-02-15
updated: 2026-04-21
tags:
  - failure-log
  - calibration
---

# Failure Log

Track all failure types for calibration. Each entry is classified by type from the canonical taxonomy. Review during weekly audits (§3.1.4) to identify recurring failure modes and update validation procedures.

**Failure types:** Convergence Failure | False Pattern | Bad Summary | Irrelevant Context | Routing Failure | Scope Miss | Quality Miss | Wrong Skill

---

## 2026-02-14 - Quality Miss

**What happened:** Claude completed a non-project interaction (updating CLAUDE.md and AGENTS.md) but did not log the session to `session-log.md` as specified in §2.3.4 and §4.6. Only logged when explicitly reminded.

**Why it passed validation:** No validation step exists for session-end logging — it's a behavioral instruction in CLAUDE.md, not a mechanically enforced gate. The vault integrity script (§7.8) validates existing entries but can't detect missing entries.

**Actual failure mode:** Behavioral instruction insufficient for reliable execution of session-end sequence.

**System update:** Strengthened CLAUDE.md session management wording. Added inline session-log template to CLAUDE.md for format consistency. Added 7-step phase gate checklist. This is a known limitation — behavioral instructions can be missed; the vault integrity script catches format drift but not omissions.

## 2026-02-14 - Quality Miss

**What happened:** When Claude did write the session-log entry (after being reminded), the format drifted from the spec: used `**What:**` instead of `**Summary:**`, added `**Files modified:**` (not in spec), renamed `**Compound:**` to `**Compound evaluation:**`, and omitted `**Domain:**` and `**Promote:**` fields.

**Why it passed validation:** No validation existed at that point — the vault integrity script's session-log compound completeness check (§7.8 check 5) was not yet running, and the inline template had not been added to CLAUDE.md.

**Actual failure mode:** Claude inferred a reasonable format from the general intent rather than following the §2.3.4 template exactly. Format drift is a compound risk — inconsistent formats make automated validation harder over time.

**System update:** Added inline session-log format template to CLAUDE.md so Claude has the exact format in its always-loaded context. Vault integrity script will catch entries missing required fields once operational.

## 2026-04-21 - False Pattern

**What happened:** Overnight research brief `research-brief-2026-04-15-builder.md` (stream: builder, produced by tess-overnight-research) cited four `[[wikilinks]]` in its "Vault Connections" section — all fabricated. Paths cited: `Projects/tess-v2/design/automation-patterns`, `Projects/opportunity-scout/design/pipeline-orchestration`, `Projects/customer-intelligence/design/document-ingestion`, `feed-intel-framework/insights/mcp-ecosystem`. None of the four files existed; `customer-intelligence/design/` and `feed-intel-framework/insights/` directories did not exist at all. External sources in the same brief (Routines docs, Graphify repo, Platform API docs) were all verified real, and the 71.5x token-efficiency benchmark matched the repo — so the fabrication was scoped specifically to internal vault references, not external claims.

**Why it passed validation:** The tess-overnight-research pipeline has no step that verifies wikilinks against the vault before emitting the brief. The writer stage synthesizes plausible-sounding project paths from the research topic without grounding them in actual filesystem state. No downstream consumer of `_openclaw/research/output/` validates links either — the pending-review queue assumes an operator reads and spot-checks manually.

**Actual failure mode:** Asymmetric grounding across source types. The writer treated external URLs as needing citation discipline but treated internal vault paths as synthesizable from project names alone. This is a classic hallucination pattern — confident-looking structured output (bracketed wikilinks with pipe-alias display text) that was never grounded. Also a scoped risk: the reader instinctively trusts a well-formed brief uniformly, so fabricated internal links travel alongside verified external ones unless explicitly audited.

**System update:** No code change yet. Capturing here so the next tess-overnight-research iteration (or a peer-review pass on the skill's writer stage) can add a vault-link verification step: before emitting a brief, resolve every `[[...]]` target against the vault and either (a) strip broken links, (b) replace with real anchors, or (c) downgrade to prose with no link. Until then, reviewer-stage audit of research briefs must include explicit link verification (applied in this case during the 2026-04-21 review; the brief itself has been disposed of since neither signal was worth promoting).


