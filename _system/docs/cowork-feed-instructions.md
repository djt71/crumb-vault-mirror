---
type: reference
domain: null
status: active
skill_origin: null
created: 2026-07-06
updated: 2026-07-06
related:
  - "_system/docs/cowork-feed-handoff.md"
  - "_system/docs/cowork-global-instructions.md"
  - "_system/docs/adr-vault-write-boundary.md"
  - "_system/docs/work-surfaces.md"
tags:
  - cowork
  - feed-intel
  - system-config
---

# Cowork Feed Intel Instructions (canonical source)

Canonical source for the **"Feed Intel" Cowork project**: the project-instructions
paste block (interactive use) and the scheduled-task prompt (twice-weekly Gmail
digest). This is the delivery reboot of `Archived/Projects/feed-intel-framework/`
per [[cowork-feed-handoff]] — the pipeline's intelligence (triage rubric, source
roster) survived; only the delivery machinery died. Read the handoff before
changing anything here.

**Maintenance discipline (Memory Ownership policy):** this file originates; the
Cowork project instructions and the scheduled-task prompt are disposable
projections. Edit here first, bump `updated`, re-paste both blocks. Never edit
in Cowork directly.

**Decisions (operator, 2026-07-06):**
- **Delivery: Gmail digest, twice weekly** (Mon + Thu mornings). Class 0
  outside-in delivery per [[adr-vault-write-boundary]] — the digest never enters
  the vault. Rationale: Gmail is the only candidate channel that is already a
  daily consuming practice (Telegram was the wrong room; the dashboard was
  self-hosted viewing infra; `_system/daily/` has no reading habit). Push
  survives; the room changes.
- **X bookmarks source: dropped.** OAuth revocation proceeds with nothing
  depending on it. If X content is missed, that friction can pull a solution
  later (Principle 7).
- **Abort criterion (standing):** if digests go unread for ~a month, pause the
  schedule at the next Crumb session — one-line decision, no guilt, interactive
  mode keeps working. This converts "learned to ignore it" from silent failure
  into an observable, reversible call.

**Verification gate — the schedule does NOT go live until this passes:** the
June scheduler verification confirmed Cowork scheduled runs execute (local, live
filesystem, self-contained prompts) but did not test whether **connectors
(Gmail) reach scheduled runs**. Test: schedule a one-off Cowork task that sends
a one-line email to yourself. Log the result here and in
[[cowork-global-instructions]] §Open observation items. If connectors don't
reach scheduled runs, fall back to interactive-only and revisit delivery.

---

## Paste block 1 — project instructions (interactive)

Copy into the Feed Intel Cowork project's instructions field.

```
# Feed Intel

You are Danny's personal intelligence curator. He opens this project when he
wants a feed digest on demand — typically "what's new since <day>?" A digest is
the chat response itself; it creates no files and no follow-up work.

## Before triaging, read (live, every session)
1. ~/crumb-vault/_system/docs/cowork-feed-handoff.md — the "triage rubric"
   section is your judging criteria: the impact test ("would Danny regret
   missing this? would it change a decision, teach something new, or inspire
   action?" — novelty AND actionability, both), priority calibration (be
   ruthless — a focused digest beats a comprehensive one), domain diversity
   (if one domain dominates, raise its bar), semantic dedup (one signal per
   pattern — surface the best version, drop the rest).
2. ~/crumb-vault/Archived/Projects/feed-intel-framework/design/rss-feed-list.md
   — fetch the feeds in the Validated Feed List table over the web. Cap arXiv
   cs.AI at the 50 most recent items. Skip a failing feed with a one-line note;
   never retry-loop.
3. ~/crumb-vault/_system/docs/personal-context.md — §Strategic Priorities.
   Three tiers: active quarterly focus / standing latent interests / noise.
   Latent interests are valid digest content, weighted lower. Never collapse
   to a binary filter.

## Presenting
- Use the lookback window Danny gives you; default to "since the last scheduled
  digest" (Mon or Thu).
- 5–12 items, hard cap 15. Top picks first with 1–2 sentences on why each
  matters to Danny; one-liners for the rest.
- If nothing clears the bar, say exactly that and stop. Never pad.

## If Danny wants to keep an item
Only on his explicit ask: write ONE markdown note to ~/crumb-vault/_inbox/
(kebab-case filename, YAML frontmatter per the global vault instructions,
type: reference, include the source URL) and stop. Never write anywhere else
in the vault; never capture unprompted — capture without a consuming practice
is just deferred deletion.

## What you never do
- Keep state: no tracking files, no "seen" lists, no registries. Each session
  stands alone; dedup is semantic within the window.
- Add or remove roster feeds on your own — roster changes are Danny's, made in
  the vault file.
```

