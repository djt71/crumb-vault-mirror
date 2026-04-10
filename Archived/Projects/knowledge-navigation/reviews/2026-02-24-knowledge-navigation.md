---
type: review
project: knowledge-navigation
domain: learning
status: active
created: 2026-02-24
updated: 2026-02-24
review_mode: full
review_round: 1
artifact_path: Projects/knowledge-navigation
artifact_type: architecture
safety_gate: pass
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
  - perplexity/sonar-reasoning-pro (manual)
reviewer_meta:
  openai:
    model: gpt-5.2
    prompt_tokens: 7761
    completion_tokens: 2323
    system_fingerprint: null
    elapsed_seconds: 43.5
    verdict: Needs significant revision
  google:
    model: gemini-3-pro-preview
    prompt_tokens: 8400
    completion_tokens: 1164
    system_fingerprint: null
    elapsed_seconds: 39.5
    verdict: Needs significant revision
  deepseek:
    model: deepseek-reasoner
    prompt_tokens: 8123
    completion_tokens: 5725
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    elapsed_seconds: 112.8
    verdict: Needs significant revision
  grok:
    model: grok-4-1-fast-reasoning
    prompt_tokens: 7816
    completion_tokens: 1320
    system_fingerprint: fp_eddf72ed7d
    elapsed_seconds: null
    verdict: Needs significant revision
  perplexity:
    model: sonar-reasoning-pro
    dispatch: manual
    verdict: Needs significant revision
---

# Peer Review: knowledge-navigation (2026-02-24)

**Artifact:** Projects/knowledge-navigation (multi-file project review)
**Mode:** full | **Round:** 1
**Reviewers:** 5/5 responded (openai, google, deepseek, grok, perplexity-manual)
**Consensus verdict:** Needs significant revision (5/5 unanimous)

---

## OpenAI (gpt-5.2)

**[F1]** (CRITICAL)
**Finding:** Check 17's "global filename uniqueness" only checks MOC files, not all files in `Domains/*/`, so it doesn't actually enforce the stated constraint.
**Why:** The design constraint says "MOC filenames must be globally unique across all `Domains/*/` directories." The implementation enforces uniqueness only among files whose `type` is `moc-orientation|moc-operational`. If a non-MOC note shares a filename with a MOC (or another note), Obsidian shortest-path resolution can still become ambiguous and break the "topics as bare filename" strategy.
**Fix:** Either (a) enforce global uniqueness for *all* markdown basenames under `Domains/*/` (recommended given shortest-path resolution), or (b) explicitly narrow the constraint text/spec to "MOC filenames unique among MOCs only" and add a separate check preventing any non-MOC from sharing a basename with a MOC.

**[F2]** (CRITICAL)
**Finding:** Check 18 uses bash arrays (`matches=()`, `matches+=`) which are not bash 3.2-safe in all macOS environments as written (and can be brittle under `set -u`/older shells).
**Why:** While bash 3.2 supports indexed arrays, many "bash 3.2 compatible" codebases avoid arrays because they interact poorly with strict modes and portability expectations; your own constraints explicitly call out "no associative arrays," but the project framing implies conservative compatibility. This is a risk if the script is run under `/bin/sh` accidentally, or with stricter shell options.
**Fix:** Remove arrays entirely: count matches via `find ... -print` piped to `wc -l`, and capture the single match via `head -1`. Example: `match=$(find ... -name "${topic_entry}.md" ... | head -1)` and `count=$(find ... | wc -l | tr -d ' ')`.

**[F3]** (SIGNIFICANT)
**Finding:** `extract_field()` only supports single-line scalar fields and will not correctly parse common YAML patterns (quoted values, inline arrays, multi-line blocks).
**Why:** Several checks depend on `type:` and `review_basis:` being extracted reliably. If frontmatter evolves (e.g., `type: "moc-orientation"` or additional spacing), `grep "^${field}:"` may fail or mis-extract, causing false negatives/positives.
**Fix:** Harden parsing: use a small YAML-aware approach (still bash-friendly) such as `python -c` (if allowed) or stricter awk that tolerates whitespace and quotes: `awk -F: -v f="$field" '$1==f{ sub(/^[^:]*:[[:space:]]*/, "", $0); gsub(/^"|"$/, "", $0); print; exit }'`.

**[F4]** (SIGNIFICANT)
**Finding:** Check 18's topics list extraction can mis-parse if another YAML key appears indented (or if topics entries include comments/quotes).
**Why:** The awk terminator `in_topics && /^[a-zA-Z]/ { exit }` assumes the next top-level key starts at column 1 with a letter. YAML keys can start with `_`, digits, or be indented unexpectedly; values can be quoted; list items can include inline comments. This can cause the parser to "run on" into subsequent fields or stop too early.
**Fix:** Terminate on the next non-indented line that matches `^[^[:space:]]` and contains `:` (a top-level key), and strip inline comments from list items. Also trim surrounding quotes.

**[F5]** (SIGNIFICANT)
**Finding:** The "topics field uses bare MOC filenames that resolve to `Domains/*/{name}.md`" is inconsistent with the actual MOC file locations shown (`Domains/Learning/` mentioned, but checks search all `Domains/*/`).
**Why:** The narrative deliverable says MOCs are in `Domains/Learning/`, but the checks resolve to any `Domains/*/`. That's not inherently wrong, but it's a spec/implementation mismatch that will confuse maintainers and can lead to unexpected cross-domain topic resolution.
**Fix:** Align documentation with implementation: either (a) update the spec to "resolves to `Domains/**/{name}.md`" (any domain), or (b) restrict resolution to `Domains/Learning/` if that's the intended invariant.

