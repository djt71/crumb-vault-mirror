---
type: log
domain: null
skill_origin: null
status: active
created: 2026-02-15
updated: 2026-02-24
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


