---
type: reference
domain: null
status: snapshot
skill_origin: null
created: 2026-04-21
updated: 2026-04-21
source: liberation-directive.md v1.1 (2026-03-19)
tags:
  - directive
  - architecture-snapshot
---

# Liberation Surfaces — Architecture Snapshot

**Status:** Snapshot extracted from liberation-directive.md v1.1 (2026-03-19) on 2026-04-21. Preserved verbatim for later revision — surfaces, credit assumptions, and rollout details are frozen in time and likely stale. Do not treat this as a live architecture description; cross-check against current reality before acting on anything here.

**Why extracted:** The liberation directive is a strategic directive — mission, priorities, prompts, metrics. System architecture (surfaces, models, connectors, credit budgets) doesn't belong in the same doc. Extracted pending a review that will decide what — if any — of this content should be rewritten, updated, or retired.

---

## Architecture: The Four-Surface Model

Crumb/Tess operates across four distinct agent surfaces, each optimized for a specific type of work. A fifth (Perplexity Personal Computer) is under evaluation.

### Surface 1: Crumb (Deep Work Executor)
- Runs on Claude (Opus/Sonnet) via Claude Code
- Handles: strategy, market analysis, spec writing, creative direction, code generation, peer review synthesis
- **All six prompts below are initiated as Crumb sessions**
- Can dispatch browser tasks via Claude Code `--chrome` flag
- Output: specs, plans, artifacts that live in the vault
- Cadence: on-demand deep work sessions, each producing a defined deliverable

### Surface 2: Tess (Always-On Orchestrator)
- Runs on Haiku via OpenClaw as LaunchDaemon on Mac Studio M3 Ultra
- Handles: daily execution against approved specs, monitoring, digests, routine production tasks
- **Tess receives standing orders derived from Crumb-produced specs**
- Does NOT do: strategic planning, market analysis, creative direction, or anything requiring deep reasoning
- Cadence: continuous, with daily reporting via Telegram

### Surface 3: Claude in Chrome (Authenticated Browser Agent)
- Chrome extension, available on all paid Claude plans (Haiku on Pro, Sonnet/Opus on Max)
- Handles: actions on websites using Danny's logged-in sessions — KDP publishing, account management, form filling, development testing via Claude Code `--chrome`
- Can record workflows as reusable shortcuts and run them on a schedule (daily/weekly/monthly)
- **Consumes Claude usage allocation** — competes with Crumb for credits
- Does NOT have vault access — Crumb/Tess must bridge this gap
- Best for: authenticated site operations, development testing, scheduled browser workflows

### Surface 4: Perplexity Comet (Research Browser)
- Standalone Chromium browser on separate Perplexity subscription
- Handles: open-web research, competitive intel, market scanning, price comparison, multi-site data gathering
- **Runs on separate credit pool** — does not compete with Claude usage
- Does NOT have vault access or Claude Code integration
- Privacy note: Perplexity collects browsing history for ad targeting. Do not route sensitive or authenticated work through Comet.
- Best for: quick research tasks, browsing-based investigation, agentic search

### Surface 5: Perplexity Computer (Multi-Agent Orchestrator)
- Cloud-based multi-agent platform orchestrating 19+ frontier models (Claude Opus 4.6 for reasoning, Gemini for research, GPT-5.2 for long-context, Grok for lightweight tasks, plus image/video models)
- **Active — Danny is on Perplexity Max ($200/month). 10,000 monthly credits + 35,000 bonus credits (expiring ~30 days from activation).**
- Handles: parallel multi-source research, market analysis, competitive intelligence, structured report generation, document/slide/app creation, scheduled jobs, condition-based monitoring triggers
- Sub-agent orchestration: Computer decomposes objectives into tasks, spawns specialized sub-agents, routes to optimal model per subtask
- 400+ app connectors: Gmail, Outlook, GitHub, Slack, Notion, and more (connector reliability varies — treat auth issues as normal troubleshooting)
- Skills system: reusable instruction sets (built-in + custom) that auto-activate based on task type
- Persistent memory across sessions. Sandboxed execution (2 vCPU, 8GB RAM, Python/Node.js/ffmpeg)
- Can run dozens of Computer instances in parallel on different projects
- **Vault access via Google Drive connector.** The full Obsidian vault is synced to Google Drive (existing sync mechanism, widened). Computer has read access to all ~1,400 files. It only pulls what's relevant to a given task — no need to curate a subset. Set up before first Computer tasks (see Day 0 in Danny's Week 1 Actions).
- **Credit cost is unpredictable.** Simple tasks ~40 credits, research ~50-70, automations 100+. Monitor consumption closely during bonus window to calibrate.
- **Known risk: runaway credit consumption.** Computer can chase its tail on failed tasks without stopping. Set spending caps. Monitor active tasks.
- Best for: research-heavy discovery, market scanning, competitive analysis, multi-step workflows that don't need vault context

