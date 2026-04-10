---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/vault-mobile-access/design/specification.md
artifact_type: spec
artifact_hash: 0635417d
prompt_hash: 6f8b5f1d
base_ref: null
project: vault-mobile-access
domain: software
skill_origin: peer-review
created: 2026-04-04
updated: 2026-04-04
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "File paths with /Users/ on lines 26, 52, 64, 142 (expected — artifact subject matter)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 56268
    attempts: 1
    raw_json: Projects/vault-mobile-access/reviews/raw/2026-04-04-specification-openai.json
  google:
    http_status: 200
    latency_ms: 30479
    attempts: 1
    raw_json: Projects/vault-mobile-access/reviews/raw/2026-04-04-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 41522
    attempts: 1
    raw_json: Projects/vault-mobile-access/reviews/raw/2026-04-04-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 22012
    attempts: 1
    raw_json: Projects/vault-mobile-access/reviews/raw/2026-04-04-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: vault-mobile-access Specification

**Artifact:** Projects/vault-mobile-access/design/specification.md
**Mode:** full
**Reviewed:** 2026-04-04
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Structured review of vault-mobile-access specification evaluating correctness, completeness, internal consistency, feasibility, and clarity.

---

## OpenAI (gpt-5.4)

Here's a structured review of the specification.

### Overall Assessment

This is a strong, implementation-oriented spec with a clear problem statement, sensible scope control, and a realistic architecture for read-only mobile access over Tailscale. The design is broadly feasible and internally coherent. The biggest weaknesses are around operational details: how Quartz ingests the vault, how rebuilds are performed atomically, how the web server is bound and secured on Tailscale, and how launchd behavior is specified. There are also a few factual claims that should be verified rather than asserted.

---

### Findings

- [F1]
- [Severity]: STRENGTH
- [Finding]: The problem statement, primary user, environment, and success mode are clearly defined.
- [Why]: This makes the solution appropriately constrained: read-only mobile browsing over a private network, not full Obsidian sync or editing. That keeps complexity low and avoids overbuilding.
- [Fix]: None.

- [F2]
- [Severity]: STRENGTH
- [Finding]: The architecture is simple and appropriate: static generation on the Mac Studio, lightweight server, access via Tailscale.
- [Why]: For a ~54MB vault and mobile read access, static serving is operationally cheap, secure by topology, and easy to maintain.
- [Fix]: None.

- [F3]
- [Severity]: STRENGTH
- [Finding]: The spec correctly identifies key content and UX constraints: Obsidian syntax support, iOS/WebKit quirks, read-only scope, and private-network-only access.
- [Why]: These are the real drivers of tool choice and implementation details, and they are surfaced early.
- [Fix]: None.

- [F4]
- [Severity]: STRENGTH
- [Finding]: Included/excluded content scope is well thought out and pragmatically aligned with the use case.
- [Why]: Excluding automation internals and app metadata should reduce noise, improve relevance, and likely reduce build/index size.
- [Fix]: None.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not explain exactly how Quartz will consume the vault content from `/Users/tess/crumb-vault/`.
- [Why]: This is an implementation-critical detail. Quartz commonly expects content in a particular source/content directory or workflow. Whether the solution uses symlinks, rsync, bind-like mirroring, Quartz config pointing at a custom content root, or a preprocessing step materially affects build correctness, exclusion handling, and atomic rebuild strategy.
- [Fix]: Add a dedicated "Content ingestion strategy" section specifying one of:
  1. Quartz configured to read directly from `/Users/tess/crumb-vault/`;
  2. A staged mirror of included files into Quartz's content directory before build;
  3. Symlink-based ingestion.
  Also specify how exclusions are enforced in that mechanism.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: "Atomic swap" is required for rebuilds, but the build/output directory model is underspecified.
- [Why]: If Quartz builds directly into the same `public/` directory being served, the site may become temporarily inconsistent or broken during rebuild. The acceptance criteria mention atomic swap, but the implementation pattern is not described.
- [Fix]: Specify the rebuild flow concretely, e.g.:
  - build into `public-next/`
  - validate expected files exist
  - atomically rename `public/` to `public-prev/`, `public-next/` to `public/`
  - optionally clean up `public-prev/`
  Also specify whether the server serves a symlink target or a fixed directory.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: The web server selection is too vague for a system spec.
