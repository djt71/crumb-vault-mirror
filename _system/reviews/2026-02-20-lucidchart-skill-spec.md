---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: _inbox/diagramming-skill-staging/lucidchart-skill-spec.md
artifact_type: specification
artifact_hash: 3404d627
prompt_hash: ce67d460
base_ref: null
project: null
domain: software
skill_origin: peer-review
created: 2026-02-20
updated: 2026-02-20
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 53088
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-lucidchart-skill-spec-openai.json
  deepseek:
    http_status: 200
    latency_ms: 43356
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-lucidchart-skill-spec-deepseek.json
  google:
    http_status: 200
    latency_ms: 33354
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-lucidchart-skill-spec-google.json
tags:
  - review
  - peer-review
---

# Peer Review: Lucidchart Skill Specification

**Artifact:** `_inbox/diagramming-skill-staging/lucidchart-skill-spec.md`
**Mode:** full
**Reviewed:** 2026-02-20
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2-Thinking)
**Review prompt:** Full review of updated Lucidchart skill spec after open question resolution and API research. Focus on API Access Gate completeness, verification confidence, auth strategy, schema correctness, conversion feasibility, and smoke test coverage.

---

## OpenAI (GPT-5.2)

- [F1]
- [Severity]: **STRENGTH**
- [Finding]: The **API Access Gate** section correctly elevates "Developer Role + SSO" as a *blocking prerequisite* and gives a decision tree (A/B/C) plus a "not viable" conclusion.
- [Why]: This is the single biggest real-world risk for enterprise Lucid deployments; without this gate you can sink time into implementation that can't be used in the target environment.
- [Fix]: None required for the basic framing.

- [F2]
- [Severity]: **SIGNIFICANT**
- [Finding]: API Access Gate is good, but not fully comprehensive: it doesn't explicitly require verifying **(a)** API access is enabled for the specific Lucid *product* (Lucidchart vs Lucidspark), **(b)** the account can generate **API keys** specifically (not just OAuth apps), and **(c)** that the intended scopes/grants are actually available under the enterprise policy.
- [Why]: Some enterprises allow developer portal access but restrict key creation, restrict scopes, or only allow OAuth with admin consent. You can still waste effort if you only verify portal access generically.
- [Fix]: Add explicit checks to the gate:
  1) Confirm tenant policy allows **API keys** (not only OAuth).
  2) Confirm ability to request the needed permission set (Document edit/content scope) and whether **admin consent** is required.
  3) Confirm the API is enabled for the Lucidchart instance the customer uses (and which "product" parameter values are accepted).

- [F3]
- [Severity]: **SIGNIFICANT**
- [Finding]: "**VERIFIED against Lucid developer docs**" is used repeatedly, but the spec also includes several items that look like *interpretation or inference* (e.g., "likely interchangeable" hosts, specific MIME type string, certain limits, z-order rule) without separating "direct quote from docs" vs "derived".
- [Why]: Overstated verification creates false confidence; diagram import APIs often have undocumented edge cases (ZIP root naming, multipart field names, MIME strictness, response fields).
- [Fix]: Replace the single label with a 3-tier tagging system and apply consistently:
  - **DOC-VERIFIED (quote/explicit)**: exact values directly stated in docs (include URL to doc section).
  - **DOC-INFERRED**: conclusion drawn from docs (requires smoke test).
  - **UNVERIFIED/EMPIRICAL**: learned via testing only.
  Also add a short "Evidence" line for each verified claim (doc URL + section heading).

- [F4]
- [Severity]: **CRITICAL**
- [Finding]: The `.lucid` ZIP **file structure and packaging command conflict**. The spec states a ZIP containing an `import.lucid/` directory with `document.json` inside, but the packaging example zips `document.json images/` at the root and does not create `import.lucid/`.
- [Why]: Import formats are often strict about internal paths. If the API expects `import.lucid/document.json`, the provided zip command will reliably fail.
- [Fix]: Make the ZIP layout unambiguous and match the command. For example:
  - Create staging dir `/tmp/lucid-export/import.lucid/` and place `document.json`, `images/`, `data/` inside it.
  - Zip the *directory*:
    ```bash
    cd /tmp/lucid-export
    zip -r /tmp/diagram-name.lucid import.lucid/
    ```
  Also specify whether the top-level folder name must be exactly `import.lucid` or whether root files are acceptable (and mark as smoke-test required if unclear).