**[F6]** (SIGNIFICANT)
**Finding:** Wikilink strategy is only partially addressed: MOCs include path-prefixed links (e.g., `[[Projects/.../specification|...]]`) but the system doesn't define a consistent rule for when to use bare vs path links.
**Why:** With shortest-path resolution, bare links are fragile once names collide; path links are robust but verbose. Without a documented policy, contributors will mix styles, and navigation will degrade as the vault grows.
**Fix:** Add a clear convention: "Use bare links only for globally-unique basenames (enforced by check X); otherwise use path-prefixed links." Consider adding a check that flags ambiguous bare links in MOCs (at least within `Domains/*`).

**[F7]** (SIGNIFICANT)
**Finding:** Check 21 "Synthesis density" will warn on newly created orientation MOCs with many entries (e.g., `moc-history` has far >5) even though the template explicitly says synthesis is populated later.
**Why:** This creates systematic warning noise and trains users to ignore warnings, reducing the value of the validation suite. It also conflicts with the comment "Populated after Core reaches >3 notes and debt score triggers synthesis pass."
**Fix:** Gate the warning on an explicit frontmatter flag (e.g., `synthesis_status: deferred`) or on `notes_at_review`/`created` age, or raise the threshold (e.g., >25 entries) before warning.

**[F8]** (SIGNIFICANT)
**Finding:** Source index schema is not validated by vault-check, despite being a new type with required structure.
**Why:** You've added `type: source-index` and a fairly specific schema (source block, topics required, body sections). Without checks, drift will occur and the "per-source landing page" concept will become inconsistent.
**Fix:** Add a new check (or extend an existing one) to validate: `type: source-index` requires `source.source_id`, `source.title`, `source.author`, `source.source_type`, and `topics` present; optionally validate filename pattern `*-index.md`.

**[F9]** (MINOR)
**Finding:** `notes_at_review` values appear inconsistent with the described counts (e.g., `moc-history` says `notes_at_review: 48` but delta text says "Initial population: 45 biographical profiles + ... roster/synthesis/history").
**Why:** Minor inconsistency reduces trust in metadata and makes automated "debt score"/review planning less reliable.
**Fix:** Define what counts as a "note" for `notes_at_review` (Core entries only? total linked notes? includes cross-cutting notes?) and update the numbers accordingly.

**[F10]** (MINOR)
**Finding:** `moc-philosophy` "Tensions" says "Currently only 2 notes" but `notes_at_review: 1` and Core lists only one link.
**Why:** Small internal contradiction; can confuse reviewers/users about what exists.
**Fix:** Reconcile: either add the second note/link, or change the text to "1 note".

**[F11]** (SIGNIFICANT)
**Finding:** Check 19's kb-tag detection (`grep "^[[:space:]]*-[[:space:]]*kb/"`) can produce false positives/negatives depending on YAML formatting and tag style.
**Why:** If tags are written inline (`tags: [kb/history]`), or if tags include `#kb/history` (with hash), or if there are other lists containing `kb/`, the check may miss or misclassify notes, undermining enforcement of `topics`.
**Fix:** Standardize tag format in conventions (explicitly "tags is a YAML list, entries without #"), and/or make the detector more robust (handle inline arrays and optional leading `#`).

**[F12]** (SIGNIFICANT)
**Finding:** The system relies on "MOC filenames globally unique" but does not address collisions for non-MOC notes that are linked from MOCs using bare links (e.g., `[[albert-einstein]]`).
**Why:** Even if MOC filenames are unique, the majority of links in MOCs are to non-MOC notes. As the vault grows, name collisions among biographies/notes are likely, breaking navigation under shortest-path resolution.
**Fix:** Introduce a uniqueness policy for *all* KB note basenames within a domain (or globally), or adopt a naming scheme (e.g., `person-albert-einstein`, `film-orson-welles`) and/or enforce path-prefixed links for non-unique names.

**[F13]** (STRENGTH)
**Finding:** The MOC frontmatter schema is consistent across the four MOCs and aligns with the stated taxonomy (`moc-orientation` vs `moc-operational`).
**Why:** Clear separation of orientation vs operational MOCs supports different content expectations (synthesis vs procedures) and enables targeted validation (e.g., check 21 exempting operational MOCs).
**Fix:** Keep this structure; consider adding a short "intended use" line in each MOC frontmatter or template for even clearer differentiation.

**[F14]** (STRENGTH)
**Finding:** Topics resolution design (bare filename + validation for existence and uniqueness) is a solid approach for maintaining referential integrity in an Obsidian vault.
**Why:** It creates a mechanical guarantee that `topics` entries point to real MOCs and prevents silent drift/typos -- key for scaling navigation.
**Fix:** Extend the same integrity approach to other new primitives (source-index validation; optional link ambiguity checks).

**[F15]** (UNVERIFIABLE CLAIM: SIGNIFICANT)
**Finding:** UNVERIFIABLE CLAIM: "Backfill of `topics` field on 65+ existing files" and "3 deferred files exist without MOCs."
**Why:** These are project-state assertions not verifiable from the provided artifacts; if inaccurate, they affect whether check 19 should remain WARNING and whether the system is actually consistent in practice.
**Fix:** Provide a short report output (counts + list of exceptions) or include a sample of backfilled notes / a generated summary from vault-check to substantiate.

**Verdict:** Needs significant revision

---

## Google (gemini-3-pro-preview)

Here are the findings from the peer review of the knowledge-navigation project artifacts.