- [Why]: "Caddy, `serve`, or similar" leaves important behavior undefined: directory serving semantics, cache headers, MIME types, launchd integration, binding address, and logging. Different servers also differ in resilience and operational footprint.
- [Fix]: Choose one server in the spec and justify it. For example:
  - Caddy for robust static serving and simple config; or
  - a minimal Node/static server if minimizing dependencies is preferred.
  Then define exact port, bind address, document root, log path, and startup command.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Network exposure is not specified precisely enough.
- [Why]: "Private network only" is a goal, not a configuration. A server listening on `0.0.0.0:8080` may be reachable on other local interfaces, depending on host/network conditions. The security posture relies on binding and/or host firewall behavior.
- [Fix]: Specify one of:
  - bind only to the Tailscale interface/IP; or
  - bind to localhost and expose via Tailscale Serve/Funnel-equivalent if intended; or
  - bind broadly but explicitly restrict with macOS firewall/pf.
  Include acceptance criteria confirming the site is reachable over Tailscale and not reachable from non-Tailscale networks.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: Launchd behavior is partially described but operationally incomplete.
- [Why]: "Starts on login and survives restarts" can be interpreted in multiple ways for a LaunchAgent. A LaunchAgent depends on the user session; after reboot, whether it starts automatically depends on login state. If the Mac reboots unattended, service availability may not match expectations.
- [Fix]: Clarify whether the intended mechanism is:
  - LaunchAgent under `tess` requiring user login; or
  - LaunchDaemon/system service if unattended startup is required.
  Align this with assumption A2 and desired availability semantics.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Assumption A2 conflates "always on" with "wakes on network access," which may not hold for the chosen access path.
- [Why]: Wake behavior on macOS depends on specific hardware, settings, and network conditions. Tailscale-triggered wake is not guaranteed merely because VPN is configured. If the machine sleeps, mobile access may fail unpredictably.
- [Fix]: Replace A2 with explicit operational requirement and validation:
  - either configure the Mac Studio to avoid sleeping;
  - or validate Wake for network access specifically in this Tailscale/mobile scenario.
  Add acceptance criteria for availability after idle periods.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: Search/index performance is identified as an unknown, but there is no acceptance criterion or fallback plan tied to it.
- [Why]: Search payload size can materially affect mobile usability, especially on iPhone over VPN. If initial load is poor, this may undermine the main use case.
- [Fix]: Add measurable criteria such as:
  - initial page load target on iPhone over Tailscale;
  - search index size ceiling;
  - fallback options if exceeded, such as disabling full-text search, reducing indexed scope, or lazy-loading search assets.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: Binary assets and embedded content handling are mentioned as an unknown, but not decomposed into validation tasks.
- [Why]: Obsidian vaults often contain images, PDFs, attachments, and embedded notes. If these are not copied/resolved correctly, many pages may appear broken on mobile despite a "successful build."
- [Fix]: Add explicit validation/acceptance criteria for:
  - image embeds;
  - note embeds;
  - PDF or binary links;
  - Mermaid rendering;
  - backlinks and tag pages.
  Consider a representative content compatibility test set.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not define URL/path behavior for root-level docs and special filenames.
- [Why]: Files like `CLAUDE.md`, frontmatter-heavy docs, index notes, files with spaces, punctuation, duplicate names in different folders, or nonstandard characters may generate surprising URLs or collisions in static site generators.
- [Fix]: Add a compatibility note and acceptance checks for:
  - duplicate basenames;
  - files with spaces/special characters;
  - root-level files;
  - index/homepage mapping;
  - broken-link reporting during build.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: Logging and observability are too thinly specified.
- [Why]: If the site or rebuild fails, the operator needs to know whether the issue is Quartz build, content parsing, launchd, server startup, or Tailscale reachability. "Build errors logged" is not enough.
- [Fix]: Define log locations and basic operational checks:
  - build stdout/stderr log path;
  - web server log path;
  - launchd label names;
  - a simple health check URL or "index exists" verification;
  - a recovery procedure after failed build.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: The rebuild trigger model is underspecified relative to user expectations.
- [Why]: A scheduled rebuild every 15-30 minutes may be acceptable, but the spec never defines freshness requirements. If Danny updates the vault from a laptop and expects it on mobile soon after, stale content may be confusing.
- [Fix]: Add an explicit freshness SLO, e.g. "mobile site reflects vault changes within 30 minutes" or "manual rebuild command available for immediate refresh." Optionally compare polling schedule vs file-watch approach.

