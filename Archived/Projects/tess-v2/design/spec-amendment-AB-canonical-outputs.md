---
project: tess-v2
type: design-input
domain: software
status: accepted
created: 2026-04-17
updated: 2026-04-17
source: tv2-057-promotion-integration-note.md §2, §4.4; staging-promotion-design.md §13 Open Question #1 (now closed)
tags:
  - spec-amendment
  - schema
  - promotion
  - state-machine
---

# Spec Amendment AB: Canonical Outputs Field

## Problem Statement

Tess v2's promotion engine needs a contract-level declaration of which files
in `_staging/<contract-id>/` are the canonical artifacts that must be atomically
renamed into the vault, and where each one lands. Without this declaration the
state machine can only distinguish Class A (STAGED-then-promote) from Class C
(side-effect only, no promotion) heuristically.

TV2-057a shipped a placeholder classifier — a hardcoded `_CLASS_C_SERVICES`
allowlist — so the 5800+ Class C rows accumulating as `outcome='staged'` could
be cleaned up before promotion code landed. The placeholder is explicitly
marked for replacement by this amendment:

```python
# classifier.py:46 (TV2-057a)
# TODO(TV2-057b): replace allowlist with `len(contract.canonical_outputs) == 0`
# check once the schema field lands.
```

`staging-promotion-design.md` §3.4 ("Target path derivation") required the
mapping from staging artifacts to canonical paths but deferred defining it
(Open Question #1). TV2-021b shipped without closing it. The gap has sat
through every subsequent design session.

Amendment AB closes the gap.

## Architecture Decision

**AD-016: The staging-to-canonical mapping is a first-class contract field
(`canonical_outputs`), carried on the contract YAML and baked in at
generation time (not resolved at runtime from `service-interfaces.md`).**

Deliberation record and ratification: `tv2-057-promotion-integration-note.md`
§2 (Options A/B/C analysis), §2.2 (C1-vs-C2 sub-question), §7a (closed
decisions 2026-04-17).

### Option selection (recap)

- **Option A — per-contract with full shape.** ✓ Selected.
- **Option B — per-service registry with runtime lookup.** ✗ Indirection layer
  with no existing implementation; service-interfaces.md is 1551 lines of
  mixed prose and YAML, not machine-readable.
- **Option C — hybrid (documented in service-interfaces.md, carried on
  contract via inheritance).** ✓ Selected as the overall shape.

### C1 vs C2 sub-question (resolved)

- **C1 — runtime resolution at contract-load time.** ✗ Would require a
  parser for `service-interfaces.md`. No mid-flight-change pressure to
  justify building it.
- **C2 — generation-time bake-in.** ✓ Selected. Contract YAML declares the
  field directly. When `service-interfaces.md` changes, the operator
  updates affected contract YAMLs manually. Matches Tess's low-frequency
  single-operator change profile.

## Schema Addition

### Field: `canonical_outputs` (optional, list)

```yaml
canonical_outputs:
  - staging_name: "attention-plan.md"
    destination: "_system/daily/{date}.md"
```

Each entry declares one canonical artifact the service produces:

- **`staging_name`** (string, required): exact filename inside the contract's
  `staging_path/`. No slashes — bare filename only. The promotion engine reads
  this file from staging.
- **`destination`** (string, required): vault-relative canonical path.
  Placeholders allowed from a closed set: `{date}` (YYYY-MM-DD UTC), `{week}`
  (YYYY-Www), `{timestamp}` (ISO 8601 UTC). Resolution happens at promotion
  time.

### Semantics

- **Absence of the field** → contract is Class C (side-effect only, no
  promotion). The classifier returns `is_side_effect_contract(c) == True`.
- **Populated field** → contract is Class A. The Ralph loop terminal state
  is STAGED; post-loop, the promotion engine moves each staging artifact
  to its destination atomically.
- **Empty list** (`canonical_outputs: []`) → rejected at load time. Absence
  is the correct way to mark Class C; a literal empty list is treated as a
  schema violation to surface typos/leftover edits.

### Validation rules (enforced in `contract.py`)

1. Optional field. When present, must be a non-empty list of mappings.
2. Each entry must declare both `staging_name` and `destination` as
   non-empty strings.
3. `staging_name` must be a bare filename (no `/`, no `.`, no `..`).
4. `destination` must be vault-relative (must not start with `/`).
5. `destination` must not contain `..` path components.
6. `destination` placeholders must come from the closed set
   (`{date}`, `{week}`, `{timestamp}`).
7. `staging_name` values must be unique within the contract's
   `canonical_outputs` list (a single filename cannot promote to two
   destinations).
8. `destination` values must be unique within the list (two artifacts
   cannot target the same canonical path).
9. No extra keys permitted on each entry (closed per-entry schema).

### Schema version

Contract schema v1.1.0 → v1.2.0. `SUPPORTED_MINOR` bumped in `contract.py`.
Existing v1.0.0 and v1.1.0 contracts continue to load and are treated as
Class C via the transitional fallback (see below).

## Classifier Swap

### Primary predicate (post-AB)

```python
def is_side_effect_contract(contract: Contract) -> bool:
    if contract.canonical_outputs:
        return False
    return contract.service in _CLASS_C_SERVICES  # transitional fallback
```

Populated `canonical_outputs` is the primary Class A signal. It trumps the
allowlist unambiguously — a service can be in the allowlist and still
classify as Class A if a specific contract declares canonical outputs.

### Transitional fallback

The TV2-057a `_CLASS_C_SERVICES` allowlist is retained as a fallback for
contracts that have not yet been migrated to carry the field. Two services
were added to the allowlist as part of AB's landing (TV2-057b §4.4 audit):

- **`connections-brainstorm`** — previously Class A in the classifier
  (absent from the allowlist → default). Audit revealed the wrapper writes
  to `_openclaw/inbox/brainstorm-{date}.md`, which is mirror space per
  integration-note §5. Added to the allowlist; no `canonical_outputs`
  declaration.
- **`vault-health`** — previously Class A. Audit revealed the Tess v2
  wrapper produces only staging-scoped output; the canonical
  `_openclaw/state/vault-health-notes.md` is still written by the
  still-loaded OpenClaw plist. Added to the allowlist; canonical-artifact
  ownership transfers to Tess v2 under TV2-040, at which point the
  `canonical_outputs` declaration gets added.

### Safe default for unknowns

Services not in the allowlist and not declaring `canonical_outputs` default
to Class A (the classifier returns `False`). This preserves the TV2-057a
safety choice — a new service that was mistakenly not classified sits in
STAGED and surfaces as a stuck row the operator notices, rather than
silently landing COMPLETED with no promotion of a file that may have needed
it.

### Follow-up retirement

Once every contract carries an explicit class marker (either non-empty
`canonical_outputs` for Class A or is confirmed Class C by omission), the
allowlist becomes dead code. Retirement tracked outside TV2-057b — earliest
viable timing is after TV2-057d (promotion wiring) and TV2-040 (OpenClaw
decommission), when all production contracts have been audited.

## Backward Compatibility

Additive change. Existing contracts without `canonical_outputs` continue to
load. Behavior change for `connections-brainstorm` and `vault-health` (A→C
reclassification) is intentional per the §4.4 audit and is the only observable
runtime difference at AB's landing moment.

Schema version bump (1.1.0 → 1.2.0) is a minor version bump — no major
version gate is required. Contracts declaring `schema_version: "1.0.0"` or
`"1.1.0"` continue to load; those are the pre-AB contracts.

## Related Work

- **TV2-057a** — shipped the `COMPLETED` terminal outcome and the placeholder
  classifier. Historical backfill held until TV2-038 Phase 5 close; backfill
  scope expands to 14 services (adds `connections-brainstorm` + `vault-health`)
  as a consequence of AB's reclassification.
- **TV2-057b** — the implementation vehicle for AB. Lands schema, validation,
  classifier swap, one live contract declaration (`daily-attention`),
  `staging-promotion-design.md` §3.4.2 Amendment (dispatch modes), and the
  `staging-promotion-design.md` §13 Open Question #1 closure.
- **TV2-057c** — uses `canonical_outputs` as the input to
  `WriteLockTable.acquire_locks()` (each entry's resolved destination is a
  locked path).
- **TV2-057d** — uses `canonical_outputs` as the input to
  `PromotionEngine.build_manifest()` + `promote()`. Per-service migration;
  `daily-attention` first. Spec: `tv2-057d-daily-attention-migration.md`.
- **TV2-040** — transfers `vault-health` canonical-artifact ownership from
  OpenClaw to Tess v2; at that point `vault-health`'s contract gains a
  `canonical_outputs` declaration and is removed from the transitional
  allowlist.

## Precedent and Naming

Amendment AB continues the alphabetical sequence after AA (Vault Semantic
Search Integration, 2026-04-04). Amendments T–Y live bundled in
`spec-amendments-harness.md`; Z and AA shipped as standalone documents. AB
follows that pattern.

## Provenance

- Integration note: `tv2-057-promotion-integration-note.md` (status
  `accepted` as of 2026-04-17).
- Code landing: `tess-v2` commit `f336ae9` (TV2-057b).
- Validation rules: `src/tess/contract.py` `_validate_raw()` clause 12.
- Field shape: `src/tess/contract.py` `CanonicalOutput` dataclass.
- Classifier swap: `src/tess/classifier.py` `is_side_effect_contract()`.
- First live declaration: `contracts/daily-attention.yaml`.
- Test coverage: `tests/test_contract.py::TestCanonicalOutputs`,
  `tests/test_classifier.py`, `tests/test_ralph.py::TestSideEffectClassification`.
