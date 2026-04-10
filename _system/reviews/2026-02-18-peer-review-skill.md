---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: .claude/skills/peer-review/SKILL.md
artifact_type: skill
artifact_hash: 8aad357c
prompt_hash: 471f3a71
project: crumb
domain: software
skill_origin: peer-review
created: 2026-02-18
updated: 2026-02-18
reviewers:
  - openai/gpt-5.2
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
    gate itself — not actual secrets). Patterns like sk-proj- and -----BEGIN PRIVATE KEY-----
    appear as documentation of what to scan for. Downgraded as false positive — the matched
    values are regex patterns in a bullet list, clearly not credentials.
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 43548
    attempts: 2
    error: "Attempt 1 failed (400): max_tokens not supported, use max_completion_tokens. Fixed and retried."
    raw_json: _system/reviews/raw/2026-02-18-peer-review-skill-openai.json
tags:
  - review
  - peer-review
---

# Peer Review: peer-review skill (SKILL.md)

**Artifact:** .claude/skills/peer-review/SKILL.md
**Mode:** full
**Reviewed:** 2026-02-18
**Reviewers:** OpenAI GPT-5.2 (single-reviewer dry run)
**Review prompt:** Structured review of the peer-review skill file. Focus areas: procedure correctness, error handling completeness, safety gate soundness, curl/API pattern correctness.

**Dry run note:** This is the validation run for the peer-review skill itself. Single reviewer (OpenAI) to validate the pipeline before wiring up all three. The first attempt returned HTTP 400 — GPT-5.2 requires `max_completion_tokens` instead of `max_tokens`. Fixed and retried successfully.

---

## OpenAI (gpt-5.2)

- [F1]
- [Severity]: CRITICAL
- [Finding]: The "context-sensitivity rule" for secrets can incorrectly downgrade real secrets to a soft warning just because they appear in a fenced code block with words like "example/sample/template" nearby.
- [Why]: Attackers (or careless authors) can wrap real credentials in an "example" code block and bypass the hard block, leading to exfiltration of live keys to external APIs.
- [Fix]: Only downgrade if the matched value itself is clearly non-real (e.g., contains `YOUR_`, `your-key-here`, `REDACTED`, all `x`, obviously invalid length/checksum) or matches an explicit "known fake" pattern. Otherwise keep as hard block. Consider an allowlist of *safe placeholder forms* rather than keyword proximity.

- [F2]
- [Severity]: CRITICAL
- [Finding]: The procedure prints expected key names and suggests `.env` handling, but the Step 0 shell snippet risks accidentally echoing or exposing environment values later in logs/process listings if not careful, and doesn't guarantee `.env` file permissions.
- [Why]: Peer review is explicitly about sending data externally; mishandling local secrets is high risk. Also, sourcing `.env` in a shell can execute arbitrary code if the file is compromised.
- [Fix]: Require `.env` to be owned by the user and mode `0600` before sourcing. Prefer parsing `.env` as key/value (no execution) rather than `source` (e.g., Python dotenv-style minimal parser). Avoid printing anything that might include values; only print whether keys are present.