- [F16]
- [Severity]: MINOR
- [Finding]: The Architecture diagram says "Quartz build (cron/watch)" while the task decomposition later specifies scheduled rebuild with launchd plist or cron.
- [Why]: This is a mild internal inconsistency. "watch" implies continuous event-driven rebuild, while later text favors scheduled execution.
- [Fix]: Normalize terminology to the chosen strategy. If scheduled rebuild is the MVP, remove "watch" from the architecture diagram.

- [F17]
- [Severity]: MINOR
- [Finding]: The acceptance criterion "Local preview shows vault content with wikilinks resolved" is too informal.
- [Why]: It is testable in spirit but not precise enough for handoff or verification.
- [Fix]: Make it concrete, e.g. "at least N representative notes render correctly with resolved internal links, backlinks, tags, embeds, and Mermaid diagrams."

- [F18]
- [Severity]: MINOR
- [Finding]: The service registration requirement references `project-state.yaml`, which is not described in this spec.
- [Why]: Reviewers lacking broader Crumb context cannot assess that requirement, and implementers may not know schema expectations.
- [Fix]: Add a brief note defining the expected service metadata or reference the governing schema/spec.

- [F19]
- [Severity]: MINOR
- [Finding]: The "Design Note: Aesthetic" section is reasonable but somewhat detached from implementation.
- [Why]: It adds context, but for an MVP systems spec it may be more useful if tied to specific deferred work items.
- [Fix]: Convert follow-up aesthetic ideas into out-of-scope notes or backlog items.

- [F20]
- [Severity]: MINOR
- [Finding]: Port `:8080` appears in the diagram but not as a firm configuration decision elsewhere.
- [Why]: This is a small clarity gap; diagrams should match implementation requirements.
- [Fix]: State the canonical port in the web server task and note whether it is configurable.

- [F21]
- [Severity]: STRENGTH
- [Finding]: The assumptions and unknowns are candid and mostly actionable.
- [Why]: This makes the spec realistic rather than pretending all operational unknowns are settled upfront.
- [Fix]: None.

- [F22]
- [Severity]: STRENGTH
- [Finding]: The task decomposition is sensible and sequenced in a workable order.
- [Why]: Install/configure, fix mobile rendering, serve, then automate rebuilds is a practical implementation path that reduces debugging complexity.
- [Fix]: None.

- [F23]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Quartz v4 is the only free static site generator with native Obsidian syntax support (wikilinks, backlinks, tags, search)."
- [Why]: This is a comparative ecosystem claim that may be inaccurate or time-sensitive, and it is not grounded in the spec with evidence. Tool-selection claims should be verified or softened.
- [Fix]: Rephrase to something evidence-safe, e.g. "Quartz v4 is a suitable free static site generator with strong native support for Obsidian-style content" unless a comparative survey is added.

- [F24]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Quartz v4 is actively maintained (commits through March 2026, 11.7k GitHub stars)."
- [Why]: These are time-sensitive repository statistics that cannot be assumed correct without citation or live verification.
- [Fix]: Either cite the repository snapshot/date explicitly or remove the exact metrics and say "actively maintained as of evaluation date."

- [F25]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "iOS WebKit -- Known Quartz issues: missing margins, sidebar overflow, graph view WebKit crash. All fixable with CSS overrides or config."
- [Why]: This bundles multiple implementation claims and implied issue history without references. Some may be true, but they should not be treated as settled fact without validation.
- [Fix]: Split into:
  - observed/anticipated mobile rendering risks;
  - validation task on iPhone;
  - references to specific issue reports if available.
  Avoid asserting "all fixable" unless demonstrated.

---

### Summary by Category

**Correctness:** Mostly correct at the architectural level. Main concerns are underspecified implementation points: content ingestion, server binding, rebuild atomicity, and launchd semantics.

**Completeness:** Good overall, but missing essential operational details for: exact Quartz source strategy, exact web server choice/config, rebuild-safe deployment mechanics, logging/monitoring, attachment/embed validation, availability/freshness expectations.

**Internal Consistency:** Mostly consistent. Minor mismatch between "cron/watch" and scheduled rebuild model. Availability expectations around LaunchAgent vs reboot/login behavior need tightening.

**Feasibility:** Feasible and low-to-moderate risk. The likely hard parts are not scale but edge-case content handling and iPhone/WebKit polish.

