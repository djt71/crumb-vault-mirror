---
type: reference
project: x-feed-intel
domain: software
status: applied
purpose: Spec amendment instructions for Crumb to apply to x-feed-intel specification v0.4.2
created: 2026-02-23
updated: 2026-02-23
source: claude-ai peer review session (XFI-009)
---

# XFI-009 Spec Amendments

These amendments are the output of the operator benchmark review (XFI-009). Crumb should apply them to `Projects/x-feed-intel/design/specification.md` and bump the version to **v0.4.3**.

---

## Amendment 1: Pin topic config file path (§5.2)

**Location:** §5.2 Topic Scanner, after the "Topic config:" paragraph and the YAML example block, before "Filter resolution:"

**Add after** "Designed for easy extension — adding a new domain requires only adding an entry to this file.":

```
**Config file location:** `config/topics.yaml` relative to the pipeline repo root (`~/openclaw/x-feed-intel/config/topics.yaml`). This file is version-controlled in the pipeline repo. The topic config loader (XFI-003) reads this path on each capture clock run — no hot-reload or restart required.
```

Also update the "What this project adds:" list in §8 to change:

> - A topic config file (operator-editable, Tess-readable)

to:

> - A topic config file at `config/topics.yaml` (operator-editable, Tess-managed)

---

## Amendment 2: Tess topic management capability (§5.2)

**Location:** §5.2 Topic Scanner, after the new "Config file location:" paragraph from Amendment 1, before "Filter resolution:"

**Add new paragraph:**

```
**Tess topic management:** Tess can read and modify the topic config on the operator's behalf via Telegram commands. Supported interactions:

- **List topics:** Operator asks what topics are configured. Tess reads `config/topics.yaml` and reports topic names, query counts, and filter settings.
- **Add topic:** Operator requests a new topic. Tess proposes queries and filters (or accepts operator-specified ones), appends the topic entry to the config, runs the topic config loader's validation to confirm valid YAML and schema, and commits the change to git. If validation fails, Tess reverts the edit and reports the error.
- **Remove topic:** Operator requests topic removal. Tess confirms the topic name, removes the entry, validates, and commits.
- **Modify queries/filters:** Operator requests changes to an existing topic's queries or filters. Tess applies the edit, validates, and commits.

All topic config edits follow the same procedure: (1) read current config, (2) apply edit, (3) run topic config loader validation, (4) commit to git on success or revert on failure, (5) confirm to operator. Changes take effect on the next capture clock run.

Tess does not modify topic config autonomously. All changes are operator-initiated via Telegram.
```

---

## Amendment 3: Tess topic management in boundary compliance (§8)

**Location:** §8 Boundary Compliance, in the "Tess owns:" bullet.

**Change:**

> - **Tess owns:** Runtime operation of the pipeline, triage execution, digest delivery, `_openclaw/feeds/` management, vault promotion of operational items, feedback processing.

**To:**

> - **Tess owns:** Runtime operation of the pipeline, triage execution, digest delivery, `_openclaw/feeds/` management, vault promotion of operational items, feedback processing, topic config management (read/add/remove/modify on operator request with validation-before-commit).

---

## Amendment 4: KB tag alignment note (§5.6)

**Location:** §5.6 Vault Router, after the "KB-worthy items" bullet and before "Everything else."

**Add new paragraph:**

```
**KB tag assignment:** The pipeline's triage tags (`crumb-architecture`, `tool-discovery`, etc.) drive routing decisions within the pipeline. They are not KB tags. When Crumb reviews items in `_openclaw/feeds/kb-review/`, Crumb assigns the appropriate `#kb/` tag from the canonical vault taxonomy (e.g., `#kb/software-dev`, `#kb/software-dev/agent-architecture`). This separation keeps Tess's routing logic independent from the vault's knowledge classification. Tess never assigns `#kb/` tags.
```

---

## Amendment 5: Phase 0 benchmark query tuning (§5.2)

**Location:** §5.2 Topic Scanner, the YAML example block. Replace the current topic definitions with the post-benchmark-review versions:

```yaml
# Global defaults
defaults:
  max_age_days: 7          # Ignore posts older than this (prevents stale content on new topics)
  max_results: 50          # Per-query cap
  filters: ""              # Default search operator string appended to all queries