**[F1]** (CRITICAL)
**Finding:** Check 18 (`check_topics_resolution`) has a severe performance scalability issue ($O(N)$ disk operations).
**Why:** The script executes `find "$VAULT_ROOT/Domains" ...` inside the loop for *every* topic entry in *every* file. As the vault grows to hundreds of files, this will spawn hundreds or thousands of sub-processes, causing the script to run extremely slowly.
**Fix:** Refactor to run `find "$VAULT_ROOT/Domains"` **once** at the start of the script to build a cache (e.g., a newline-delimited string variable of `filename|path` pairs). Inside the loop, search this variable using string manipulation or `grep` (memory operation) instead of disk I/O.

**[F2]** (SIGNIFICANT)
**Finding:** Check 17 (`check_moc_schema`) uses unsafe regex for filename uniqueness, treating dots as wildcards.
**Why:** The line `grep "^${bn}|"` treats the `.` in `.md` as a regex wildcard. A file named `moc-test.md` would incorrectly match a previous entry like `moc-testxmd`, potentially masking duplicates or flagging false positives.
**Fix:** Use `grep -F` (fixed string) if possible, or escape the dot in the variable before using it in the regex: `bn_escaped="${bn//./\\.}"`.

**[F3]** (SIGNIFICANT)
**Finding:** Check 19 (`check_topics_requirement`) fails to detect `kb/` tags if formatted as inline YAML arrays.
**Why:** The check uses `grep -q "^[[:space:]]*-[[:space:]]*kb/"`. Valid YAML frontmatter like `tags: [kb/history, other]` will be ignored, allowing files to bypass the topic requirement check.
**Fix:** Update the check to handle both list format and inline array format, or enforce a specific YAML list style in `file-conventions.md`. Given the Bash constraint, enforcing the list format (`- tag`) via the linter is the easier path, but the check should ideally be robust.

**[F4]** (SIGNIFICANT)
**Finding:** Topic resolution (Check 18) does not verify global uniqueness, risking ambiguous wikilink resolution.
**Why:** The check only verifies that the topic file exists in `Domains/`. If a file with the same name exists in `Projects/`, Obsidian's shortest-path resolution becomes ambiguous (or dependent on undefined behavior), but the script will pass. The `topics` field relies on bare filenames, so global uniqueness is required for deterministic linking.
**Fix:** The "cache" suggested in F1 should include *all* markdown files in the vault, or a separate check must ensure that MOC filenames in `Domains/` do not collide with filenames in `Projects/` or `Sources/`.

**[F5]** (MINOR)
**Finding:** Artifact 3 (`moc-crumb-architecture.md`) uses path-prefixed wikilinks, contradicting the "shortest-path" design constraint.
**Why:** The artifact contains `[[Projects/feed-intel-framework/...]]`. While Obsidian handles this, the design constraints explicitly state "shortest-path wikilink resolution (not path-prefixed)". Mixing styles creates inconsistency.
**Fix:** Remove the path prefixes in the MOC body (e.g., `[[specification|Feed Intelligence Framework Spec]]`) provided the filenames are unique, or update the design constraints to allow path prefixes for disambiguation.

**[F6]** (MINOR)
**Finding:** Check 21 (`check_synthesis_density`) sentence counting heuristic is prone to false positives.
**Why:** The `awk` logic counts any period, exclamation, or question mark as a sentence. Abbreviations (e.g., "v1.0", "approx.", "Mr.") will inflate the count, potentially allowing sparse synthesis to pass the check.
**Fix:** Refine the `awk` logic to require a space after the punctuation (e.g., `/[.!?][[:space:]]/`) or accept the limitation as a rough heuristic for a warning-level check.

**[F7]** (MINOR)
**Finding:** `extract_frontmatter` helper function is fragile regarding the closing fence.
**Why:** The `awk` script exits immediately upon finding the second `---`. If the file has no closing frontmatter fence (invalid markdown), it might consume the whole file or behave unpredictably.
**Fix:** Ensure the `awk` logic handles EOF gracefully or validates that a second `---` was actually found before returning the block.

**[F8]** (STRENGTH)
**Finding:** The `vault-check.sh` script correctly adheres to the Bash 3.2 constraint (no associative arrays).
**Why:** The use of helper functions and string manipulation avoids `declare -A`, ensuring compatibility with the default macOS environment as requested.
**Fix:** N/A (Keep as is).

**Verdict:** Needs significant revision

(Primary reason: The performance issue in Check 18 [F1] makes the validation script unscalable for a growing vault, and the regex bug [F2] compromises the integrity of the uniqueness check.)

---

## DeepSeek (deepseek-reasoner)

**[F1]** (CRITICAL)
**Finding:** vault-check.sh check 18 (Topics Resolution) fails to properly parse YAML list entries when the topics field contains nested structures or multi-line strings.
**Why:** The `awk` script assumes each topic entry is on its own line starting with `- `, but YAML allows folded scalars and inline lists. A topic entry like `- moc-one, moc-two` would be incorrectly extracted as a single string `moc-one, moc-two`, causing resolution failure.
**Fix:** Use a YAML parser (e.g., `yq` or `python -c 'import sys,yaml;...'`) if available, or enforce a strict one-entry-per-line format in the convention and update the extraction to match only lines with `- ` followed by a single word.

**[F2]** (CRITICAL)
**Finding:** vault-check.sh check 17 (MOC Schema Validation) searches only within `$VAULT_ROOT/Domains` for MOC files, but the spec states MOCs must be in `Domains/*/`. A MOC placed directly in `Domains/` (without a subdirectory) would be missed, and uniqueness checking would be incomplete.
**Why:** The `find` pattern `"$VAULT_ROOT/Domains" -name "*.md"` includes the root `Domains` directory. MOCs must be in a subdirectory per domain (e.g., `Domains/Learning/`); a file in `Domains/` itself violates the location convention but would still be checked as a MOC, causing confusion.
**Fix:** Restrict the find to subdirectories: `find "$VAULT_ROOT/Domains" -mindepth 2 -name "*.md" -type f -print0`.