**Clarity:** Clear and readable. Strong structure. A few sections should be made more explicit where they currently rely on implied implementation knowledge.

---

### Highest-Priority Fixes

1. Define exactly how Quartz reads the vault and applies exclusions.
2. Choose and specify one web server, including bind behavior and port.
3. Specify the atomic rebuild/deploy mechanism in concrete steps.
4. Clarify LaunchAgent vs LaunchDaemon and actual startup/availability expectations.
5. Add validation for embeds, attachments, Mermaid, and search performance on iPhone.
6. Replace or soften unverifiable comparative/tool-health claims.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the `vault-mobile-access` specification.

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Quartz v4 is the only free static site generator with native Obsidian syntax support"
- [Why]: There are several other free static site generators and frameworks (e.g., Astro with Digital Garden templates, Eleventy with Obsidian plugins) that natively support Obsidian wikilinks, backlinks, and frontmatter.
- [Fix]: Revise the claim to state that Quartz v4 is a "leading" or "highly optimized" free static site generator for Obsidian, rather than the "only" one.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Quartz v4 is actively maintained (commits through March 2026, 11.7k GitHub stars)"
- [Why]: The exact star count and future maintenance date (relative to current temporal context) cannot be independently grounded and will fluctuate.
- [Fix]: Remove the specific star count and date reference; rely on a general statement of "active community maintenance."

- [F3]
- [Severity]: CRITICAL
- [Finding]: Tailscale connection drops when the Mac Studio goes to sleep, defeating network wake-up.
- [Why]: Assumption A2 states the Mac Studio "wakes on network access." However, Tailscale runs locally on the Mac Studio. If the Mac Studio sleeps, its Tailscale client drops offline. A sleeping machine is disconnected from the tailnet and therefore cannot receive the Wake-on-LAN/network packets needed to wake it up via its Tailscale IP.
- [Fix]: Either mandate that the Mac Studio's sleep settings be changed to "Prevent computer from sleeping automatically when the display is off" (always-on), or introduce an always-on Tailscale Subnet Router (like an Apple TV or Raspberry Pi) on the same local network to proxy a physical Wake-on-LAN packet to the Mac Studio.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Missing Tailscale addressing strategy for the iPhone client.
- [Why]: The System Architecture notes `GET :8080`, but does not specify how the iPhone resolves the Mac Studio. If Tailscale MagicDNS is used, the URL would be `http://mac-studio:8080`. If not, it requires a static `100.x.x.x` Tailscale IP.
- [Fix]: Update the Architecture section and VMA-003 to explicitly define the local URL (e.g., MagicDNS hostname) to be bookmarked on the iPhone Chrome browser.

- [F5]
- [Severity]: MINOR
- [Finding]: The "atomic swap" requirement in VMA-004 lacks implementation definition.
- [Why]: `npx quartz build` outputs directly to the `public/` directory by default. Achieving zero-downtime atomic swaps requires a custom wrapper script to build to a temporary directory and then execute a swift directory `mv` operation.
- [Fix]: Expand VMA-004 to explicitly include writing a bash wrapper script (e.g., `build to public_temp/`, `mv public public_old`, `mv public_temp public`, `rm -rf public_old`) rather than just relying on the raw Quartz build command.

- [F6]
- [Severity]: MINOR
- [Finding]: Rebuild automation (VMA-004) relies on a scheduled cron interval rather than event-driven file watching.
- [Why]: A fixed 15-30 minute interval will result in unnecessary CPU usage when no changes have occurred, and introduces up to a 30-minute latency for mobile updates.
- [Fix]: Consider evaluating a filesystem watcher (like `fswatch` or a persistent `quartz build --serve` background process) to trigger builds only when files in the vault actually change.

- [F7]
- [Severity]: STRENGTH
- [Finding]: Pragmatic scoping of iOS WebKit constraints and aesthetic requirements.
- [Why]: Acknowledging known mobile Quartz bugs (margins, sidebar overflow, WebKit graph view crashes) upfront, defining CSS fixes as a distinct task (VMA-002), and intentionally deferring complex aesthetic overlays ensures the MVP remains highly focused and achievable without getting bogged down in design tweaks.

---

## DeepSeek (deepseek-reasoner)

Here is a structured review of the provided specification artifact.