- [F5]
- [Severity]: **CRITICAL**
- [Finding]: The multipart upload uses `type=x-application/vnd.lucid.standardImport`, which looks suspicious: the `x-` prefix is typically part of a **MIME type** (`application/vnd...`), not `x-application/...`. Also, it's unclear whether the server requires `Content-Type: application/octet-stream` vs a specific vendor type, and whether the form field name must be `file`.
- [Why]: If MIME type or form field naming is strict, uploads will fail even if the ZIP is correct.
- [Fix]: In the spec, separate:
  - **HTTP header Content-Type for the request** (multipart boundary handled by curl)
  - **Part content-type for the file field**
  Then:
  1) Quote the exact MIME string from docs (or mark DOC-INFERRED).
  2) Provide a fallback approach known to work in many APIs:
     - omit the `type=...` override and let curl send `application/octet-stream`, unless docs explicitly require a vendor type.

- [F6]
- [Severity]: **SIGNIFICANT**
- [Finding]: The endpoint note "`api.lucid.co` vs `api.lucid.app` — likely interchangeable" is risky and undermines the "verified" posture.
- [Why]: DNS, tenancy routing, and auth audience can differ; one host may be deprecated or require different tokens.
- [Fix]: Choose a single canonical base URL as **DOC-VERIFIED** and treat the other as **UNVERIFIED fallback** gated behind smoke testing. Add an explicit note: "Do not ship with dual-host logic until tested."

- [F7]
- [Severity]: **SIGNIFICANT**
- [Finding]: Auth strategy ("prefer API keys, fall back to OAuth2; token refresh out of scope") is only partially aligned with "personal operating system" goals. For personal automation, manual refresh quickly becomes operational debt; for enterprise SSO, API keys may be disallowed.
- [Why]: You risk building something that either can't be used in the target enterprise (no keys) or becomes annoying/unreliable (manual refresh every hour / 180 days).
- [Fix]: Reframe as:
  - **Primary: OAuth2 with refresh** (implement refresh flow in v1 if feasible), because it's most compatible with SSO policies.
  - **Secondary: API key** when enterprise policy explicitly allows it.
  If you keep "manual refresh", at least add a minimal built-in refresh helper command/workflow and secure storage guidance.

- [F8]
- [Severity]: **MINOR**
- [Finding]: Environment variable naming implies OAuth token and API key are interchangeable (`LUCID_ACCESS_TOKEN`), but API keys are often passed differently (sometimes `Authorization: Bearer`, sometimes `X-Api-Key`).
- [Why]: Confusion here creates integration bugs and weakens the "verified" promise.
- [Fix]: Split configuration:
  - `LUCID_AUTH_MODE=api_key|oauth`
  - `LUCID_API_KEY=...` and/or `LUCID_ACCESS_TOKEN=...`
  - Document the exact required header for each mode as DOC-VERIFIED.

- [F9]
- [Severity]: **CRITICAL**
- [Finding]: The **Standard Import JSON schema** is presented as if authoritative, but key parts are likely incomplete/incorrect for a real importer: e.g., page `settings.size` vs actual fields, shape `type` enumerations, whether `Text` is a `type` vs `text` shape, whether `customData` is allowed, whether `note` exists, and whether `layers` exist in import v1.
- [Why]: If schema fields are wrong, Lucid may silently drop elements (worst-case: "success" but blank/partial diagram), making the tool unreliable for customer-facing output.
- [Fix]: Add:
  1) A **Schema fidelity section** listing which fields are DOC-VERIFIED vs guessed.
  2) A **minimum viable document.json** example known to import (1 page, 1 rectangle, 1 line).
  3) A requirement to implement a smoke test that imports the minimal doc and asserts presence of at least one shape and line.