**[F3]** (SIGNIFICANT)
**Finding:** The wikilink strategy relies on shortest-path resolution without enforcing global filename uniqueness for all notes, not just MOCs.
**Why:** MOC Core sections use `[[filename|Display Name]]` wikilinks. If two notes in different directories share the same filename (e.g., `Projects/foo.md` and `Domains/Learning/foo.md`), the link target is ambiguous and may resolve incorrectly, breaking navigation.
**Fix:** Add a vault-check validation that enforces unique basenames across the entire vault (or at least within each domain) for all `.md` files.

**[F4]** (SIGNIFICANT)
**Finding:** vault-check.sh check 19 (Topics Requirement) may incorrectly flag notes that have a `kb/` tag but are exempt (e.g., MOCs themselves) because it only checks `type` field; notes without a `type` field but with `kb/` tags would be incorrectly required to have topics.
**Why:** The check excludes files with `type: moc-orientation` or `moc-operational`, but many knowledge notes may not have a `type` field at all (it's optional per conventions). This would cause false-positive warnings.
**Fix:** Explicitly define which note types are exempt (e.g., `moc-*`, `source-index`, `summary`) and treat all other types (including missing type) as subject to the topics requirement.

**[F5]** (SIGNIFICANT)
**Finding:** The `topics` field uses bare filenames that resolve to `Domains/*/{name}.md`, but the resolution logic in check 18 searches `Domains/*/` only. If a MOC is placed outside `Domains` (e.g., in `Projects/`), it will not be found, causing false unresolved-topic errors.
**Why:** The system assumes all MOCs are under `Domains/`. A misplaced MOC would break topic references and cause validation errors, but the script does not detect the misplacement.
**Fix:** In check 18, if a topic resolves to zero matches, search the entire vault for the file and, if found, emit a specific error that the MOC is outside the allowed `Domains/*/` location.

**[F6]** (SIGNIFICANT)
**Finding:** The `rawls-theory-justice-index.md` source-index example does not specify its directory path, creating ambiguity about where source-index notes should be placed.
**Why:** The spec says source-index notes live in `Sources/[type]/` directory, but the example artifact is shown without path. If placed in `Domains/Learning/`, it would violate the convention and potentially break source-aggregation workflows.
**Fix:** Clarify in file-conventions.md that source-index notes must be under `Sources/` (e.g., `Sources/books/rawls-theory-justice-index.md`) and update the example accordingly.

**[F7]** (SIGNIFICANT)
**Finding:** vault-check.sh check 21 (MOC Synthesis Density) uses a naive sentence-count heuristic (lines containing `[.!?]`) that will miscount abbreviations (e.g., "e.g."), markdown list items, and section headers.
**Why:** This may produce false-positive warnings for properly synthesized MOCs that use bullet lists or contain abbreviations, undermining the warning's credibility.
**Fix:** Use a more robust sentence detector (e.g., `awk` that ignores common abbreviations) or simply check for a minimum word count (e.g., >30 words) in the Synthesis section between the markers.

**[F8]** (SIGNIFICANT)
**Finding:** The MOC system lacks a defined mechanism for hierarchical or nested MOCs, which will become unwieldy as topics grow beyond 100-200 notes.
**Why:** Currently, MOCs are flat lists. At scale (e.g., 500+ notes per MOC), the Core section becomes too long to navigate, and the single-file approach may impact editor performance.
**Fix:** Define a convention for sub-MOCs (e.g., `moc-history-science.md`) and a parent-child linking pattern, plus validation to ensure notes in sub-MOCs also link to parent MOCs via topics.

**[F9]** (SIGNIFICANT)
**Finding:** The `file-conventions.md` addition states that `topics` is "required if this file has #kb/ tags," but the vault-check (19) only warns; there is no enforcement timeline or condition to upgrade to error.
**Why:** Without a clear upgrade path, the warning may be ignored indefinitely, leaving the knowledge graph incomplete.
**Fix:** Specify a deadline or condition (e.g., "after 2026-03-31" or "when backfill completion is verified") in the script comment and in the conventions document.

**[F10]** (MINOR)
**Finding:** vault-check.sh check 17 uses `grep "^${bn}|"` to detect duplicate MOC filenames, but if `bn` contains regex special characters (e.g., `moc-test-1.2.md`), the grep may behave unexpectedly.
**Why:** While filenames are expected to be alphanumeric-hyphen, edge cases could cause false duplicate detection or missed duplicates.
**Fix:** Escape `bn` for literal string matching: `grep "^$(printf '%s' "$bn" | sed 's/[.[\*^$/]/\\&/g')|"` or use `awk` with exact string comparison.

**[F11]** (MINOR)
**Finding:** The `notes_at_review` field in MOCs is a static snapshot; there is no validation that it matches the actual count of notes in the Core section.
**Why:** Discrepancy between the claimed count and actual links could mislead reviewers about MOC coverage.
**Fix:** Add an optional vault-check that compares `notes_at_review` with the number of wikilinks in the Core section (between `<!-- CORE:START -->` and `<!-- CORE:END -->`) and reports a warning if they differ by more than a threshold.

**[F12]** (MINOR)
**Finding:** The `moc-history.md` includes a fictional character (`Flik`) and a student profile (`Shaan Sahota`) under "Other," blurring the boundary between historical figures and contemporary/campaign-related entries.
**Why:** While the MOC is designed around the Think Different campaign, the title "Historical Figures" may be misleading for users expecting strictly historical subjects.
**Fix:** Rename the MOC to `moc-think-different-figures` or add a disclaimer in the MOC header clarifying the campaign-centric scope.

**[F13]** (MINOR)
**Finding:** The `learning-overview.md` update lists MOCs but does not include the source-index note type in the "Knowledge Base" section, missing an opportunity to educate users about the new artifact type.
**Why:** Users may not discover the source-index pattern unless they read the full file-conventions.
**Fix:** Add a subsection "Source Indexes" under "Knowledge Base" with a brief explanation and example link.

**[F14]** (MINOR)
**Finding:** The `moc-crumb-operations.md` has an empty "Paths" section, which is described as "Required for operational MOCs" in the artifact.
**Why:** Incomplete required sections reduce the utility of operational MOCs as step-by-step guides.
**Fix:** Populate the Paths section with at least a placeholder (e.g., "To be populated after usage patterns emerge") or remove the "required" claim until content exists.

**[F15]** (STRENGTH)
**Finding:** The MOC schema validation (check 17) enforces global filename uniqueness across all domain directories, a critical guard against ambiguous topic resolution.
**Why:** Prevents subtle bugs where a topic reference could point to the wrong MOC due to duplicate names in different domains.
**Fix:** (No fix needed.)

**[F16]** (STRENGTH)
**Finding:** The separation of `moc-orientation` and `moc-operational` types, with different expectations for Synthesis vs. Paths, aligns well with the distinct purposes of conceptual navigation and procedural guidance.
**Why:** Allows the system to evolve different review and maintenance criteria for each type, improving long-term sustainability.
**Fix:** (No fix needed.)

**[F17]** (STRENGTH)
**Finding:** The use of bare filenames in the `topics` field (no path, no extension) leverages Obsidian's shortest-path wikilink resolution, keeping frontmatter clean and portable.
**Why:** Reduces maintenance overhead when moving notes between domains and avoids brittle path-based references.
**Fix:** (No fix needed.)

**[F18]** (STRENGTH)
**Finding:** The source-index note type provides a clean aggregation point for all notes from a single source, preventing MOC bloat and giving each source a dedicated landing page.
**Why:** Encourages systematic source management and improves discoverability of related notes without duplicating links across MOCs.
**Fix:** (No fix needed.)

**[F19]** (SIGNIFICANT)
**Finding:** UNVERIFIABLE CLAIM: The artifact states "Check 19 (topics requirement) is intentionally a WARNING, not an error -- 3 deferred files exist without MOCs." The review cannot verify the existence or justification of these three deferred files.
**Why:** Without access to the vault, we cannot assess whether deferral is appropriate or if the warning threshold is set correctly.
**Fix:** Document the deferred files and the criteria for their exemption in a visible place (e.g., a `DEFERRED_TOPICS.md` note) so future reviewers can verify.

**[F20]** (SIGNIFICANT)
**Finding:** UNVERIFIABLE CLAIM: The "Backfill of `topics` field on 65+ existing files pointing to their parent MOCs" is asserted but not shown. The review cannot verify that the backfill was performed correctly or completely.
**Why:** Missing or incorrect backfill would cause check 19 to produce widespread warnings and undermine the MOC system's integrity.
**Fix:** Provide a summary report of the backfill (e.g., count of files updated, list of MOCs referenced) as part of the artifact.

**Verdict:** Needs significant revision

---

## Grok (grok-4-1-fast-reasoning)

**[F1]** (CRITICAL)
**Finding:** No validation of MOC body structure (e.g., presence of DELTAS, SYNTHESIS, CORE sections with markers).
**Why:** vault-check 17 only validates frontmatter; malformed MOC bodies (missing `<!-- CORE:START -->` etc.) would pass silently, breaking navigation and synthesis checks like 21.
**Fix:** Add check 22 to scan Domains/*/*.md with type:moc-* for required section markers using grep/awk patterns.

**[F2]** (CRITICAL)
**Finding:** No validation that wikilinks in MOC Core sections resolve to existing files.
**Why:** Broken links in Core (e.g., `[[nonexistent|Name]]`) render MOCs unusable for navigation; current checks ignore body content beyond simplistic counts.
**Fix:** Implement check 23: parse Core sections, extract bare/aliased wikilink targets, verify existence via find across vault dirs.

**[F3]** (SIGNIFICANT)
**Finding:** Flat Core lists in MOCs do not scale; historical-figures has ~48 entries with subheadings but no sub-MOC delegation.
**Why:** At 500+ notes (per prompt query), Core becomes unreadable scrolling list; tensions section notes this but no enforcement or subtopic MOCs created.
**Fix:** Add guideline in file-conventions.md for sub-MOCs under large topics; update check 21 to warn at >20 Core entries without Paths or sub-MOCs.

**[F4]** (SIGNIFICANT)
**Finding:** Unidirectional topics validation; no check that MOC Core links back to files claiming membership via topics.
**Why:** Drift risk: file adds topics:moc-xxx but not added to MOC Core, or vice versa; schema consistency breaks without bidirectional enforcement.
**Fix:** Add check 24: for each topics entry, scan target MOC Core for wikilink matching source filename (basename sans .md).

**[F5]** (SIGNIFICANT)
**Finding:** Wikilink strategy inconsistent: bare names in most Core entries, full paths in crumb-architecture (e.g., Projects/...).
**Why:** Violates "shortest-path wikilink resolution (not path-prefixed)" constraint; mixes styles confuses maintenance and assumes Obsidian handles both uniformly.
**Fix:** Standardize to bare wikilinks only (rename files for uniqueness if needed); document fallback to paths only for unavoidable ambiguities.

**[F6]** (SIGNIFICANT)
**Finding:** UNVERIFIABLE CLAIM: Backfill of `topics` field on 65+ existing files and exactly 3 deferred files without MOCs.
**Why:** Artifacts show no evidence (e.g., no sample backfilled files); check 19 assumes this state but cannot confirm compliance or completeness.
**Fix:** Provide log/diff of backfill changes or sample 5+ backfilled files; run vault-check 19 output in review.

**[F7]** (SIGNIFICANT)
**Finding:** Check 21 synthesis density uses fragile heuristics (line-based `[[` count, sentence regex).
**Why:** Overcounts multi-link lines; misses sentences without .!? or in lists; false positives/negatives undermine debt tracking (e.g., historical-figures should warn but regex may fail on empty comments).
**Fix:** Refine awk: count bullets (`- [[`) for core; use wc -w on stripped prose >50 words for synthesis threshold.

**[F8]** (SIGNIFICANT)
**Finding:** MOC uniqueness check 17 uses inefficient string concatenation/grep on MOC_SEEN_FILES.
**Why:** Scales poorly beyond ~100 MOCs (memory, grep slowness); fragile to `|` in paths (unlikely but unescaped); bash 3.2 ok but not robust.
**Fix:** Switch to sorted temp file: sort -u check via comm/join, or temp dir symlinks for existence (bash 3.2 safe).

**[F9]** (MINOR)
**Finding:** Check 19 hardcodes skips for run-log*.md|progress-log.md by basename only.
**Why:** Fails if renamed or in subdirs; operational logs with kb/ tags could slip through without topics.
**Fix:** Extract type or tags first, skip if type:log or grep log patterns in basename/path.

**[F10]** (MINOR)
**Finding:** Check numbers skip 20 (17-19,21 shown); unclear if gap intentional.
**Why:** Documentation gap; readers assume missing check affects sequencing or completeness.
**Fix:** Note "check 20 pre-exists" or include stub; ensure sequential in full script.

**[F11]** (MINOR)
**Finding:** Future dates (2026-02-24) across all MOCs/source-index.
**Why:** Inconsistent with real-world timelines; confuses versioning if vault used presently.
**Fix:** Use current dates (e.g., 2024) or placeholder [DATE].

**[F12]** (MINOR)
**Finding:** Paths section empty in all MOCs despite "required for operational MOCs".
**Why:** moc-crumb-operations lacks procedure steps; violates schema intent for usage patterns.
**Fix:** Populate Paths in operational MOCs or demote to optional with vault-check warning.

**[F13]** (STRENGTH)
**Finding:** Frontmatter schema fully consistent across 4 MOCs, source-index, and file-conventions.md additions.
**Why:** Uniform fields (e.g., type, scope, topics usage); validates against design (moc-orientation vs operational distinction clear).
**Fix:** N/A

**[F14]** (STRENGTH)
**Finding:** Bash helpers (extract_frontmatter etc.) reusable, bash 3.2 compatible (no assoc arrays, process subs ok).
**Why:** Correctly handles YAML-ish parsing, null-sep find; checks like 18 array usage confirmed bash 3.2 supported.
**Fix:** N/A

**[F15]** (STRENGTH)
**Finding:** Topics resolution (check 18) correctly enforces unique bare-name-to-MOC mapping.
**Why:** Matches design (Domains/*/search, type validation); prevents ambiguity/duplicates as required.
**Fix:** N/A