### F1
- **Severity:** SIGNIFICANT
- **Finding:** Assumption A1 ("Tailscale is reliably connected") is noted but the validation step ("check Tailscale uptime on phone") is vague and insufficient for a specification. There is no defined mitigation for when Tailscale is *not* connected, which is a likely failure mode for mobile access.
- **Why:** The entire access path depends on this connection. The specification should address the user experience or contingency plan for when the VPN is unavailable.
- **Fix:** Add a section "Failure Modes & Mitigations" or expand Assumption A1 validation to include: "Define expected behavior when iPhone cannot reach Tailscale network (e.g., server unreachable, static error page)."

### F2
- **Severity:** SIGNIFICANT
- **Finding:** The specification lacks explicit configuration for the web server's listening interface and port. The architecture diagram shows port `:8080`, but the text does not specify binding to `localhost` versus all interfaces (`0.0.0.0`). Binding to all interfaces on a Tailscale node could be a security concern if not explicitly intended.
- **Why:** Binding to `0.0.0.0:8080` makes the server accessible on the Tailscale interface. Binding only to `127.0.0.1:8080` would require a reverse proxy. This ambiguity affects VMA-003 implementation.
- **Fix:** In the Architecture diagram or VMA-003 acceptance criteria, specify the listen address (e.g., `Web server (127.0.0.1:8080)` or explicitly state "binds to Tailscale IP/interface").

### F3
- **Severity:** SIGNIFICANT
- **UNVERIFIABLE CLAIM:** The claim "Quartz v4 is the only free static site generator with native Obsidian syntax support" and its activity status ("commits through March 2026, 11.7k GitHub stars") are presented as fact. While plausible, these are specific, un-cited assertions that require verification against the current ecosystem and GitHub repository.
- **Why:** Basing the core tool choice on an unverified claim about uniqueness and activity could lead to suboptimal selection if incorrect. The star count and commit recency are verifiable metrics that should be sourced.
- **Fix:** Reword to reflect this is the *evaluated* or *believed* best option based on research, or add a citation/link to the Quartz GitHub repository and a note on comparative analysis.

### F4
- **Severity:** SIGNIFICANT
- **Finding:** The fix for the known WebKit graph view crash ("Disabling on mobile avoids WebKit crash") is mentioned as a lever, but task VMA-002 only lists "Graph view disabled on mobile viewport widths" as an acceptance criterion without describing the method.
- **Why:** Disabling a core feature requires a technical implementation path (e.g., CSS `display: none`, conditional loading in Quartz layout, or a plugin setting). Its absence leaves a gap between the requirement and implementation.
- **Fix:** In VMA-002, add a brief note on the intended method (e.g., "via CSS media query targeting max-width, or Quartz configuration if available").

### F5
- **Severity:** MINOR
- **Finding:** The specification mentions "launchd plist or cron entry for the rebuild schedule" (VMA-004) and "LaunchAgent under `tess`" (VMA-003) but does not choose one consistently. Using both a LaunchAgent for the server and a cron job for rebuild is feasible but mixes scheduling systems.
- **Why:** Consistency in automation tools simplifies maintenance and logging. A mixed approach is not wrong, but the spec should explicitly state the chosen tools for each job.
- **Fix:** Clarify the choice: e.g., "Use LaunchAgent for the web server (persistent). Use a LaunchDaemon or cron job for periodic rebuilds, favoring cron for simplicity."

### F6
- **Severity:** MINOR
- **Finding:** The "System Map" lists "Caddy, `serve`, or similar" as web server options but does not provide a selection criterion or default choice.
- **Why:** Leaving this open-ended is acceptable for a specification, but for a task breakdown aimed at implementation, a recommended choice reduces ambiguity.
- **Fix:** Specify a default choice (e.g., "`serve` for simplicity, given low traffic and Node.js environment") in VMA-003 or add a note that selection will be based on a quick benchmark of ease-of-use vs. features.

### F7
- **Severity:** STRENGTH
- **Finding:** The "Content Scope" section is exceptionally well-defined, with a clear, justified table of included and excluded directories. This directly addresses potential problems with build performance and mobile noise.
- **Why:** This level of detail prevents scope creep, sets clear expectations for what will be visible, and provides a rationale that can be revisited if needs change.

### F8
- **Severity:** STRENGTH
- **Finding:** The task decomposition (VMA-001 to VMA-004) is logical, with appropriate risk assessments, dependencies, and clear, testable acceptance criteria. It follows a sound installation, configuration, serving, automation sequence.
- **Why:** This provides a direct, actionable implementation roadmap that aligns with the described architecture and manages complexity through phased dependencies.