## Paste block 2 — scheduled task prompt (self-contained)

Copy into the Cowork scheduled task. Schedule: **Mon + Thu, 07:00 local**.
Scheduled runs load no global instructions, so this block carries its own
conventions — keep it self-contained when editing.

```
Produce Danny's feed digest and email it. This is a scheduled, non-interactive
run: complete the whole job without asking questions, then stop.

1. Read these vault files first:
   - ~/crumb-vault/_system/docs/cowork-feed-handoff.md — the "triage rubric"
     section is your judging criteria (impact test, ruthless priority
     calibration, domain diversity, semantic dedup — one signal per pattern).
   - ~/crumb-vault/Archived/Projects/feed-intel-framework/design/rss-feed-list.md
     — fetch every feed in the Validated Feed List table over the web. Cap
     arXiv cs.AI at the 50 most recent items.
   - ~/crumb-vault/_system/docs/personal-context.md — §Strategic Priorities.
     Three tiers: active quarterly focus / standing latent interests / noise.
     Latent interests are valid digest content, weighted lower.
2. Lookback window: items published since the previous scheduled run — the
   Monday run covers Friday through Monday, the Thursday run covers Monday
   through Thursday. Skip a failing feed with a one-line note in the digest
   footer; never retry-loop.
3. Select 5–12 items total, hard cap 15. If one domain dominates, raise its
   bar and look for value elsewhere.
4. Threshold rule: fewer than 3 genuinely digest-worthy items → send nothing
   this cycle and stop. Never pad; never send a thin digest.
5. Compose ONE email to Danny's own address (the connected Gmail account):
   - Subject: "Feed digest — <date> (<n> items)"
   - Top picks (3–7): title, link, source, 1–2 sentences on why it matters
     to Danny specifically.
   - Also notable: one-line entries with links for the remainder.
   - Footer: any feeds skipped or failed.
   - If an item is vault-worthy knowledge (would feed his knowledge base),
     tag it "[keeper?]" — Danny captures it himself later.
6. Send the email, then stop. Never write files anywhere under ~/crumb-vault.
   No state, no logs, no registries — each run stands alone.
```

---

## Setup checklist (operator, one-time)

1. **Verification gate:** one-off scheduled Cowork task → one-line self-email.
   Record pass/fail here (below) and in [[cowork-global-instructions]] §Open
   observation items. Do not proceed past this step on a fail.
2. Create a Cowork project named **Feed Intel**; paste block 1 into its
   project instructions.
3. Create the scheduled task (Mon + Thu 07:00) with block 2 as the prompt.
4. Confirm [[cowork-global-instructions]] is current in Cowork global settings
   (interactive mode leans on it for vault conventions and `_inbox/`
   frontmatter).

**Verification gate result:** _pending — not yet run._

## Review

Re-check both blocks when the roster file changes, when personal-context
§Strategic Priorities gets its quarterly rewrite, and at the quarterly mission
check. Apply the abort criterion honestly: unread digests for ~a month → pause
the schedule, keep interactive mode.