**Verdict:** Needs significant revision

---

## Perplexity (sonar-reasoning-pro) — manual submission

**[F1]** (SIGNIFICANT)
**Finding:** Check 17 uniqueness grep yields false positives when one MOC filename is a prefix of another (e.g., `moc-dns.md` vs `moc-dns-architecture.md`). Pattern `grep "^${bn}|"` matches anchored at start but not end-of-filename.
**Why:** Substring hits bypass the uniqueness guarantee, silently allowing collisions or flagging non-duplicates.
**Fix:** Use awk with exact string comparison: `awk -F'|' -v f="$bn" '$1==f {print; exit}'`

**[F2]** (SIGNIFICANT)
**Finding:** Check 18 (Topics Resolution) omits `_attachments/` and `Archived/` directories from its scan scope. §5.6 applies to all stable kb-tagged content.
**Why:** kb-tagged companion notes in `_attachments/` or archived notes with `topics` would silently bypass resolution checks.
**Fix:** Add `_attachments` and `Archived` to the search scope.

**[F3]** (MINOR)
**Finding:** Check 19 uses filename-based exemptions (`run-log*.md`, `progress-log.md`) instead of type-based exclusion.
**Why:** Fragile against renames or additional operational file types; inconsistent with the type-driven logic in other checks.
**Fix:** Derive exemptions by `type:` field (e.g., skip `log`, `system-meta`, `source-index`).