### F9
- **Severity:** MINOR
- **Finding:** The specification states the vault is "accessible from a work laptop (drive mapping + SSH)" in the Problem Statement. This is a background fact but doesn't connect to the proposed solution. Leveraging the existing SSH access could be an alternative or complementary sync method.
- **Why:** It's a minor omission, but acknowledging why this existing path isn't suitable for mobile (e.g., SSH+browser complexity on iPhone, lack of a served HTML interface) would strengthen the rationale for the Quartz/web server approach.
- **Fix:** Add a sentence in "Why This Matters" or a new "Considered Alternatives" section noting that direct file access via SSH/FS is unsuitable for mobile browsing compared to a purpose-built web interface.

### Summary Assessment
**Correctness:** High. The technical approach (Quartz + static server + Tailscale) is sound for the read-only mobile access problem.
**Completeness:** Good. Major components and tasks are defined. Gaps exist in failure mode handling and some implementation details (F1, F2, F4).
**Internal Consistency:** Good. The tasks and architecture align. Minor inconsistency in automation tool mention (F5).
**Feasibility:** High. Uses established, maintained tools within the existing infrastructure (Node.js, Tailscale). Assumptions are reasonable and validatable.
**Clarity:** High. Well-structured, clear language, and good use of diagrams and tables. The purpose and scope are unambiguous.

---

## Grok (grok-4-1-fast-reasoning)

[F1]
[Severity]: SIGNIFICANT
[Finding]: UNVERIFIABLE CLAIM: "Quartz v4 is the only free static site generator with native Obsidian syntax support (wikilinks, backlinks, tags, search)"
[Why]: This absolute claim ("only free") cannot be confirmed without exhaustive survey of alternatives (e.g., Obsidian Digital Garden plugin, mkdocs-obsidian, or custom scripts); overstates uniqueness and risks misleading feasibility if competitors suffice.
[Fix]: Rephrase to "leading free option" or list verified competitors; add task to benchmark 1-2 alternatives.

[F2]
[Severity]: SIGNIFICANT
[Finding]: UNVERIFIABLE CLAIM: "Quartz v4 is actively maintained (commits through March 2026, 11.7k GitHub stars)"
[Why]: Future dates (2026) and specific metrics unverifiable now; if stale, undermines tool choice and A3 build time assumption.
[Fix]: Flag as "as of [last known date]" or add validation task to check repo status pre-install.

[F3]
[Severity]: CRITICAL
[Finding]: No tasks or steps to validate key assumptions (A1-A4) or resolve unknowns (U1-U3); e.g., no benchmarking for build time or FlexSearch size.
[Why]: Leaves core feasibility unproven; risks deployment failure (e.g., >2min builds overload CPU, unhandled WebKit crashes).
[Fix]: Add VMA-000: Pre-install validation task with subtasks for Tailscale uptime test, power settings check, benchmark build on subset/full vault, permissions audit, and content type sampling.

[F4]
[Severity]: SIGNIFICANT
[Finding]: Rebuild automation (VMA-004) lacks specifics on "atomic swap" implementation for zero-downtime (e.g., rsync to temp dir + symlink swap, or Node watcher like chokidar).
[Why]: Vague AC risks rebuild downtime (site 404s mid-build), contradicting "site remains available during rebuild"; high-traffic read use case amplifies.
[Fix]: Specify tool/method in AC (e.g., "Use `quartz build --output tmp/` then `mv tmp public` or launchd watcher"); reference example script.

[F5]
[Severity]: SIGNIFICANT
[Finding]: No handling for vault changes during rebuild (e.g., partial builds, inconsistent indexes) or error recovery (e.g., failed build leaves stale site).
[Why]: Frequent rebuilds (15-30min) on live vault risk corrupted mobile view; logs alone don't prevent user-facing issues.
[Fix]: Add AC: "Rollback to previous good build on failure; notify via email/slack on 3+ consecutive fails."

[F6]
[Severity]: SIGNIFICANT
[Finding]: Port :8080 hardcoded in diagram/architecture but unspecified in tasks/AC; no firewall/port-forward config for Tailscale.
[Why]: iPhone access fails without consistent port; Tailscale ACLs or macOS firewall may block.
[Fix]: Standardize port in VMA-003 AC (e.g., "Serves on Tailscale IP:8080"); add firewall allowance step.

