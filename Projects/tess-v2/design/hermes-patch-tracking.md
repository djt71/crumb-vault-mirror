---
type: reference
status: active
domain: software
project: tess-v2
created: 2026-04-01
updated: 2026-04-09
---

# Hermes Agent — Local Patches

## Patches (on branch `fix/thinking-model-reasoning-field`)

Originally bundled in **#4467** (closed 2026-04-01 by teknium1 on "retry loop is intended behavior" grounds). Upstream landed a softer version of the reasoning-field fix via the salvage chain below; the KeepAlive fix was never picked up.

### 1. Thinking model reasoning field early exit — PARTIALLY SUPERSEDED

- **File:** `run_agent.py` (~line 7920)
- **Original PR:** [#4467](https://github.com/NousResearch/hermes-agent/pull/4467) — closed 2026-04-01, not merged
- **Upstream resolution:** landed in [#4645](https://github.com/NousResearch/hermes-agent/pull/4645) (merged 2026-04-02, shipped in v0.7.0 / v2026.4.3) via salvage chain `#4467 → #4552 → #4645`. teknium1 himself cherry-picked @kshitijk4poor's #4552 rework onto main, crediting the original author. The v0.7.0 release note *"Think-only empty response classification prevents infinite retry loops"* is this fix.
- **Semantic difference:** #4645 uses a classifier (`_classify_empty_content_response`), not a blanket early-exit. It salvages reasoning only when (a) local/custom backend + context pressure signal, OR (b) the same structured reasoning payload repeats unchanged (2nd identical response). Preserves the normal 3-retry path for one-off thinking-model responses — which was teknium1's stated concern on closing #4467.
- **For Tess-v2's Kimi workload (OpenRouter, cron-triggered, analytical prompts):** stock v0.7.0+ should salvage on the 2nd identical reasoning payload within a single invocation, reducing wasted API calls from **3 → 1 per invocation**, not 3 → 0 like the original #4467 patch. Heartbeat/simple prompts unaffected either way.
- **Decision pending:** whether 1 wasted Kimi call per cron run is acceptable, or whether to reapply the original early-exit as a delta on top of the #4645 classifier. Requires a short soak on stock v0.7.0+ to confirm actual behavior.
- **Fork:** `djt71/hermes-agent` — still holds the original early-exit delta, kept for potential re-use as a delta on top of the classifier.

### 2. Unconditional KeepAlive in LaunchAgent plist — STILL OUT-OF-TREE

- **File:** `hermes_cli/gateway.py` (~line 871)
- **Original PR:** bundled in #4467 — never salvaged. #4552 and #4645 are purely `run_agent.py` / reasoning-field changes and don't touch `gateway.py`.
- **What:** Changed `KeepAlive` from `SuccessfulExit: false` to unconditional `true`. Gateway now restarts after clean exits, not just crashes.
- **Upstream status (as of v0.8.0 / v2026.4.8):** no merged PR found addressing this specifically. v0.8.0's "9 community bugfixes (gateway, cron, macOS launchd)" may or may not touch line 871 — needs a post-upgrade diff to confirm.
- **Action:** reapply after every `hermes update` until landed upstream. A focused follow-up PR (smaller scope than #4467, no philosophical objection available) is queued as an idea but not yet drafted.

## Kimi K2.5 Model Behavior — reasoning_content is Default Mode

Confirmed via direct API test (`max_tokens:10`, prompt: "Say OK"): Kimi K2.5 returns
`content: null` with **all** tokens in the `reasoning` / `reasoning_content` field. This
is not prompt-dependent or analytical-prompt-specific — it is the model's fundamental
response structure through OpenRouter. Every Kimi interaction goes through the reasoning
field path.

**Implications for Tess v2:**
- The Hermes patch (#4467) is not a workaround for edge cases — it's required infrastructure
  for Kimi as orchestrator. Without it, every single Kimi response triggers 3 wasted retries.
- Any future integration consuming Kimi responses must read `reasoning_content`, not `content`.
- If Hermes is replaced or bypassed (e.g., direct `claude --print` bridge to OpenRouter),
  the consumer must handle this field mapping.

## OpenRouter Streaming Stall (Observed)

One occurrence during soak: gateway at 0% CPU for 12+ minutes after Kimi read 3 JSON files.
Likely cause: SSE connection from OpenRouter didn't close cleanly after Kimi finished
thinking. Kimi was responsive to direct API calls during the stall (1.4s round-trip).

**Mitigations:**
- Hermes default timeout is 1800s — generous enough to let stalls sit. Consider lowering
  for cron jobs if this recurs.
- Heavy analytical prompts (multiple file reads + synthesis) maximize stall exposure.
  Smaller sequential checks may be more reliable than single-pass multi-file analysis.
- Not a blocker — single occurrence in 48h soak on an unusually heavy prompt.

## Before Running `hermes update`

**Updated 2026-04-09 after the #4645 salvage chain was traced.**

Patch #1 (reasoning field) is partially upstream as of v0.7.0 via #4645 — don't blindly cherry-pick the old delta on top, because the classifier and your early-exit would overlap. Patch #2 (KeepAlive) is still out-of-tree and always needs reapply.

### Procedure

1. **Before update — capture baseline:**
   ```
   cd ~/.hermes/hermes-agent
   git log --oneline fork/fix/thinking-model-reasoning-field ^main | head
   grep -n 'reasoning_content\|SuccessfulExit' run_agent.py hermes_cli/gateway.py
   ```
2. **Run `hermes update`.**
3. **Verify the #4645 classifier landed:**
   ```
   grep -n '_classify_empty_content_response' run_agent.py
   ```
   Should match. If not, the update regressed or this tracking note is stale.
4. **Diff `hermes_cli/gateway.py` for KeepAlive:**
   ```
   grep -n -A 3 'KeepAlive' hermes_cli/gateway.py
   ```
   If still `SuccessfulExit: false` → reapply the KeepAlive patch from the fork branch.
5. **Patch #1 decision (requires soak data on stock):**
   - Run a short Kimi analytical-prompt soak on stock v0.7.0+ and count wasted retries per invocation (should be 1, per the classifier semantics above).
   - If 1 retry/invocation is acceptable → drop patch #1, keep the fork branch archived for reference.
   - If not → cherry-pick only the `run_agent.py` reasoning-field early-exit as a *delta on top of* the #4645 classifier, not as a replacement for it.
6. **Restart gateway** and confirm Kimi behavior with a heartbeat + one analytical prompt.