**[F4]** (SIGNIFICANT)
**Finding:** Check 21 sentence counting heuristic (`/^[^<#]/ && /[.!?]/`) overcounts bullets and misses wrapped sentences across multiple lines.
**Why:** MOCs with bullet-heavy Synthesis sections falsely warned or falsely passed.
**Fix:** Collapse wrapped lines and count sentence delimiters, or switch to word count threshold.

**[F5]** (SIGNIFICANT)
**Finding:** No vault-check validation for `source-index` notes despite a full schema being defined.
**Why:** Missing fields (source.title, source.author, source_id) go undetected. Schema drift risk.
**Fix:** Add Check 20 for source-index schema validation — also fills the numbering gap.

**[F6]** (SIGNIFICANT)
**Finding:** The soft one-liner quality lint from §5.6.6 ("warn if <10 chars after [[...]]") is not implemented.
**Why:** Thin one-liners reduce MOC orientation value at scale.
**Fix:** Implement as part of Check 21 or a new check.

**[F7]** (MINOR)
**Finding:** Check numbering skips from 19 to 21 with no explanation.
**Why:** Documentation gap confuses maintainers.
**Fix:** Add placeholder comment: `# 20. Reserved — future source-index schema validation`.

**[F8]** (STRENGTH)
**Finding:** Backfill deferral strategy (3 single-file topics) is well-justified. Leaving Check 19 as warning prevents premature MOC proliferation.