[F7]
[Severity]: SIGNIFICANT
[Finding]: Multi-user filesystem constraint noted but unaddressed in tasks (e.g., if Danny != tess, access denied); LaunchAgent assumes single-user `tess`.
[Why]: Breaks access if non-tess login; contradicts "tess user can run" without explicit multi-access plan.
[Fix]: Add AC to VMA-003/VMA-004: "Read perms for group/other or ACL for Danny user"; clarify user mapping.

[F8]
[Severity]: MINOR
[Finding]: Content exclusion relies on "ignore patterns" in Quartz config, but no explicit patterns listed (e.g., `quartz.config.ts` glob for excluded dirs).
[Why]: Ambiguity risks including noise (e.g., .git leaks) or excluding wanted files; incomplete handoff to implementer.
[Fix]: Append table of exact glob patterns (e.g., `**/._system/scripts/**`, `**/.obsidian/**`) to VMA-001 AC.

[F9]
[Severity]: MINOR
[Finding]: No guidance on discovering Mac Studio's Tailscale IP from iPhone (e.g., Tailscale app shows peers, but not documented).
[Why]: Users may struggle with "GET :8080" without IP; minor UX friction for primary use case.
[Fix]: Add note/section: "Access via http://[mac-tailscale-ip]:8080; IP viewable in Tailscale iPhone app > Machines."

[F10]
[Severity]: MINOR
[Finding]: CSS fixes (VMA-002) list issues but no concrete selectors/code snippets (e.g., `@media (max-width: 768px) { .quartz-sidebar { overflow: hidden; } }`).
[Why]: Increases implementation time/debugging; "fixable with CSS" assumes dev familiarity.
[Fix]: Provide sample CSS file/link in AC or Design Note.

[F11]
[Severity]: MINOR
[Finding]: Excluded dirs like `_openclaw/inbox/` may contain readable content (unprocessed items); inclusion criteria vague ("system internals").
[Why]: Risks hiding useful mobile content; edge case for "knowledge base" needs.
[Fix]: Review/audit excluded dirs post-MVP; add toggle in Quartz config.

[F12]
[Severity]: STRENGTH
[Finding]: Task decomposition includes risks, dependencies, and testable AC with tags (e.g., `#code`).
[Why]: Enables parallel work, tracks progress; aligns with "full four-phase workflow."
[Fix]: N/A

