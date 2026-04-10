---
type: review
review_mode: full
review_round: 1
prior_review: _system/reviews/2026-02-18-peer-review-skill.md
artifact: .claude/skills/peer-review/SKILL.md
artifact_type: skill
artifact_hash: 6662ddba
prompt_hash: d5b8860d
project: crumb
domain: software
skill_origin: peer-review
created: 2026-02-18
updated: 2026-02-18
reviewers:
  - openai/gpt-5.2
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: 4096
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: true
  soft_heuristic_triggered: false
  user_override: false
  notes: >
    Hard denylist triggered on lines 53-54 (regex pattern definitions for the safety
    gate itself). Patterns like sk-proj- and -----BEGIN PRIVATE KEY----- appear as
    documentation of what to scan for. Downgraded — clearly illustrative regex patterns.
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 56406
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-18-peer-review-skill-full-openai.json
  google:
    http_status: 429
    latency_ms: 415
    attempts: 2
    error: "Quota exceeded (billing limit, not transient rate limit). Skipped."
    raw_json: _system/reviews/raw/2026-02-18-peer-review-skill-full-google.json
  perplexity:
    http_status: 200
    latency_ms: 45574
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-18-peer-review-skill-full-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review: peer-review skill (SKILL.md) — Full Review

**Artifact:** .claude/skills/peer-review/SKILL.md
**Mode:** full
**Reviewed:** 2026-02-18
**Reviewers:** OpenAI GPT-5.2, Perplexity Sonar Reasoning Pro (Google Gemini skipped — quota exceeded)
**Review prompt:** Structured review focusing on procedure correctness, error handling completeness, safety gate soundness, curl/API pattern correctness, and synthesis methodology.

---

## OpenAI (gpt-5.2)

- [F1]
- [Severity]: CRITICAL
- [Finding]: OpenAI/Perplexity "Chat Completions" payload/endpoint assumption is likely wrong for current OpenAI models (esp. "GPT-5.2") and may fail or silently degrade.
- [Why]: OpenAI's newest models are commonly served via the **Responses API** rather than `/v1/chat/completions`; some models reject chat-completions payloads or ignore fields. You already hit a token-param mismatch once; this is the same class of failure but bigger (wrong endpoint/schema).
- [Fix]: In `docs/peer-review-config.md`, require per-provider fields: `api_style: responses|chat_completions`, `endpoint`, and `response_text_jq`. Implement two code paths.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Token parameter handling is underspecified/inconsistent: the script passes `"{max_tokens}"` even when the comment says OpenAI needs `max_completion_tokens`, and Gemini uses `maxOutputTokens`; but the procedure doesn't define where `{max_tokens}` comes from or how it maps per provider/model.
- [Why]: Misconfiguration here causes hard API failures or truncated reviews; also makes config non-portable across providers.
- [Fix]: Rename the abstract config value to `token_budget` and require a per-reviewer `token_param` plus validation before send.