**[F9]** (STRENGTH)
**Finding:** Bash 3.2 compatibility layer (string-based uniqueness instead of `declare -A`) is robust and portable.

**[F10]** (STRENGTH)
**Finding:** MOC placement and backfill flow exactly match §5.6.4's domain locality and hierarchy rules.

**Verdict:** Needs significant revision

---

## Synthesis

### Consensus Findings

**C1: Check 21 synthesis density heuristic is fragile (5/5 reviewers)**
Sources: OAI-F7, GEM-F6, DS-F7, GRK-F7, PPLX-F4
All five reviewers flag the sentence-counting approach (`/[.!?]/` per line) as unreliable. Failure modes: abbreviations ("e.g."), bullets ending in periods, multi-line sentences, list items. Universal consensus — the strongest signal in this review.

**C2: YAML parsing fragility across multiple checks (4/5 reviewers)**
Sources: OAI-F3/F4/F11, GEM-F3/F7, DS-F1/F4, PPLX-F3
The awk/grep-based YAML extraction can't handle inline arrays (`tags: [kb/history]`), quoted values (`type: "moc-orientation"`), or edge-case formatting. Affects checks 17, 18, 19. Risk is moderated by the fact that vault-check itself enforces the YAML list convention — inline arrays are a convention violation. However, `extract_field` should strip surrounding quotes to be robust.

**C3: Wikilink style inconsistency in MOCs (4/5 reviewers)**
Sources: OAI-F6, GEM-F5, DS-F3, GRK-F5
`moc-crumb-architecture.md` uses path-prefixed wikilinks (`[[Projects/.../specification|...]]`) while the design constraint says shortest-path. This is by design for ambiguous filenames (documented in run-log: 10 files named `specification.md`), but the convention is not formally documented in file-conventions.md.

**C4: Non-MOC filename uniqueness not enforced (3/5 reviewers)**
Sources: OAI-F1/F12, GEM-F4, DS-F3
Check 17 enforces uniqueness only for MOC filenames. But MOC Core sections link to non-MOC files via bare wikilinks (`[[albert-einstein|...]]`). As the vault grows, name collisions among non-MOC notes would break navigation.

**C5: Missing source-index vault-check validation (2/5 reviewers)**
Sources: OAI-F8, PPLX-F5
`type: source-index` has a defined schema with required fields but no mechanical enforcement. Schema drift is certain without a check.

**C6: Scalability — no sub-MOC convention (2/5 reviewers)**
Sources: DS-F8, GRK-F3
Flat Core lists won't scale past 100-200 entries. The largest MOC (historical-figures) already has 48 entries with subheadings, but no sub-MOC delegation convention exists.

**C7: Check 17 grep pattern issues (4/5 reviewers)**
Sources: GEM-F2, DS-F10, PPLX-F1, GRK-F8
The `grep "^${bn}|"` pattern treats dots as regex wildcards and can match prefixes. A file named `moc-test.md` could incorrectly match `moc-testxmd`. Performance also degrades with string concatenation at scale.

**C8: Backfill claims unverifiable (3/5 reviewers)**
Sources: OAI-F15, DS-F19/F20, GRK-F6
The "65+ files backfilled" and "3 deferred files" claims can't be verified from the artifacts alone. Note: These are verifiable by running `vault-check` on the live vault — the 3 warnings and 0 errors confirm the state. This is inherent to reviewing a multi-file project by artifact snapshot.

### Unique Findings

**U1: GRK-F1/F2 — No validation of MOC body structure or wikilink resolution** (genuine insight)
Only Grok identified that Check 17 validates frontmatter but not the required section markers (DELTAS:START/END, SYNTHESIS:START/END, CORE:START/END) or that wikilinks in Core resolve to existing files. A MOC with valid frontmatter but missing CORE markers would pass all checks while being completely non-functional for navigation.

**U2: GRK-F4 — Bidirectional topics/Core validation missing** (genuine insight)
Only Grok identified the uni-directional validation gap: Check 18 verifies topics→MOC resolution, but nothing verifies that files listed in topics actually appear in the target MOC's Core section, or vice versa. Drift between file-level `topics` claims and MOC Core content is undetectable.

**U3: PPLX-F6 — Missing one-liner quality lint from §5.6.6** (genuine insight, verified)
Only Perplexity flagged that §5.6.6 explicitly specifies "vault-check emits an informational warning (not error, not blocking) if a one-liner in Core is shorter than 10 characters after the [[...]] link." Spec section exists and is unambiguous — this is a missed implementation item.