- [F10]
- [Severity]: **SIGNIFICANT**
- [Finding]: The spec says "Parse response for `editUrl` and `viewUrl`" without marking it verified, and without defining error handling/response shape.
- [Why]: If the API returns different fields (or returns URLs via another endpoint), the skill can't complete its core promise (return an edit URL).
- [Fix]: Add a "Response contract" section:
  - DOC-VERIFIED example response payload (redacted).
  - If not available, mark as **needs smoke test** and specify fallback: return document ID and instruct user to open in Lucid UI.

- [F11]
- [Severity]: **SIGNIFICANT**
- [Finding]: Constraints claim "Create-only: cannot update existing documents via API" is plausible but stated categorically.
- [Why]: If Lucid later supports updates (or supports replacing content), this constraint could unnecessarily limit the design; if it's wrong, you may miss a better UX.
- [Fix]: Mark as DOC-VERIFIED with citation, or change to: "v1 skill will be create-only (even if API later supports updates)."

- [F12]
- [Severity]: **SIGNIFICANT**
- [Finding]: Rate limits, timeouts, and retry behavior are mentioned in the intro but not actually specified in the body (despite "deep research findings" claim).
- [Why]: Upload/import APIs often have strict rate limits and transient failures; without guidance you risk flaky automation.
- [Fix]: Add a concise "Operational limits" subsection:
  - Requests/minute (DOC-VERIFIED)
  - Max upload size (DOC-VERIFIED)
  - Recommended retry policy (e.g., exponential backoff on 429/5xx)
  - Typical import latency and whether the call is synchronous/asynchronous

- [F13]
- [Severity]: **MINOR**
- [Finding]: The layout rules include a "letter landscape (1100 x 850 usable area)" statement but the schema uses `size.type: letter` rather than explicit pixel dimensions.
- [Why]: If coordinate space isn't defined (points? pixels? arbitrary units?), generated diagrams may appear scaled/clipped.
- [Fix]: Define coordinate units as per docs (DOC-VERIFIED). If docs don't specify, add smoke-test requirement: place a shape at known bounds and confirm rendering.

- [F14]
- [Severity]: **SIGNIFICANT**
- [Finding]: "z-order limitation: all shapes must be on top of all lines, or vice versa. Cannot interleave." is a very specific rule that should be clearly tagged as verified vs inferred.
- [Why]: If wrong, you may unnecessarily constrain diagram quality; if right, it's a key gotcha that affects containers/overlays.
- [Fix]: Add citation or mark as "DOC-INFERRED/UNVERIFIED" and include a targeted smoke test (shape-line-shape overlap).

- [F15]
- [Severity]: **STRENGTH**
- [Finding]: Clear product positioning: Lucidchart is for externally shared/customer deliverables; Mermaid remains default. Routing table is conservative.
- [Why]: Prevents unnecessary API dependencies and keeps the local-first model intact.
- [Fix]: None.

- [F16]
- [Severity]: **MINOR**
- [Finding]: Resolved decisions (naming convention, example scope, parent folder default) are reasonable, but "no parent parameter" may lead to clutter in root for frequent use.
- [Why]: UX degradation over time; enterprise Lucid orgs often enforce folder hygiene.
- [Fix]: Add an optional config: `LUCID_PARENT_FOLDER_ID` (or folder path mapping) with "off by default" behavior.

- [F17]
- [Severity]: **SIGNIFICANT**
- [Finding]: Conversion feasibility is plausible at a high level, but the spec lacks a mapping table and explicitly acknowledged gaps (e.g., Mermaid subgraphs → containers vs swimlanes; Excalidraw freehand, groups, arrowheads, fonts).
- [Why]: Without explicit mappings, "best-effort" can become unpredictable and hard to debug.
- [Fix]: Add a compact mapping matrix:
  - Mermaid node shapes supported → Lucid `type`
  - Mermaid edge types/arrowheads → Lucid endpoint styles
  - Excalidraw element types → Lucid shapes/lines
  - Explicit "won't convert" list (freehand, embedded images unless exported, complex text styling)