- [F3]
- [Severity]: CRITICAL
- [Finding]: Diff-mode command `git diff main -- {artifact_path}` assumes branch `main` exists and that the comparison baseline is correct; it may produce empty/incorrect diffs on repos using `master`, detached HEAD, or no upstream.
- [Why]: Wrong diffs lead to reviewers missing important changes or reviewing irrelevant hunks, undermining trust in the workflow.
- [Fix]: Detect default branch (`git symbolic-ref refs/remotes/origin/HEAD` or fallback to `main/master`) and/or compare against the last reviewed commit hash stored in prior review frontmatter. Make baseline explicit in metadata.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Step 4 says "Read config ... using deterministic extraction (grep/sed for key fields)" but doesn't define an exact schema or robust parsing rules; markdown configs are brittle with grep.
- [Why]: Small formatting changes can silently break extraction (wrong models, endpoints, timeouts), causing failures or unintended API calls.
- [Fix]: Move config to a strict format (YAML/TOML/JSON) or enforce a fenced code block in the markdown with machine-parseable YAML. Validate required fields and echo a "config_snapshot" summary before sending.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Curl response handling is underspecified: you write response to a file and also use `-w "%{http_code}|%{time_total}"`, but you must capture `-w` output separately; otherwise you can't reliably record status/latency and may mingle outputs depending on shell usage.
- [Why]: Without reliable status/latency capture, retry logic and reviewer_meta become inaccurate; you may treat failures as successes or vice versa.
- [Fix]: Capture `-w` to a variable or separate file, e.g. `metrics=$(curl ... -o resp.json -w "%{http_code}|%{time_total}")` then parse. Also include `--fail-with-body` (where available) and record stderr via `2>...` for debugging.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Retry/backoff spec is internally inconsistent: you list default backoff `[2, 5]` with max attempts 3, but do not define the 3rd wait (between attempts 2-3) clearly; also no jitter.
- [Why]: Ambiguity causes implementation drift; lacking jitter can amplify rate-limit collisions across repeated runs.
- [Fix]: Define `backoff_seconds = [2, 5, 10]` (length = max_attempts-1) with optional jitter (e.g., +/-20%). Spell out how to choose when arrays are shorter/longer than needed.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: The OpenAI/Perplexity payload uses Chat Completions, but current OpenAI guidance increasingly favors the Responses API; also Perplexity's OpenAI-compat surface may differ in fields or limits.
- [Why]: API drift can break the skill; "will work correctly" depends on exact endpoints/models. A brittle integration increases maintenance.
- [Fix]: In config, explicitly store `api_style: chat_completions|responses` per provider and generate payload accordingly. Add a compatibility note and a periodic smoke test.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Gemini endpoint example hardcodes `gemini-2.5-pro:generateContent`; model/versioning and URL structure may change, and some deployments require region/project routing rather than API-key URL.
- [Why]: Breaks in Gemini calls reduce triangulation; hardcoding makes the config less useful.
- [Fix]: Put full Gemini URL template and model name in config. Support both API-key and ADC/OAuth modes if relevant, or clearly constrain to API-key only.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: "Store raw JSON response" is good, but the raw responses may contain the full artifact content (some providers echo prompts in metadata) and can include sensitive material you intended not to persist broadly in the vault.
- [Why]: You might avoid sending secrets, but still store sensitive internal docs as raw API transcripts; vault sync/backups could leak them.
- [Fix]: Add an option to redact or omit prompt echo fields if present, or store raw responses outside the synced vault. At minimum, document that raw storage contains reviewed content and should be protected.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Safety gate patterns are helpful but incomplete for common secrets (GitHub tokens `ghp_`, `github_pat_`, Slack `xoxb-`, GCP service account JSON, Stripe `rk_live_`, `sk_live_` beyond `sk-`, Cloudflare tokens, etc.).
- [Why]: Realistic leakage risk remains high; users may assume "safety gate" is comprehensive when it isn't.
- [Fix]: Expand denylist with a broader library of token regexes and/or allow user-extensible patterns in `docs/peer-review-denylist.md` (not just customer domains). Clearly label it as "best-effort" and keep it updated.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: The "Generic secrets: password\s*= ... token\s*=" rule may miss YAML/JSON formats (`password:`), quoted values, env var exports, or whitespace/newlines; may also false-positive in prose.
- [Why]: Either you miss secrets (bad) or block too aggressively (frustrating), causing users to override and defeat the gate.
- [Fix]: Add structured detectors: `password\s*[:=]\s*["']?[^"'\s]+`, `export\s+(\w*KEY|TOKEN|SECRET)=...`, YAML `key: value`. Also show a short surrounding snippet with masking.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: "Show the user what matched and where (line number...)" is required, but the procedure doesn't define how line numbers are computed for inline artifacts vs file reads vs diffs with context.
- [Why]: Without accurate locations, remediation is slow; users may override rather than fix.
- [Fix]: Specify an implementation: for file artifacts, compute line numbers from the file content; for diffs, reference hunk headers + relative line; for inline text, count lines in the assembled artifact block.

- [F13]
- [Severity]: MINOR
- [Finding]: Temp file naming is not unique per run (`/tmp/peer-review-payload-{reviewer}.json`, `/tmp/peer-review-prompt.txt`), which can collide across concurrent runs or if a previous run crashed.
- [Why]: Collisions can cause wrong payloads/responses to be attributed to the wrong reviewer or leak data between runs.
- [Fix]: Include a run ID (timestamp+PID) in temp filenames, or use `mktemp`. Ensure cleanup in a trap (`trap 'rm -f ...' EXIT`).

- [F14]
- [Severity]: MINOR
- [Finding]: "Clean up temp payload file" mentions payload but not prompt file and response temp files in `/tmp/`.
- [Why]: Leaving prompts/responses in `/tmp` can leak sensitive content to other local users (depending on system) and clutters disk.
- [Fix]: Clean up *all* temp artifacts (prompt, payloads, responses, stderr logs) or store them under a run-specific temp dir removed at end.

- [F15]
- [Severity]: MINOR
- [Finding]: The frontmatter requires `reviewers: - {provider/model for each reviewer that responded}` but doesn't include reviewers that were attempted and failed, except via reviewer_meta.
- [Why]: It's useful to know coverage at a glance; missing reviewers can mislead.
- [Fix]: Add `reviewers_attempted` and `reviewers_succeeded` lists, or include failure entries in `reviewers` with status.