topics:
  - name: agent-architecture
    queries:
      - "agent architecture LLM"
      - "agentic coding"
      - "multi-agent system"
    max_results: 50
    filters: "min_faves:10 -filter:replies lang:en"
    
  - name: claude-code
    queries:
      - "claude code"
      - "anthropic claude developer"
      - "claude MCP"
    max_results: 50
    filters: "min_faves:5 -filter:replies lang:en"
    
  - name: obsidian-pkm
    queries:
      - "obsidian vault"
      - "personal knowledge management AI"
      - "obsidian plugin AI"
    max_results: 50
    filters: "min_faves:10 -filter:replies lang:en"
    
  - name: ai-workflows
    queries:
      - "developer workflow LLM"
      - "LLM tool use"
      - "AI-assisted development"
    max_results: 50
    filters: "min_faves:20 -filter:replies lang:en"

  # Future: account monitoring
  # accounts:
  #   - username: "example_user"
  #     pull_all: true
```

**Changes from v0.4.2:**

- `obsidian-pkm`: Replaced "second brain agent" (too much generic self-help noise) with "obsidian plugin AI" (more targeted)
- `ai-workflows`: Replaced "AI automation workflow" (attracted spam/marketing accounts) with "developer workflow LLM" (tighter signal); bumped `min_faves` from 10 to 20 (highest noise-to-signal topic needs stricter engagement filter)

---

## Amendment 6: Changelog entry (§15)

**Add to top of §15 Changelog:**

```
### v0.4.3 (2026-02-23) — Phase 0 Benchmark Review + Topic Management

**Operator benchmark review (XFI-009):**
- **B1:** Topic config file path pinned to `config/topics.yaml` relative to pipeline repo root. (§5.2)
- **B2:** Tess topic management capability defined — read/add/remove/modify topics via Telegram with validation-before-commit. (§5.2, §8)
- **B3:** KB tag alignment clarified — triage tags are pipeline-internal; `#kb/` assignment is Crumb's responsibility at review time. Tess never assigns `#kb/` tags. (§5.6)
- **B4:** Topic query tuning from benchmark data — `obsidian-pkm` third query replaced ("second brain agent" → "obsidian plugin AI"); `ai-workflows` first query replaced ("AI automation workflow" → "developer workflow LLM") and `min_faves` bumped to 20. (§5.2)
- **B5:** Labeled benchmark set created: `benchmarks/xfi-triage-benchmark-20260223.json` (20 posts, operator-labeled). (§12)
```

---

## Additional task: File placement for benchmark

Crumb should copy the labeled benchmark file to `~/openclaw/x-feed-intel/benchmarks/xfi-triage-benchmark-20260223.json`. This file is referenced by XFI-017 (triage prompt engineering) for validation.

---

## Additional task: Update topics.yaml on disk

After applying the spec amendments, Crumb should also update the actual `config/topics.yaml` file in the pipeline repo (if it exists, or create `config/` directory and the file if not) to match the amended spec's YAML block. This ensures the live config matches the spec.

---

## Notes for Crumb

- These amendments do NOT change architecture, schemas, or add dependencies. They are clarifications, path pinning, and query tuning.
- The Tess topic management capability (Amendment 2) is a Phase 1 implementation concern — the spec just needs to define the capability. Actual Tess-side implementation (parsing Telegram commands for topic management) is covered by the feedback listener and ops tooling, not a new task.
- The KB tag alignment note (Amendment 4) is informational — it codifies what was already implicit in the separation between triage tags and vault taxonomy.