- [F18]
- [Severity]: **CRITICAL**
- [Finding]: The spec does not clearly delineate **what must be smoke-tested** before declaring the skill usable, despite multiple "not tested live" caveats.
- [Why]: This skill is explicitly for customer-facing deliverables; reliability and correctness matter more than internal diagrams.
- [Fix]: Add a "Smoke test checklist (must pass)" section with 8–12 concrete tests, e.g.:
  1) Upload minimal doc; confirm non-empty diagram
  2) Upload with container + child; confirm magnetize
  3) Upload with labeled elbow line + arrowhead
  4) Upload with image asset (if supported)
  5) Verify returned `editUrl/viewUrl`
  6) Verify size limits behavior and error messages
  7) Verify auth mode(s) in the real enterprise SSO environment

- [F19]
- [Severity]: **MINOR**
- [Finding]: Vault reference note format is good, but it's missing the *source artifact hash/version* (e.g., the generated JSON) to enable reproducibility.
- [Why]: If a customer asks for changes, you want to be able to regenerate and diff.
- [Fix]: Store (or link to) the generated `document.json` and the `.lucid` file path/hash in the vault note, or store a "generation input" section.

- [F20]
- [Severity]: **STRENGTH**
- [Finding]: Good explicitness about constraints (no auto-layout, shape library gaps, container text behavior) and clear guidance to fall back to Mermaid when needed.
- [Why]: Sets correct expectations and reduces user surprise.
- [Fix]: None.

---

## DeepSeek (DeepSeek-V3.2-Thinking)

**Overall Assessment:** The specification is well-structured, comprehensive, and demonstrates thorough research. It successfully translates a user need (externally-shareable diagrams) into a concrete technical plan with appropriate guardrails. The "API Access Gate" is a particularly strong and necessary inclusion.

---

**F1**
- **Severity:** SIGNIFICANT
- **Finding:** The "VERIFIED against Lucid developer docs" claims, while valuable, risk overstating confidence. The spec correctly notes these items are "not tested with a live API," but the prominent "VERIFIED" label could be misinterpreted as implementation-ready.
- **Why:** Engineers or reviewers might assume these components are de-risked, leading to potential surprises during integration (e.g., undocumented required fields, differing MIME type handling).
- **Fix:** Replace "VERIFIED" with a more precise term like "DOCUMENTED" or "SOURCED FROM OFFICIAL DOCS". Add a new, consolidated section titled "Implementation Verification Status" that clearly tables what is documented-only, what has been smoke-tested, and what is unknown.

**F2**
- **Severity:** SIGNIFICANT
- **Finding:** The OAuth2 token refresh strategy ("user manages lifecycle manually") is a significant usability hurdle for a personal automation tool and contradicts the "simplest for personal automation" goal.
- **Why:** Requiring users to manually refresh a token every hour via a separate script or `curl` command defeats the purpose of an automated skill. This will lead to skill failure and user frustration.
- **Fix:** For v1, prioritize and mandate the API Key path as the only supported authentication method. Document the OAuth2 flow as a future enhancement. If API Keys are not universally available (e.g., certain enterprise plans), this must be a blocking prerequisite check, not a fallback.

**F3**
- **Severity:** MINOR
- **Finding:** The `document.json` schema is missing a `layers` array definition, though it's listed in the page structure.
- **Why:** While layers might be an advanced feature, omitting the schema leaves an ambiguity for implementers. The Lucid API may require an empty array or may fail validation if the property is missing or malformed.
- **Fix:** In the `document.json` schema example, include `"layers": []`. In the `shape-reference.md`, add a brief note explaining layer usage is out of scope for v1.

**F4**
- **Severity:** MINOR
- **Finding:** The constraints list is missing explicit API rate limits, which were mentioned as researched.
- **Why:** Rate limits directly impact the skill's reliability and error handling. Users pushing multiple diagrams in succession could encounter throttling.
- **Fix:** Add a constraint: "9. **Rate limiting:** API calls are subject to Lucid's rate limits (exact limits TBD via smoke test). Implement basic retry logic with exponential backoff for 429 responses."

