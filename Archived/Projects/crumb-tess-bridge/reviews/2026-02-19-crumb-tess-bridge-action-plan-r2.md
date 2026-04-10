---
type: review
review_mode: diff
review_round: 2
prior_review: Projects/crumb-tess-bridge/reviews/2026-02-19-crumb-tess-bridge-action-plan.md
artifact: Projects/crumb-tess-bridge/design/action-plan.md + Projects/crumb-tess-bridge/design/tasks.md
artifact_type: action-plan
artifact_hash: 603c81bf
prompt_hash: fe94a1fe
base_ref: HEAD~1
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-19
updated: 2026-02-19
reviewers:
  - openai/gpt-5.2
  - google/gemini-2.5-pro
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192 (openai, google) / 65536 (perplexity)
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 35081
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-action-plan-r2-openai.json
  google:
    http_status: 200
    latency_ms: 32109
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-action-plan-r2-google.json
  perplexity:
    http_status: 200
    latency_ms: 38646
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-action-plan-r2-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review R2: Crumb–Tess Bridge Action Plan & Task List

**Artifact:** `Projects/crumb-tess-bridge/design/action-plan.md` + `Projects/crumb-tess-bridge/design/tasks.md`
**Mode:** diff (reviewing R1 changes only)
**Reviewed:** 2026-02-19
**Reviewers:** GPT-5.2, Gemini 2.5 Pro, Sonar Reasoning Pro
**Prior review:** `_system/reviews/2026-02-19-crumb-tess-bridge-action-plan.md`

---

## OpenAI GPT-5.2

- **[OAI-F1] STRENGTH:** All 10 R1 action items implemented completely. No paper fixes.
- **[OAI-F2] SIGNIFICANT:** Canonical JSON canonicalization rules need more detail (UTF-8, no BOM, no trailing newline, key sort, number formatting). CI check recommended.
- **[OAI-F3] SIGNIFICANT:** UUIDv7 de-dup store not specified — retention window, eviction policy, clock-skew behavior undefined.
- **[OAI-F4] MINOR:** M1 success criteria conflates Phase 1 and Phase 2 scoping.
- **[OAI-F5] SIGNIFICANT:** Allowlist should have single source of truth (schema enum or policy file) to prevent drift between Tess and Crumb.
- **[OAI-F6] MINOR:** CTB-008 Telegram rendering test methodology unclear (manual vs automated).
- **[OAI-F7] STRENGTH:** NLU → strict command parsing consistently applied.
- **[OAI-F8] STRENGTH:** CTB-008 → CTB-014 dependency closes a process gap.
- **[OAI-F9] MINOR:** CTB-005 response hash binding unclear (are responses hash-bound like requests?).
- **[OAI-F10] SIGNIFICANT:** U3 note not tied to CTB-011 acceptance criteria — risks being unenforced.

---

## Google Gemini 2.5 Pro

- **[GEM-S1] STRENGTH:** NLU → strict command parsing is a major security improvement.
- **[GEM-F1] SIGNIFICANT:** Error feedback path undefined — rejected requests (allowlist, schema, replay) don't specify how failure is communicated back to user via Telegram. Structured error response should be written to outbox.
- **[GEM-F2] MINOR:** "Verified safe" for transcript-poisoning in CTB-008 is ambiguous — safe from what?

---

## Perplexity Sonar Reasoning Pro

- **[PPLX-F1] MINOR:** U4 fate unclear after removal from M1 success criteria.
- **[PPLX-F2] SIGNIFICANT:** Response schema not explicitly designed as a task — CTB-005 says "matching response schema" but CTB-003 only mentions request schema.
- **[PPLX-F3] MINOR:** Error code taxonomy missing.
- **[PPLX-F4] CRITICAL:** Telegram rendering dependency blocks CTB-008 without test environment setup.
- **[PPLX-F5] SIGNIFICANT:** UUIDv7 cross-library compatibility not validated.
- **[PPLX-F6] SIGNIFICANT:** Threat-to-task mapping missing.
- **[PPLX-F7] MINOR:** Schema migration strategy absent.
- **[PPLX-F8] SIGNIFICANT:** "No NLU" policy implicit, needs explicit design constraint.
- **[PPLX-F9] MINOR:** "Verified safe" vague for transcript poisoning.

---

## Synthesis

### Consensus Findings

1. **"Verified safe" for transcript-poisoning is vague** (GEM-F2, PPLX-F9). Both reviewers independently flagged the same ambiguity — safe from misinterpretation? Safe from rendering exploits? Safe from log corruption?

2. **Error feedback path to user undefined** (GEM-F1, PPLX-F3). When requests are rejected (allowlist, schema, duplicate), the plan doesn't specify how the user learns about the failure via Telegram. Error responses need to be written to outbox and relayed.