**U4: PPLX-F2 — Check 18/19 scope omits _attachments/ and Archived/** (genuine insight)
Only Perplexity noted that companion notes in `_attachments/` could carry kb/ tags but bypass topic resolution checks. Low-priority currently but would become relevant as the attachment corpus grows.

**U5: DS-F12 — Historical figures MOC title may be misleading** (noise)
DeepSeek flags that Flik (Pixar character) and Shaan Sahota (student) aren't historical figures. True literally, but the MOC's scope is the Think Different campaign — the "Other" category and cross-cutting section make this explicit.

### Contradictions

**OAI-F2 (bash arrays unsafe) vs GRK-F14 (bash helpers compatible):**
OpenAI claims Check 18's indexed arrays (`matches=()`, `matches+=`) are a bash 3.2 risk. Grok says the helpers are compatible. **Grok is correct** — bash 3.2 supports indexed arrays; the constraint is only about associative arrays (`declare -A`). However, if the script were ever run under `/bin/sh`, arrays would fail. Current shebang is `#!/bin/bash`, so this is safe.

**DS-F5 (misplaced MOC error) vs actual design:**
DeepSeek suggests that if a MOC is placed outside `Domains/`, Check 18 should search the entire vault and give a specific misplacement error. This is reasonable but adds complexity for a user-error scenario that vault-check's existing Check 1 (frontmatter validation) would catch indirectly.

### Action Items

**Must-fix:**

- **A1** (C7: GEM-F2, DS-F10, PPLX-F1): Fix Check 17 grep pattern — replace `grep "^${bn}|"` with awk exact string matching to prevent regex dot wildcards and prefix matching. Simple one-line fix.

- **A2** (C3: OAI-F6, GEM-F5, GRK-F5): Document wikilink convention in file-conventions.md — "Use bare wikilinks for globally-unique basenames; use path-prefixed wikilinks only for filenames with known ambiguity (multiple files sharing the same name)." The implementation already follows this rule; it just lacks formal documentation.

**Should-fix:**

- **A3** (C1: all 5 reviewers): Improve Check 21 synthesis density heuristic — replace sentence counting with word count threshold (e.g., >30 words between SYNTHESIS markers). Simpler, more robust, addresses all five reviewers' concerns.

- **A4** (C5: OAI-F8, PPLX-F5 + C8: GRK-F10, PPLX-F7): Add Check 20 for source-index schema validation — verify `source.source_id`, `source.title`, `source.author`, `source.source_type` exist. Fills the numbering gap between 19 and 21.

**Must-fix (promoted from should-fix per operator review):**

- **A5** (U1: GRK-F1): Add MOC body structure validation — verify CORE:START/END, SYNTHESIS:START/END, DELTAS:START/END markers exist in MOC files. Can extend Check 17 or add as Check 22. *Promoted: body markers are load-bearing for Check 21 and navigation — frontmatter-only validation is insufficient.*

- **A6** (OAI-F10): Fix moc-philosophy Tensions text — "Currently only 2 notes" should say "Currently only 1 note" to match `notes_at_review: 1`.

- **A7** (GEM-F1): Cache find results in Check 18 — run `find Domains/ -name "*.md"` once at script start and search the cached list instead of spawning find per topic entry. Performance improvement for scaling.

- **A8** (C2: OAI-F3): Harden `extract_field` to strip surrounding quotes — handles `type: "moc-orientation"` as well as `type: moc-orientation`. One-line sed addition.

- **A15** (PPLX-F6): Add one-liner quality lint per §5.6.6 — informational warning (not error) if a Core one-liner has <10 characters after the `[[...]]` link. Simple awk check inside CORE markers. *Promoted from defer: spec section verified as unambiguous.*

**Defer:**

- **A9** (C4: OAI-F1/F12, GEM-F4, DS-F3): Non-MOC filename uniqueness enforcement. Valid concern but large scope — would need vault-wide basename collision detection. Currently mitigated by the Obsidian graph (which shows ambiguous links). Revisit when actual collisions are reported. `defer`

- **A10** (C6: DS-F8, GRK-F3): Sub-MOC convention. Largest MOC has 48 entries with subheadings — manageable. Define the convention when any MOC exceeds 100 entries. `defer`

- **A11** (U2: GRK-F4): Bidirectional topics/Core validation. Useful for drift detection but adds significant check complexity. Defer until topic drift is actually observed. `defer`

- **A12** (GRK-F2): Wikilink resolution validation in Core sections. Compute-intensive (needs vault-wide file search per link). Valuable but deferred — broken links are visible in Obsidian's graph view. `defer`

- **A13** (DS-F9): Check 19 upgrade timeline. The TODO comment in the script is sufficient — promote to error when each of the 3 deferred topics reaches 3+ notes. `defer`

- **A14** (PPLX-F2): Extend Check 18/19 scope to `_attachments/` and `Archived/`. Low current density of kb-tagged content in these directories. `defer`

- ~~**A15**~~ Promoted to should-fix (see above).

### Considered and Declined

- **OAI-F2** (Check 18 uses bash arrays): `incorrect` — bash 3.2 supports indexed arrays; the constraint is about associative arrays only. Shebang is `#!/bin/bash`. No action needed.

- **DS-F2** (Check 17 should restrict to Domains/*/): `overkill` — `find "$VAULT_ROOT/Domains" -name "*.md"` recursively searches all subdirectories, which correctly covers `Domains/Learning/`. A MOC placed at `Domains/moc-foo.md` (without subdirectory) is a user error that would fail other conventions. Adding `-mindepth 2` adds complexity for a non-existent problem.

- **DS-F12** (Rename moc-history): `constraint` — The MOC scopes to the Think Different campaign which deliberately includes Flik and Shaan Sahota. The "Other" category and cross-cutting section make the campaign scope explicit. 45/48 entries are historical figures.

- **GRK-F11** (Future dates 2026-02-24): `incorrect` — 2026-02-24 is today's date. The reviewer lacks system clock context.

- **DS-F6** (Source index path ambiguous): `incorrect` — The source index is at `Sources/books/rawls-theory-justice-index.md` and file-conventions states "Source index notes... live in the same `Sources/[type]/` directory as their child knowledge notes." Path is explicit.

- **DS-F4** (Check 19 false positives for typeless notes): `incorrect` — All vault docs require `type` in frontmatter per file-conventions. Check 1 validates this. A typeless note with kb/ tags would already be flagged by Check 1 before Check 19 runs.

- **PPLX-F3** (Type-based exemptions in Check 19): `overkill` — Current filename-based exemptions cover the only two operational file types that could carry kb/ tags. Adding type-based logic adds parsing overhead for a theoretical scenario. Monitor for recurrence.