- [F16]
- [Severity]: MINOR
- [Finding]: Extraction commands assume `jq` exists ("jq preferred") but the allowed-tools list doesn't include dependency installation and the procedure doesn't mandate jq presence.
- [Why]: Many environments won't have jq; relying on it without a clear fallback path can break runs.
- [Fix]: Make Python the primary extractor (since you already require Python for payload writing), and only use jq if detected. Record which extractor was used.

- [F17]
- [Severity]: STRENGTH
- [Finding]: Strong overall structure: mandatory safety gate, injection-resistance wrapper, structured findings format, and a synthesis step focused on decision/actionability.
- [Why]: This is exactly the right shape for cross-model review: it reduces prompt injection risk, encourages comparable outputs, and produces an operator-friendly result.
- [Fix]: None.

- [F18]
- [Severity]: STRENGTH
- [Finding]: Good operational resilience: sequential calls, retries on sensible status codes, "never fail the entire review because one reviewer is down," and raw response preservation for audit/debug.
- [Why]: Cross-LLM workflows often fail in practice due to transient API issues; this design anticipates that.
- [Fix]: None (consider adding jitter and better metrics capture per F5/F6).

---

## Synthesis

*Single-reviewer dry run — no cross-model consensus/contradiction analysis possible. Findings evaluated on merit.*

### Action Items

**Must-fix (blocking — fix before production use):**

- **A1** (OAI-F dry run finding): OpenAI GPT-5.2 requires `max_completion_tokens` instead of `max_tokens`. The skill file, config file, and spec all use `max_tokens`. Update the payload construction in the skill to use `max_completion_tokens` for OpenAI. Check if Perplexity also requires this. Gemini uses `maxOutputTokens` (different API, already correct).

- **A2** (OAI-F3): Diff mode hardcodes `git diff main`. Detect default branch or compare against prior review commit hash. This vault does use `main`, so not immediately broken, but fragile.

**Should-fix (address before regular use):**

- **A3** (OAI-F10, F11): Expand safety gate denylist patterns. Add `ghp_`, `github_pat_`, `xoxb-`, `sk_live_`, `rk_live_` at minimum. Improve generic secret matching to cover YAML `:` delimiter. This is a spec-level change — update the skill spec first, then the skill file.

- **A4** (OAI-F6): Backoff array `[2, 5]` has 2 entries for 3 max attempts. Add a third entry or document that the last value is reused. Config-level fix.

- **A5** (OAI-F16): Python is already required for payload construction. Make it the primary extractor, fall back to jq as a convenience. Simplifies the dependency story.

**Defer (revisit when evidence warrants):**

- **A6** (OAI-F1): Safety gate downgrade bypass risk. The spec designed this tradeoff deliberately (prevent false-positive fatigue on docs that discuss keys). Valid concern but the current vault's primary use case is reviewing documentation. Revisit if the skill reviews code with real credentials.

- **A7** (OAI-F2): `.env` file permissions check and sourcing risk. Valid defense-in-depth, but this is a single-user macOS system. The `.env` file is outside the vault and not synced. Add a `chmod 600` recommendation to the spec, defer the Python parser.

- **A8** (OAI-F7, F8): API style abstraction and Gemini URL templating. Over-engineering for v1. The current curl patterns work. Revisit when an API actually breaks.

- **A9** (OAI-F9): Raw response may contain echoed prompts with sensitive content. Valid concern for future. Current usage reviews specs and skills (not customer data). Add a note to the spec about raw storage containing reviewed content.

- **A10** (OAI-F13, F14): Temp file uniqueness and full cleanup. Low risk in single-user Claude Code context. Good practice, low urgency.

### Considered and Declined

- **OAI-F4** (config parsing brittleness): The spec deliberately chose markdown-wrapped YAML with grep/sed extraction and defined strict format constraints. The config format is intentionally simple. This was an explicit design decision (see spec §3.3 format constraints). The skill actually uses Python for JSON construction, so config parsing brittleness is managed at the Claude interpretation layer, not at a shell parsing layer.

- **OAI-F5** (curl `-w` output handling): The dry run demonstrated that `metrics=$(curl ... -w ...)` works correctly for capturing HTTP code and latency. The pattern shown in the skill file is functional. No fix needed.

- **OAI-F12** (line number computation for inline artifacts): Valid nit but Claude computes line numbers contextually when scanning. The safety gate implementation showed this working in the dry run. Not worth specifying further.

- **OAI-F15** (reviewers_attempted vs reviewers_succeeded): reviewer_meta already captures this information with http_status per reviewer. Adding more frontmatter fields adds complexity without new information.