**F5**
- **Severity:** STRENGTH
- **Finding:** The "API Access Gate" section is an excellent and critical addition. It explicitly prevents wasted effort by forcing a permissions check before any development begins.
- **Why:** Enterprise SSO and admin-controlled Developer Roles are a common, hidden obstacle for API integrations. Highlighting this as a blocking prerequisite is responsible and pragmatic.
- **Fix:** None. This is a best practice.

**F6**
- **Severity:** MINOR
- **Finding:** The conversion support section declares feasibility but lacks guidance on handling intrinsic format mismatches (e.g., Mermaid subgraphs vs. Lucid containers, Excalidraw's freehand elements).
- **Why:** Implementers might underestimate the complexity of the conversion, leading to a poor user experience when "approximate" conversions are too crude.
- **Fix:** Add a brief bullet list under each conversion type noting the key challenges (e.g., "Mermaid subgraphs map to Lucid containers, but nested positioning logic is non-trivial").

**F7**
- **Severity:** SIGNIFICANT
- **Finding:** The `z-order limitation` constraint is vague ("All shapes must be on top of all lines, or vice versa"). This is a major functional restriction that needs clearer explanation and impact assessment.
- **Why:** This severely limits diagram fidelity. Many diagrams (e.g., a line passing behind one shape and in front of another) cannot be accurately represented. The skill must have a defined strategy (e.g., all lines on top) and warn the user.
- **Fix:** Clarify the constraint: "Lucid Standard Import does not support fine-grained z-ordering. The skill will place all **lines above all shapes**. Diagrams where lines must pass behind shapes cannot be accurately rendered."

**F8**
- **Severity:** STRENGTH
- **Finding:** The decisions on resolved questions (naming convention, focused example scope, no parent folder) are appropriate and pragmatic for a v1 implementation.
- **Why:** They provide sensible defaults without over-engineering, allowing real usage patterns to inform future iterations. The chosen examples (DDI, Network, Query Path) effectively test the skill's core capabilities.
- **Fix:** None.

**F9**
- **Severity:** MINOR
- **Finding:** The procedure uses `curl` in a shell command, which assumes the `LUCID_ACCESS_TOKEN` environment variable is available in that shell's context. The skill's environment (`~/.config/crumb/.env`) may not be loaded.
- **Why:** This could cause silent authentication failures when the skill executes.
- **Fix:** Update Step 5 to explicitly source the environment file or, better, use a language-native HTTP client (Python's `urllib`) that can read the skill's configured environment directly.

**F10**
- **Severity:** STRENGTH
- **Finding:** The specification clearly delineates its relationship to other diagramming skills (Mermaid, Excalidraw) and wisely positions Lucidchart as an export target for external sharing, not a default.
- **Why:** This prevents skill sprawl and maintains a coherent user mental model: Mermaid/Excalidraw for vault work, Lucidchart for sharing.
- **Fix:** None.

---

## Google (Gemini 3 Pro Preview)

Based on the review of the Lucidchart Skill Specification, here are the findings categorized by severity.

### Review Summary
The specification is well-researched regarding the API mechanics (ZIP structure, JSON schema) and pragmatically addresses the biggest hurdle: Enterprise Authentication. However, it significantly underestimates the algorithmic complexity of converting Mermaid diagrams (which lack spatial data) to Lucidchart (which requires explicit X/Y coordinates).

---

[F1]
**Severity: CRITICAL**
**Finding:** The "Mermaid → Lucidchart" conversion requirement is likely technically infeasible within the scope of a standard skill.
**Why:** Mermaid is a declarative language that relies on a complex rendering engine (Dagre/Graphviz) to determine node positions. Lucidchart's Standard Import **requires explicit X, Y, Width, and Height** for every element. To convert Mermaid to Lucid, this skill would effectively need to implement a graph layout algorithm from scratch. Without this, the diagram will result in a stack of overlapping shapes at `{0,0}` or a crude list that defeats the purpose of a diagram.
**Fix:**
1.  **Scope Reduction:** Remove general Mermaid conversion.
2.  **Alternative:** Restrict conversion to **Flowcharts only** and implement a very strict "Columnar/Grid" layout logic (e.g., every node is placed in a grid `x = column * 200`, `y = row * 150`).
3.  **Warning:** Explicitly mark this feature as "Experimental: Layout will be linear/grid-based and require manual rearrangement."

[F2]
**Severity: STRENGTH**
**Finding:** The "API Access Gate" section is highly pragmatic and protects against "works on my machine" failures.
**Why:** Most integrations fail not because of code, but because of Enterprise SSO policies (e.g., Okta/SAML blocking API key generation). Identifying the specific "Developer Role" requirement and providing a flowchart for resolution (A/B/C options) ensures the user doesn't waste time coding against a blocked API.

[F3]
**Severity: SIGNIFICANT**
**Finding:** Z-Index/Layering logic is mentioned in Constraints but defined in the Schema.
**Why:** The Constraints section notes "Z-order limitation," but the Schema section does not explain *how* the API determines Z-order. In most drawing APIs, this is determined by the order of elements in the JSON array (painters algorithm: last item is on top). If the AI generates lines *before* shapes in the array, lines might appear behind shapes, looking broken.
**Fix:** Update the "Procedure: Step 3" or "document.json schema" to explicitly state: "Order matters: Render standard shapes first, then lines, then text overlays. Elements appearing later in the `shapes` or `lines` arrays will be drawn on top of earlier elements."

[F4]
**Severity: MINOR**
**Finding:** Rate Limits are missing from the spec text.
**Why:** The Context introduction claims "rate limits verified against official docs," but the actual specification text under "Network" or "Constraints" does not list them. If a user tries to push a batch of diagrams, they might hit a silent wall.
**Fix:** Add a specific line to "Constraints": "Rate Limit: Lucid API typically enforces ~100 requests/minute (verify current tier). Implement a 1-second delay between pushes if batching."

[F5]
**Severity: MINOR**
**Finding:** Ambiguity on Container "Magnetize" logic.
**Why:** The spec mentions "Children inside containers... for magnetize to work." However, it doesn't specify if the `groups` array is required to logically bind them, or if spatial overlap is sufficient for Lucid to treat them as attached.
**Fix:** Clarify in "Step 2: Plan layout": "Spatial overlap is sufficient for magnetization. Explicit grouping via the `groups` array is optional but recommended for logical coherence."

[F6]
**Severity: MINOR**
**Finding:** "Infoblox" specific company reference in the artifact.
**Why:** The "API Access Gate" section mentions "e.g., Infoblox via Okta/SAML". This appears to be leaked context from a specific user environment rather than generic specification text.
**Fix:** Replace "Infoblox" with "Your Organization" or "[Enterprise Company]" to keep the skill generic and shareable.

[F7]
**Severity: MINOR**
**Finding:** Missing `lineType` definitions in constraints.
**Why:** The spec uses `elbow` in the example. The AI needs to know what other types are legal (e.g., `straight`, `curved`) to make stylistic decisions, or it will default to `elbow` for everything (which looks bad for sequence diagrams).
**Fix:** Add a brief row to the supported libraries or Schema section listing valid `lineType` values: `elbow`, `straight`, `curved`.

---

## Synthesis

### Consensus Findings

**1. "VERIFIED" label overstates confidence** (OAI-F3, DS-F1)
Both OpenAI and DeepSeek flagged that "VERIFIED against Lucid developer docs" is misleading when paired with "not tested against a live API." The label implies de-risked when it's really "documented but untested." OpenAI suggests a 3-tier tagging system (DOC-VERIFIED / DOC-INFERRED / UNVERIFIED); DeepSeek suggests renaming to "DOCUMENTED" or "SOURCED FROM OFFICIAL DOCS."

**2. Rate limits missing from spec body** (OAI-F12, DS-F4, GEM-F4)
All three reviewers noted that rate limits were researched but not included in the spec text. The deep research found 750 req/min global with potentially stricter per-endpoint limits. This belongs in a Constraints or Operational Limits subsection.

**3. Z-order constraint needs clarification** (OAI-F14, DS-F7, GEM-F3)
All three flagged the z-order limitation as vague. The spec says shapes and lines can't interleave but doesn't specify the ordering strategy or how array order maps to rendering. Gemini's suggestion (painters algorithm — array order = z-order) is the most specific.

**4. API Access Gate is a strength** (OAI-F1, DS-F5, GEM-F2)
Universal agreement that the API Access Gate is well-designed and addresses the biggest real-world risk.

**5. Conversion section lacks specificity** (OAI-F17, DS-F6, GEM-F1)
All three flagged conversion support as underspecified. Gemini went further: Mermaid→Lucidchart is likely infeasible because Mermaid has no spatial data — the skill would need to implement a layout algorithm. OpenAI and DeepSeek focused on missing mapping tables and gap acknowledgment.

**6. Auth strategy tension** (OAI-F7, DS-F2)
OpenAI and DeepSeek both flagged the auth strategy as misaligned. OpenAI says prioritize OAuth2 with refresh for SSO compatibility; DeepSeek says mandate API Key only for v1 and defer OAuth2. These contradict each other (see Contradictions below).

**7. Resolved questions are sound** (DS-F8, OAI-F16 partial)
DeepSeek and OpenAI agree the resolved decisions are pragmatic for v1.

### Unique Findings

**OAI-F4 (CRITICAL): ZIP structure/command mismatch.** The spec shows an `import.lucid/` directory in the file structure diagram but the `zip` command packages `document.json` at the root. This is a genuine catch — the two representations are inconsistent. However, reviewing the Lucid docs, the Standard Import expects files **at the root of the ZIP**, not inside a subdirectory. The `import.lucid` label in the spec's tree diagram is the *name of the ZIP file*, not a subdirectory. The command is correct; the diagram is misleading.

**OAI-F9 (CRITICAL): Schema fields may be incomplete/incorrect.** Valid concern about whether all fields (`customData`, `note`, `layers`) actually exist in import v1. The spec's schema came from documentation review, not from testing. However, this is inherent to a draft spec — the smoke test gate is the right mitigation, not exhaustive field verification in the spec.

**OAI-F18 (CRITICAL): No formal smoke test checklist.** Strong finding. The spec has multiple "not tested live" caveats but doesn't consolidate them into a concrete verification plan. For a customer-facing skill, this should be a section with pass/fail criteria.

**GEM-F1 (CRITICAL): Mermaid conversion is infeasible.** The strongest unique insight. Mermaid is declarative; Lucidchart requires explicit coordinates. Converting Mermaid to Lucid means reimplementing a graph layout engine. This deserves serious consideration — either scope-reduce to grid-based flowcharts or remove the feature.

**GEM-F6 (MINOR): Infoblox reference in spec.** Valid — the spec is personal but referencing the employer by name in a technical spec is unnecessary. Easy fix.

**GEM-F5 (MINOR): Magnetize ambiguity.** Useful clarification needed — is spatial overlap sufficient, or does the groups array matter?

**OAI-F5 (CRITICAL): MIME type suspicion.** This was already resolved by deep research — the `x-application/vnd.lucid.standardImport` MIME type is confirmed in Lucid's official docs and curl examples. The `x-application` prefix is non-standard per RFC 6838 but is what Lucid's API actually requires. It's a form-data field type, not an HTTP Content-Type header.

### Contradictions

**Auth strategy direction:** OpenAI (OAI-F7) says prioritize OAuth2 with refresh because enterprise SSO may disallow API keys. DeepSeek (DS-F2) says mandate API Key only and defer OAuth2 because manual token refresh defeats automation. **Both have valid points from different angles.** The resolution depends on whether API keys are available in the target enterprise environment — which is exactly what the API Access Gate is designed to determine. The spec's current "prefer API Key, document OAuth2" stance is reasonable as a starting position. The gate will force the auth decision before implementation.

### Action Items

**Must-fix** (blocking for spec maturity):

- **A1** — Rename "VERIFIED against Lucid developer docs" to "DOCUMENTED in Lucid developer docs" and add "(not live-tested)" suffix. Remove "likely interchangeable" host note — pick `api.lucid.co` as canonical, note `api.lucid.app` as unverified alternative. (Source: OAI-F3, OAI-F6, DS-F1)

- **A2** — Add a "Smoke Test Checklist" section with concrete pass/fail criteria: minimal doc import, container+child magnetize, labeled elbow line, auth verification, editUrl/viewUrl in response, error response handling. Gate: all must pass before skill is declared usable. (Source: OAI-F18, OAI-F9, OAI-F10)

- **A3** — Scope-reduce Mermaid→Lucidchart conversion to "Experimental: grid-based flowcharts only." Add explicit warning that layout will be approximate and require manual rearrangement. Consider removing general Mermaid conversion entirely. (Source: GEM-F1, OAI-F17)

- **A4** — Clarify ZIP structure diagram: rename the tree label from `import.lucid` to show it as the output file name, not a subdirectory. The files go at the root of the ZIP. Ensure the `zip` command matches. (Source: OAI-F4)

**Should-fix** (improve spec quality):

- **A5** — Add "Operational Limits" subsection to Constraints: rate limits (750 req/min global, per-endpoint may be stricter), upload size limits (ZIP: 50MB, document.json: 2MB), retry recommendation (exponential backoff on 429/5xx), sync vs async import behavior. (Source: OAI-F12, DS-F4, GEM-F4)

- **A6** — Clarify z-order: specify that array order = rendering order (painters algorithm), define the skill's strategy (shapes first, then lines, then text overlays), mark as DOC-INFERRED pending smoke test. (Source: OAI-F14, DS-F7, GEM-F3)

- **A7** — Add API Access Gate sub-checks: verify API key creation is allowed (not just portal access), verify DocumentEdit grant is available, verify Lucidchart product API is enabled. (Source: OAI-F2)

- **A8** — Add conversion mapping matrix with explicit "won't convert" list (freehand drawings, embedded images, complex text styling, Excalidraw groups). (Source: OAI-F17, DS-F6)

- **A9** — Clarify magnetize behavior: spatial overlap is sufficient for containment; groups array is optional for logical coherence. Mark as DOC-INFERRED. (Source: GEM-F5)

**Defer** (minor or speculative):

- **A10** — Replace Infoblox reference with generic "[Your Organization]". Low priority since this is a personal spec, not a published artifact. (Source: GEM-F6)

- **A11** — Add `lineType` enumeration (`elbow`, `straight`, `curved`). (Source: GEM-F7)

- **A12** — Split env var into `LUCID_AUTH_MODE` + separate key/token vars. Premature until auth method is determined by the API Access Gate. (Source: OAI-F8)

- **A13** — Add source artifact hash to vault reference note for reproducibility. (Source: OAI-F19)

- **A14** — Include `"layers": []` in schema example. (Source: DS-F3)

- **A15** — Add optional `LUCID_PARENT_FOLDER_ID` config. (Source: OAI-F16)

- **A16** — Add env sourcing step to procedure Step 5. (Source: DS-F9)

### Considered and Declined

- **OAI-F5** (MIME type suspicion) — `incorrect`. The `x-application/vnd.lucid.standardImport` MIME type is confirmed across multiple official Lucid sources including curl examples, the Standard Import overview, and the API reference. The `x-application` prefix is non-standard per RFC 6838 but is what Lucid requires. Deep research already verified this.

- **OAI-F11** (create-only constraint too categorical) — `constraint`. The spec is correct: the REST API does not support updating existing documents. The Extension API can modify canvas contents but is a different paradigm. Stating this as a constraint is accurate.

- **DS-F2** (mandate API Key only, defer OAuth2) — `constraint`. The spec already prefers API keys. Whether OAuth2 is needed depends on the API Access Gate outcome. Removing it entirely would leave no fallback if the enterprise doesn't allow API keys.

- **OAI-F7** (prioritize OAuth2 with refresh) — `constraint`. Implementing a full OAuth2 refresh flow in v1 adds significant scope. The current "API Key preferred, OAuth2 documented for fallback" is the right balance for v1 given the API Access Gate will determine the actual requirement.
