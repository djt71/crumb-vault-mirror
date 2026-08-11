---
type: reference
status: active
domain: software
project: tess-v2
created: 2026-04-01
updated: 2026-04-16
---

# Hermes Agent — Local Patches

## Patches (on branch `fix/thinking-model-reasoning-field`)

Originally bundled in **#4467** (closed 2026-04-01 by teknium1 on "retry loop is intended behavior" grounds). Upstream landed a softer version of the reasoning-field fix via the salvage chain below; the KeepAlive fix was never picked up.

### 1. Thinking model reasoning field early exit — SUPERSEDED (v0.9.0)

- **File:** `run_agent.py` (~line 10880 in v0.9.0)
- **Original PR:** [#4467](https://github.com/NousResearch/hermes-agent/pull/4467) — closed 2026-04-01, not merged
- **Upstream resolution chain:** `#4467 → #4552 → #4645` (v0.7.0 classifier) → refactored in v0.9.0 into a multi-stage empty-response handler:
  1. Partial stream recovery (use already-streamed content)
  2. Prior-turn content fallback (housekeeping tool turns)
  3. Post-tool empty nudge (one retry with continuation prompt)
  4. **Thinking-only prefill continuation** — detects `reasoning`/`reasoning_content`/`reasoning_details` fields, appends assistant message as-is and continues so model sees its own reasoning on next turn. Up to 2 prefill retries.
- **v0.7.0's `_classify_empty_content_response`** was removed by v0.9.0 — replaced by the prefill continuation approach above.
- **For Tess-v2's Kimi workload:** stock v0.9.0 allows up to 2 prefill retries (down from 3 bare retries in v0.6.0). The model sees its own reasoning on each continuation, so subsequent attempts are more likely to produce visible content. Wasted calls: **0–2 per invocation** depending on whether Kimi produces visible text on the prefill turn.
- **Decision: CLOSED.** Stock v0.9.0 handling is sufficient. The fork branch (`djt71/hermes-agent`, branch `fix/thinking-model-reasoning-field`) is archived for reference only — do not reapply.
- **Fork:** `djt71/hermes-agent` — archived, 1 commit ahead of v0.6.0 main (no longer relevant).

### 2. Unconditional KeepAlive in LaunchAgent plist — STILL OUT-OF-TREE

- **File:** `hermes_cli/gateway.py` (line 1363 in v0.9.0)
- **Original PR:** bundled in #4467 — never salvaged upstream.
- **What:** Changed `KeepAlive` from `SuccessfulExit: false` to unconditional `true`. Gateway now restarts after clean exits, not just crashes.
- **Upstream status (as of v0.9.0 / v2026.4.13):** still `SuccessfulExit: false` in stock. Not addressed by v0.8.0 or v0.9.0 gateway fixes.
- **Action:** reapply after every `hermes update` until landed upstream. Last reapplied: **2026-04-16 (v0.9.0 update)**.
- A focused follow-up PR (smaller scope than #4467, no philosophical objection available) is queued as an idea but not yet drafted.

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

**Updated 2026-04-16 after v0.6.0 → v0.9.0 upgrade.**

Patch #1 (reasoning field) is fully superseded — stock v0.9.0's multi-stage handler covers Kimi's thinking-only responses. Patch #2 (KeepAlive) is the only remaining out-of-tree patch.

### Procedure

1. **Before update — capture baseline:**
   ```
   cd ~/.hermes/hermes-agent
   grep -n -A 3 'KeepAlive' hermes_cli/gateway.py
   ```
2. **Run `hermes update`.**
3. **Verify thinking-only handling still present** (sanity check — should see `_thinking_prefill_retries`):
   ```
   grep -n '_thinking_prefill_retries' run_agent.py
   ```
4. **Diff `hermes_cli/gateway.py` for KeepAlive:**
   ```
   grep -n -A 3 'KeepAlive' hermes_cli/gateway.py
   ```
   If still `SuccessfulExit: false` → edit line ~1363: replace the `<dict>...<false/>...</dict>` block with `<true/>`.
5. **Restart gateway** (`hermes gateway restart`) and confirm Kimi heartbeat (`hermes chat -q "Say OK" -m moonshotai/kimi-k2.5 --max-turns 1`).

### Update Log

| Date | From | To | Patches reapplied | Notes |
|------|------|----|--------------------|-------|
| 2026-04-16 | v0.6.0 (v2026.3.30) | v0.9.0 (v2026.4.13) | KeepAlive only | Patch #1 closed — stock prefill handler sufficient. 1377 commits, 3 releases. Kimi heartbeat confirmed. |