[F13]
[Severity]: STRENGTH
[Finding]: Clear distinction of included/excluded content with table; levers/second-order effects proactively address tradeoffs.
[Why]: Reduces scope creep, anticipates pain points (e.g., CPU, load time); high completeness.
[Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. "Only free SSG" claim is unverifiable and likely inaccurate** (OAI-F23, GEM-F1, DS-F3, GRK-F1)
All four reviewers flagged the claim that Quartz v4 is the "only" free SSG with native Obsidian support. Gemini specifically named alternatives (Astro Digital Garden, Eleventy plugins). Should be softened.

**2. Maintenance metrics are time-sensitive and uncited** (OAI-F24, GEM-F2, DS-F3, GRK-F2)
All four flagged the "commits through March 2026, 11.7k stars" claim as unverifiable. Should reference evaluation date.

**3. Atomic rebuild mechanism underspecified** (OAI-F6, GEM-F5, GRK-F4)
Three reviewers noted the acceptance criteria require "atomic swap" without defining the implementation pattern (build-to-temp, rename, cleanup).

**4. Web server choice, bind address, and port not pinned** (OAI-F7/F8, DS-F2, GRK-F6)
Three reviewers noted the server selection is too vague for implementation. Bind address affects security posture (0.0.0.0 vs Tailscale IP vs localhost).

**5. Mac Studio sleep breaks Tailscale** (GEM-F3, OAI-F10)
Gemini rated this CRITICAL: if the Mac Studio sleeps, its Tailscale client goes offline and cannot receive connections. Wake-on-network doesn't help because the Tailscale tunnel is down. Must either prevent sleep or accept intermittent availability.

**6. LaunchAgent vs LaunchDaemon ambiguity** (OAI-F9, GRK-F7)
Two reviewers noted the spec says "LaunchAgent under tess" but doesn't address what happens after reboot if tess isn't logged in. Ties to the sleep/availability question.

**7. Tailscale addressing not specified** (GEM-F4, GRK-F9)
Two reviewers noted the spec doesn't define how the iPhone finds the Mac Studio — MagicDNS hostname or static Tailscale IP.

### Unique Findings

**OAI-F5: Content ingestion strategy missing** — Genuine insight. Quartz expects content in a specific directory structure. Whether we symlink, rsync, or configure the content root materially affects build behavior and exclusion handling. Should be addressed.

**OAI-F12: Binary asset/embed validation missing** — Genuine insight. Images, PDFs, Mermaid diagrams, and note embeds could break silently. Should add validation criteria.

**OAI-F15: No freshness SLO defined** — Genuine insight. "15-30 minutes" is mentioned but there's no explicit target. Useful for setting rebuild interval.

**GRK-F3: No assumption validation task** — Partially valid. A dedicated VMA-000 is overkill for this project size, but validation should be folded into VMA-001 acceptance criteria.

**GRK-F5: No error recovery for failed rebuilds** — Genuine insight. Failed build should fall back to last-good build, not leave a broken site.

**DS-F4: Graph view disable method unspecified** — Valid but minor. Implementation detail for VMA-002.

### Contradictions

**Rebuild trigger: cron vs file-watch.** GEM-F6 suggests fswatch for event-driven rebuilds; OAI-F16 says normalize to scheduled rebuild. Both are valid approaches. Cron is simpler and more predictable for MVP; file-watch is more responsive but adds complexity. Not a conflict — a design choice to make.

### Action Items

**A1 (must-fix)** — [OAI-F10, GEM-F3] Resolve Mac Studio sleep/availability. Either mandate "prevent sleep" in system requirements or accept intermittent access and document it.

**A2 (must-fix)** — [OAI-F5] Add content ingestion strategy: how Quartz reads the vault (symlink, config, or staged copy) and how exclusions are enforced in that mechanism.

**A3 (must-fix)** — [OAI-F7/F8, DS-F2, GRK-F6] Specify web server choice, bind address, port. One concrete decision, not a menu of options.

**A4 (should-fix)** — [OAI-F6, GEM-F5, GRK-F4] Define the atomic rebuild mechanism concretely: build to temp dir, validate, rename swap.

**A5 (should-fix)** — [OAI-F23, GEM-F1, DS-F3, GRK-F1] Soften "only free SSG" claim to "leading free SSG with strong Obsidian support."

**A6 (should-fix)** — [OAI-F24, GEM-F2, DS-F3, GRK-F2] Replace specific metrics with "actively maintained as of evaluation (April 2026)."

**A7 (should-fix)** — [GEM-F4, GRK-F9] Specify Tailscale addressing: MagicDNS hostname or static IP for the iPhone bookmark.

**A8 (should-fix)** — [OAI-F9, GRK-F7] Clarify LaunchAgent (requires tess login) vs LaunchDaemon. Ties to A1.

**A9 (should-fix)** — [OAI-F12] Add acceptance criteria for content type validation: images, embeds, Mermaid, backlinks, tag pages.

**A10 (should-fix)** — [GRK-F5] Add rollback-to-last-good-build on failure to VMA-004 acceptance criteria.

**A11 (defer)** — [OAI-F15] Freshness SLO. Set during implementation based on actual build times.

**A12 (defer)** — [OAI-F14] Logging paths. Implementation detail for VMA-003/004.

**A13 (defer)** — [DS-F1] Failure mode for Tailscale disconnection. Standard browser "unreachable" behavior; no special handling needed.

### Considered and Declined

- **OAI-F13** (URL/path behavior for special filenames) — `overkill`. Quartz handles this or it surfaces organically during testing.
- **OAI-F18** (service registration schema reference) — `constraint`. project-state.yaml is a Crumb convention understood by the implementer.
- **OAI-F19** (aesthetic section as backlog items) — `overkill`. The design note serves its purpose as-is.
- **DS-F9** (SSH alternative rationale) — `out-of-scope`. Spec context is clear; alternatives were evaluated in conversation.
- **GRK-F8** (explicit glob patterns in spec) — `overkill`. Implementation detail for VMA-001.
- **GRK-F10** (CSS code snippets in spec) — `overkill`. Implementation detail for VMA-002.
- **GRK-F11** (excluded dirs audit post-MVP) — `out-of-scope`. Can revisit after deployment if needed.