3. **Response schema not explicitly in CTB-003 scope** (PPLX-F2, OAI-F9). CTB-005 now says "matching response schema" but no task explicitly designs the response schema. The spec has a response schema example — CTB-003 should explicitly cover both request and response.

4. **All 10 R1 items confirmed complete** (OAI-F1, all three reviewers verified). No partial implementations. No regressions identified.

### Unique Findings

1. **OAI-F5 — Allowlist single source of truth.** Genuine. If Tess and Crumb each hardcode their own allowlist, they'll drift. Should be a shared definition.

2. **OAI-F10 — U3 not tied to CTB-011 acceptance criteria.** Genuine. The note in M5 prerequisites is good documentation but doesn't create an enforceable check.

3. **PPLX-F4 — Telegram test environment blocks CTB-008.** See Considered and Declined.

4. **PPLX-F1 — U4 fate unclear.** Genuine catch — I need to correct the M1 unknown set. U4 (Telegram formatting) exists in the spec and IS resolved by CTB-002. The R1 reviewer (OAI-F7) incorrectly stated U4 doesn't exist; my correction dropped U4 by mistake.

### Contradictions

None. Reviewers are broadly aligned on the remaining gaps.

### Action Items

**Must-fix:**

- **A1** (PPLX-F2, OAI-F9): CTB-003 acceptance criteria should explicitly state it covers both request AND response schema design. The spec already has a response schema — CTB-003 formalizes it.

- **A2** (GEM-F2, PPLX-F9): Tighten CTB-008 transcript-poisoning criterion: "verified safe" → "does not corrupt transcript file format, does not cause misinterpretation by Crumb on re-read, and renders unambiguously for human review."

- **A3** (PPLX-F1, OAI-F4): Fix M1 success criteria — U4 exists in the spec (Telegram formatting, resolved by CTB-002). Correct set: U1/U2/U3/U4 resolved by CTB-001 + CTB-002. U5/U6 resolved by CTB-009 + CTB-010. U7 deferred to Phase 2. The R1 OAI-F7 finding incorrectly stated U4 doesn't exist.

**Should-fix:**

- **A4** (GEM-F1): Add to CTB-005 acceptance criteria: "Rejected requests (schema invalid, out-of-scope operation, duplicate ID) produce structured error response in outbox with error code and human-readable message."

- **A5** (OAI-F5): Add to CTB-003: "Operation allowlist defined as a single authoritative source (schema enum). Both Tess and Crumb import from the schema definition."

- **A6** (OAI-F10): Add to CTB-011 acceptance criteria: "U3 validated: repeated automated invocations work correctly, state persistence across sessions confirmed, no session collision with interactive sessions."

### Considered and Declined

- **PPLX-F4** (Telegram test environment): `incorrect` — Tess IS the Telegram bot (@tdusk42_bot), already running and connected. "Actual Telegram rendering" means sending test payloads through the existing bot and inspecting the display. No separate test environment or API integration needed. The infrastructure already exists from the colocation project.

- **PPLX-F5** (UUIDv7 cross-library): `incorrect` — UUIDv7 is generated only by Tess (CTB-004). Crumb reads the UUID for idempotency but doesn't generate UUIDs. Cross-library compatibility is a non-issue — only one side generates.

- **PPLX-F6** (threat-to-task mapping): `constraint` — Same finding as R1 PPLX-F4, already declined. The spec's threat model section maps each BT to its mitigations. A separate matrix duplicates the spec.

- **OAI-F2** (canonicalization rules detail): `constraint` — The spec already defines these precisely in §Protocol Design, Canonical JSON Specification (7 rules + test vector). CTB-003 implements the spec's rules. Adding them again to acceptance criteria would duplicate the normative source.

- **OAI-F3** (de-dup retention window): `out-of-scope` — Phase 1 volume is trivially low (single-digit requests/day). `.processed-ids` is a simple append log. Retention policy is Phase 3 hardening scope.

- **PPLX-F7** (schema migration strategy): `overkill` — We're at schema version 1.0 for a two-system integration built by one person. Migration strategy for a hypothetical v2.0 is premature. Version field exists for forward compatibility.

- **PPLX-F8** ("no NLU" explicit constraint): `overkill` — Already stated in: action plan description, CTB-004 description, CTB-004 acceptance criteria ("strict command parsing into allowlisted operations (no free-form NLU)"), and the spec's governance model ("Tess NEVER interprets the user's intent"). Four locations is sufficient.

- **PPLX-F3** (error code taxonomy): `out-of-scope` — Error codes are implementation detail for CTB-004/CTB-005. The acceptance criteria already require rejection behavior. Enumerating codes before implementation overspecifies.

- **OAI-F6** (Telegram test methodology): `out-of-scope` — CTB-008 is a manual security testing task by nature. The methodology (send payloads via existing bot, inspect display) is straightforward. Specifying screenshot methodology is process overhead for a solo operator.