### Pending: Perplexity Personal Computer
- Always-on software running on dedicated Mac, merging local files/apps with Perplexity Computer's cloud AI orchestration
- **Danny is on the waitlist.** When access opens, evaluate immediately.
- Bridges the biggest gap: Computer + local file access (including vault, if configured)
- Could serve as a second always-on agent alongside Tess — different model stack, different strengths
- Requires hands-on evaluation of: actual autonomy level, local file access quality, vault integration feasibility, and whether it adds capability Tess can't provide

### The Composition Pattern
```
Crumb thinks and specs → Computer researches and discovers →
Tess monitors and executes routine tasks →
Chrome acts on authenticated sites → Comet browses the open web →
Cowork produces polished deliverables → Danny reviews and decides
```

### Surface Selection Guide

| Work Type | Primary Surface | Why |
|-----------|----------------|-----|
| Strategy, specs, planning | Crumb | Deep reasoning, vault context, model flexibility |
| Daily execution, monitoring, digests | Tess | Always-on, cheap (Haiku), routine work |
| Parallel market research, competitive intel | Computer | 19-model orchestration, parallel search, sub-agents |
| Opportunity scanning and validation | Computer | Multi-source synthesis, scheduled jobs, condition triggers |
| KDP publishing, account setup, dev testing | Chrome | Authenticated sessions, Claude Code bridge |
| Quick web research, browsing investigation | Comet | Lightweight, separate from Claude credits |
| Polished documents, spreadsheets, presentations | Cowork | Professional output formatting |
| Code writing + browser verification | Crumb + Chrome | Claude Code `--chrome` flag |
| Research → finished deliverable | Computer → Cowork | Research layer feeds production layer |

### Handoff Pattern
```
Crumb Session → Spec/Plan (vault artifact) → Danny Review → Approved? → Tess Standing Order → Daily Execution → Tess Reports Progress → Danny Reviews → Course Corrections via Crumb
```

Computer operates in parallel to this pattern — it runs discovery and research tasks independently, feeding results into Crumb sessions as input context. Browser surfaces (Chrome, Comet) are dispatched as needed within any phase. Cowork receives output from any surface for polishing.

---

## Credit Budget Awareness

During the bonus window (~45,000 total credits):
- Allocate ~15,000 to Prompts 2 + 4 (initial discovery scans)
- Allocate ~5,000 to Prompt 3 simulation
- Allocate ~5,000 to calibration and experimentation
- Reserve ~20,000 as buffer for iteration and unexpected tasks

After bonus expires (10,000 credits/month):
- Weekly Prompt 2/4 refreshes: budget ~2,000/month
- Scout-related Computer tasks: budget ~1,500/month
- Ad hoc research: budget ~3,000/month
- Buffer: ~3,500/month
- Monitor actual consumption against these targets. Adjust after first full month of real data.

---

## Day 0 Prep — Give Computer Vault Access and Calibrate

A Google Drive sync mechanism already exists (used for NotebookLM Crumb documentation). Widen it to the full vault:

1. Sync the entire Obsidian vault to Google Drive. Markdown files are tiny — the full ~1,400 files are likely under 100MB. No curation needed; Computer only reads the files relevant to a given task.
2. In Perplexity Settings → Connectors, enable Google Drive and point it at the vault folder.
3. Verify Computer can read the files by asking it a simple question about the design spec.
4. **Calibration task:** Run one small, bounded research task on Computer before committing three prompts to it. Example: ask it to analyze the competitive landscape for one specific public domain title on KDP, using vault context. Observe: credit cost, output quality, vault access reliability, response time. If the output is poor or credits burn unexpectedly fast, scale back to one Computer prompt in Week 1 instead of three.

This is not a new infrastructure project — it's pointing an existing sync mechanism at a broader folder and verifying the tool works before depending on it.