- [F3]
- [Severity]: CRITICAL
- [Finding]: Safety gate "hard denylist" includes patterns (`sk-...`, `sk-ant-`) that will frequently appear in docs/examples; downgrade logic relies on "nearby text contains markers" but "nearby" is undefined and brittle.
- [Why]: You'll either block too often (review UX pain) or, if "nearby" is implemented loosely, you may inadvertently downgrade real secrets.
- [Fix]: Define an explicit algorithm: parse fenced code blocks separately, only downgrade if matched value also matches an explicit placeholder regex (contains `...`, `YOUR_`, `your-`, all X's) OR is a known non-secret format. Add a "redaction mode" option.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: The procedure says "scan artifact content for sensitive data" but doesn't specify how to obtain line numbers/where matches are, especially if content is assembled from diffs/context windows.
- [Why]: Without stable line numbers, the user can't remediate quickly.
- [Fix]: Implement match reporting as line number + snippet with the match partially masked. For diff mode, reference hunk headers.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: "Known customer domains denylist" is referenced but the mechanism is vague and risks leaking the denylist itself into prompts.
- [Why]: Inconsistent behavior and potential privacy issues.
- [Fix]: Only use the denylist locally for detection; never include denylist entries in prompts; in warnings, report "matched customer domain pattern" rather than dumping the denylist.

- [F6]
- [Severity]: CRITICAL
- [Finding]: Diff mode logic depends on "prior review exists" and "last reviewed commit," but the review note schema doesn't store commit SHA, branch, or base reference; also `git diff main` assumes a `main` branch.
- [Why]: Diff mode will be unreliable and may compare against the wrong base.
- [Fix]: Extend review frontmatter with git metadata (tracked, base_ref, base_commit, head_commit). Detect default branch via `git symbolic-ref refs/remotes/origin/HEAD`.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: "Large-diff escape hatch" includes a qualitative criterion ("touches foundational sections") without detection rules.
- [Why]: Unclear implementation; inconsistent switching between diff/full may surprise users.
- [Fix]: Implement deterministic triggers: lines > 800 OR diff includes edits to frontmatter delimiters, step headings, etc.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Response extraction assumes `.choices[0].message.content` for OpenAI/Perplexity and single text part for Gemini; both providers can return multi-part content or alternate shapes.
- [Why]: May write empty reviews even when the model responded, or crash parsing.
- [Fix]: Make extractor configurable per reviewer. For Gemini, join all parts.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: Curl error handling is underspecified: no `--fail-with-body`, no capture of stderr.
- [Why]: Can mis-parse status/latency, lose error bodies, treat failures as successes.
- [Fix]: Standardize curl invocation with stderr capture and proper status extraction.

- [F10]
- [Severity]: MINOR
- [Finding]: Temp files are only partially cleaned up; reviewer name interpolated into `/tmp` path without sanitization.
- [Why]: Leaves sensitive artifacts on disk; potential path weirdness.
- [Fix]: Use `mktemp` and trap cleanup.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: Sequential-only reviewer calls increases latency; the procedure mandates sequential "not in parallel" without justification.
- [Why]: For 2-3 reviewers it's probably fine, but timeouts/retries make the skill feel slow.
- [Fix]: Keep sequential as default but add config flag for limited parallelism.

- [F12]
- [Severity]: CRITICAL
- [Finding]: The skill says "Read config ... using deterministic extraction (grep/sed)" but doesn't define the config schema; brittle and can mis-read values.
- [Why]: Misread config leads to wrong endpoints/models/token params.
- [Fix]: Define config as strict YAML frontmatter. Parse with python `yaml.safe_load` or if you truly must avoid deps, require JSON.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: Review note frontmatter requires many fields, but some are not computable as described (e.g., `project`/`domain` "from artifact frontmatter" when artifact may be inline).
- [Why]: Either you violate your own constraint or fill with incorrect nulls.
- [Fix]: Specify extraction rules and make required-vs-optional explicit.

- [F14]
- [Severity]: STRENGTH
- [Finding]: Strong synthesis methodology: consensus/unique/contradictions + action items + considered/declined is decision-oriented and guards against over-trusting any single model.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: "Considered and Declined" requires Claude to reject findings, but there's no explicit rule for when to reject vs defer.
- [Why]: Users may not trust the synthesis if declines feel opaque.
- [Fix]: Add a lightweight rubric: decline if based on false assumption, conflicts with stated constraints, or adds complexity without benefit. Require one-line justification.

- [F16]
- [Severity]: MINOR
- [Finding]: "Start a new review cycle with explicit override" may be confused with the Safety Gate OVERRIDE keyword.
- [Why]: Overloaded "override" terminology can cause accidental secret leakage.
- [Fix]: Use distinct keywords: `SAFETY_OVERRIDE` for safety gate, `NEW_CYCLE` for round resets.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: Raw JSON responses are stored, but the procedure doesn't mention redacting sensitive content that might come back in responses (e.g., model echoes secrets).
- [Why]: Even if you block sends, in override cases you can persist secrets into `_system/reviews/raw/`.
- [Fix]: If safety override is used, add option to skip raw storage or run post-response redaction pass.

- [F18]
- [Severity]: MINOR
- [Finding]: "All API calls use curl — no SDKs" but Python is used for JSON writing/extraction; could be misread as violating the constraint.
- [Why]: Ambiguity in constraints causes confusion.
- [Fix]: Reword: "All HTTP requests use curl; helper scripting (python) allowed for JSON and parsing."

- [F19]
- [Severity]: STRENGTH
- [Finding]: Good operational metadata capture (status, latency, attempts, raw_json_path, hashes) supports reproducibility and debugging.

- [F20]
- [Severity]: SIGNIFICANT
- [Finding]: Retry policy doesn't include jitter and doesn't mention handling curl exit codes (6, 7, 28, 35), only HTTP status.
- [Why]: Thundering herd behavior and unnecessary failures when the network flakes.
- [Fix]: Add retry on curl exit codes with same backoff. Add random jitter (+/-20%). Record curl_exit_code in reviewer_meta.

---

## Perplexity (sonar-reasoning-pro)

- [F1]
- [Severity]: CRITICAL
- [Finding]: Step 4 describes response extraction using jq as "preferred" but provides Python fallbacks without enforcing which tool is available. If jq is not installed, extraction fails silently or crashes.
- [Why]: Response extraction is a hard dependency. Silent failure leaves the review incomplete with no clear signal.
- [Fix]: Add a pre-flight check for jq availability. If missing, use Python fallback explicitly. Document as system dependency.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Hard denylist regex patterns lack flags and anchoring rules. `sk-[a-zA-Z0-9]{20,}` matches partial strings. `password\s*=` triggers on comments.
- [Why]: False positives block legitimate reviews; false negatives leak secrets.
- [Fix]: Anchor patterns, require word boundaries. Specify the actual check for context-sensitivity (fenced code block detection + marker search) as code, not prose.

- [F3]
- [Severity]: CRITICAL
- [Finding]: Retry logic described in prose but not implemented in the shown bash. The curl command shown is a single attempt with no loop, backoff, or retry counter.
- [Why]: Without retry logic actually coded, transient API failures cause unnecessary review failures.
- [Fix]: Replace single curl invocation with actual bash loop implementing the retry/backoff logic.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: `git diff main -- {artifact_path}` assumes main branch without fallback.
- [Why]: Diff mode fails silently in repos using master, develop, or other default branches.
- [Fix]: Detect default branch via `git symbolic-ref refs/remotes/origin/HEAD` with fallback.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Large-diff escape hatch (800 lines) described in prose but line-counting logic not shown.
- [Why]: Without enforcement, massive diffs get sent, incurring API costs and poor review quality.
- [Fix]: Add explicit bash line-counting before prompt construction.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: .env sourcing could fail silently if the file has invalid bash syntax.
- [Why]: Skill proceeds with empty API keys, fails cryptically at curl stage.
- [Fix]: Validate .env with `bash -n` before sourcing.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: prompt_addendum referenced in template but no extraction logic shown for reading it from config.
- [Why]: Addendum ignored silently if not extracted, or template placeholder causes rendering errors.
- [Fix]: Define config structure for prompt_addendum and provide extraction commands.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Synthesis normalization assumes reviewers will format findings as specified. Different LLMs use different severity labels without validation.
- [Why]: Non-standard findings break the consensus/unique/contradiction logic.
- [Fix]: Add post-extraction reformatting step that normalizes findings and logs inferences.

- [F9]
- [Severity]: MINOR
- [Finding]: Temp file cleanup timing not specified; files accumulate.
- [Why]: Sensitive payloads linger in /tmp.
- [Fix]: Explicit cleanup after all reviewers complete.

- [F10]
- [Severity]: MINOR
- [Finding]: No validation that artifact_hash in prior review matches current artifact before switching to diff mode.
- [Why]: Stale prior reviews produce misleading diffs.
- [Fix]: Check artifact_hash consistency before activating diff mode.

- [F11]
- [Severity]: STRENGTH
- [Finding]: Injection resistance wrapper well-designed. Placed before artifact content, provides defense-in-depth against prompt injection.

- [F12]
- [Severity]: STRENGTH
- [Finding]: Reviewer namespacing (OAI-F1, GEM-F1, PPLX-F1) prevents confusion and enables traceability.

- [F13]
- [Severity]: STRENGTH
- [Finding]: Config snapshot with hashes enables reproducibility and auditability.

**Dependency Verification (Perplexity web-grounded):**

| Dependency | Status | Notes |
|---|---|---|
| curl | Verified | POSIX standard, available on all Unix/Linux |
| jq | Available but optional | Not guaranteed in minimal environments |
| Python 3 (json module) | Verified | Standard library |
| git | Required for diff mode | No fallback provided |
| OpenAI Chat Completions API | Verified current | GPT-5.2 with max_completion_tokens confirmed |
| Google Gemini generateContent | Verified current | Endpoint and generationConfig structure current Feb 2026 |
| Perplexity Chat Completions | Verified current | OpenAI-compatible format, uses max_tokens |

---

## Synthesis

### Consensus Findings

Issues flagged by both reviewers — highest signal:

1. **Safety gate regex patterns need precision** (OAI-F3 + PPLX-F2): Both flag that the denylist patterns are underspecified — no anchoring, no word boundaries, and the context-sensitivity downgrade logic is described in prose but not as implementable code. The risk cuts both ways: too loose misses real secrets, too strict trains users to override.

2. **Git diff assumes `main` branch** (OAI-F6 + PPLX-F4): Both identify that `git diff main` has no fallback. OAI goes further and flags missing commit SHA storage in frontmatter for reliable diff baselines.

3. **Config extraction is underspecified** (OAI-F12 + PPLX-F7): Both flag that "deterministic extraction (grep/sed)" is stated as the method but no actual extraction logic is defined. OAI calls it CRITICAL; PPLX flags it via the prompt_addendum extraction gap.

4. **Retry logic exists in prose but not in code** (PPLX-F3): The skill describes retry behavior but shows only single curl invocations. Claude implements the retry loop at execution time, but the skill should either show it or explicitly state it's Claude's responsibility to implement the loop.

5. **Response extraction fragility** (OAI-F8 + PPLX-F1): Both flag that extraction assumes specific JSON shapes and that jq availability isn't checked. PPLX recommends a pre-flight check; OAI recommends configurable extractors.

6. **Temp file cleanup** (OAI-F10 + PPLX-F9): Both note cleanup is incomplete. Low severity but consensus.

### Unique Findings

**OpenAI only:**
- **OAI-F1** (Responses API): Claims Chat Completions may be wrong for GPT-5.2. **Likely noise** — contradicted by both the dry run (which succeeded with Chat Completions) and Perplexity's dependency verification (confirmed current). OpenAI is pushing the Responses API but Chat Completions works fine for GPT-5.2.
- **OAI-F15** (Decline rubric): Suggests a structured rubric for the "Considered and Declined" section. **Genuine insight** — adds transparency to Claude's filtering.
- **OAI-F16** (Override keyword overloading): Notes that "OVERRIDE" is used for both safety gate and round cap reset. **Genuine catch** — could cause confusion.
- **OAI-F17** (Raw response redaction on override): If safety gate is overridden, raw responses may echo secrets back. **Genuine concern** for future use.
- **OAI-F20** (Jitter + curl exit codes): Retry doesn't handle network-level failures (curl exit codes) or add jitter. **Genuine improvement** for robustness.

**Perplexity only:**
- **PPLX-F6** (.env validation): Suggests `bash -n` check before sourcing to catch syntax errors. **Genuine insight** — silent sourcing failures are hard to debug.
- **PPLX-F8** (Severity normalization enforcement): Suggests a post-extraction reformatting step for non-standard findings. **Genuine insight** — Claude does this in the synthesis, but making it explicit is better.
- **PPLX-F10** (Artifact hash consistency check): Verify prior review's artifact_hash before diff mode. **Good catch** — prevents stale comparisons.
- **PPLX Dependency verification table**: Confirmed all named APIs are current. Verified GPT-5.2 uses max_completion_tokens. **High-value unique contribution** from Perplexity's web-grounded search.

### Contradictions

1. **Chat Completions vs Responses API** (OAI-F1 vs PPLX dependency verification): OpenAI claims Chat Completions "may fail or silently degrade" for GPT-5.2. Perplexity verified it as "current." The dry run confirmed it works. **Verdict: OpenAI is over-indexing on their own API migration narrative. Chat Completions works. Monitor but don't migrate preemptively.**

2. **Retry implementation location** (OAI vs PPLX): Both flag retry logic, but they have different expectations. PPLX wants actual bash loops in the skill file. The skill is a *procedure for Claude to follow*, not a standalone script — Claude implements the loops at execution time. The prose description is sufficient for a Claude skill; it would only be insufficient for Option B (helper script). **Note for skill conventions: clarify that procedure code blocks are templates/patterns, not complete scripts.**

### Action Items

**Must-fix:**

- **A1** (OAI-F6 + PPLX-F4): **Fix diff mode branch detection.** Replace hardcoded `git diff main` with default branch detection: `git symbolic-ref refs/remotes/origin/HEAD | sed 's@.*/@@'` with fallback to `main`. Also add `base_ref` to review note frontmatter so diff baselines are explicit and reproducible.

- **A2** (OAI-F3 + PPLX-F2): **Tighten safety gate denylist patterns.** Add word boundary anchoring where appropriate. Refine the context-sensitivity downgrade: require the matched value itself to contain placeholder markers (`...`, `YOUR_`, `REPLACE`, `example`), not just nearby text. This is a spec-level change — update the spec, then the skill.

**Should-fix:**

- **A3** (OAI-F12 + PPLX-F7): **Document config extraction approach.** The skill relies on Claude reading the config file (not grep/sed). Clarify in the skill that Claude reads and interprets the YAML frontmatter directly — this is Option A (pure skill, no scripts). Remove the misleading "deterministic extraction (grep/sed)" language.

- **A4** (PPLX-F1 + OAI-F8): **Add jq pre-flight check.** Check jq availability at skill start. If missing, use Python for all JSON extraction. Since Python is already required for payload construction, this simplifies the dependency story.

- **A5** (PPLX-F6): **Validate .env before sourcing.** Add `bash -n ~/.config/crumb/.env` check to catch syntax errors early.

- **A6** (OAI-F15): **Add decline rubric to synthesis.** Decline if: based on false assumption, conflicts with stated design constraints, or adds complexity without proportional benefit. Tag each decline with reason category.

- **A7** (OAI-F16): **Disambiguate override keywords.** Use `OVERRIDE` for safety gate only. Use different phrasing for round cap reset (e.g., "start new cycle" rather than "explicit override").

**Defer:**

- **A8** (OAI-F1): Responses API migration. Contradicted by evidence. Monitor for deprecation signals.
- **A9** (OAI-F20): Jitter and curl exit code retry. Good robustness improvement, low urgency for a single-user skill.
- **A10** (OAI-F10 + PPLX-F9): Temp file uniqueness (mktemp). Low risk in single-user Claude Code context.
- **A11** (OAI-F17): Raw response redaction on safety override. Relevant if the skill reviews customer data. Current use case is specs and skills.
- **A12** (OAI-F11): Parallel execution. Spec deliberately chose sequential. ~2 min total wall time is acceptable.
- **A13** (PPLX-F10): Artifact hash consistency check before diff mode. Good defense-in-depth, but diff mode is a v2 concern — no prior reviews exist yet for most artifacts.

### Considered and Declined

- **OAI-F2** (token_budget rename, per-reviewer token_param in config): The current approach works — the skill maps the config's `max_tokens` to the correct per-provider parameter name at execution time. The A1 fix from the dry run already handles this. Adding `token_param` to the config adds complexity for a problem that's solved. **Reason: already addressed by implementation.**

- **OAI-F4** (line number reporting in safety gate): Claude computes line numbers contextually when scanning. The safety gate demonstrated this in both the dry run and this review. Specifying it further adds procedure bulk without benefit. **Reason: works as implemented.**

- **OAI-F5** (customer domain denylist privacy): The denylist file is local to the vault and never sent in prompts — it's used for local pattern matching only. The concern about "leaking the denylist into prompts" is based on a misreading. **Reason: based on false assumption.**

- **OAI-F9** (curl stderr capture, --fail-with-body): The current pattern captures HTTP status and response body. Stderr is visible in Claude Code's bash output. Adding explicit stderr redirection adds complexity. **Reason: marginal benefit in Claude Code context.**

- **OAI-F13** (frontmatter fields for inline artifacts): The procedure already says `artifact: "inline"` and `project: null` when there's no file. This is specified. **Reason: already addressed.**

- **PPLX-F3** (retry loop as actual bash): The skill file is a procedure for Claude, not a standalone script. Claude implements retry logic at execution time based on the prose description. The spec chose Option A (pure skill) specifically to avoid maintaining scripts. **Reason: conflicts with design decision (Option A).**

- **PPLX-F5** (large-diff line counting logic): Same reasoning as PPLX-F3. Claude counts lines and makes the mode decision. The prose description is sufficient. **Reason: conflicts with design decision (Option A).**

- **OAI-F7** (deterministic escape hatch detection): Over-specifying the heuristic for "foundational sections" risks brittleness (hardcoded heading names). Claude's judgment on whether a diff touches foundational content is more adaptive. **Reason: adds rigidity without proportional benefit.**
