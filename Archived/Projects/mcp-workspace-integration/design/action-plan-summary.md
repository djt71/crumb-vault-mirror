---
type: action-plan-summary
domain: software
status: active
project: mcp-workspace-integration
skill_origin: action-architect
created: 2026-03-16
updated: 2026-03-16
source_updated: 2026-03-16
---

# MCP Workspace Integration — Action Plan Summary

## Structure

4 milestones, 13 tasks, spike-gated progression.

## Milestones

1. **Spike (MWI-001 to MWI-003):** Install MCP server, validate 6 services on Crumb, decision gate for email triage migration architecture. ~1-2 sessions.
2. **Tess Integration (MWI-004 to MWI-006):** Configure OpenClaw MCP, validate concurrent access, resolve transport architecture. ~1 session.
3. **Email Triage Migration (MWI-007 to MWI-010):** Migrate email-triage.sh and daily-attention.sh, 48-hour parallel validation, retire gws CLI. ~2 sessions.
4. **Stabilization (MWI-011 to MWI-013):** Update docs, update ADR §2.2, 7-day soak. ~1 session + soak period.

## Critical Path

Spike → gate → Tess integration → transport decision → migration → parallel validation → soak.
MWI-009 (daily-attention migration) runs parallel with MWI-007. MWI-012 (ADR update) can run anytime after spike.

## Key Gates

- **MWI-003:** Go/no-go after spike. Blocks all downstream work.
- **MWI-006:** Transport architecture decision. Informs how migration scripts connect to MCP.
- **MWI-008:** Parallel validation pass. Must achieve ≥95% classification parity before retiring gws CLI.
- **MWI-013:** 7-day soak. Zero auth failures required before project completion.

## Risk Profile

One high-risk task (MWI-007 — email triage migration), five medium, seven low. Highest risk is mitigated by the decision gate and 48-hour parallel validation.

## Estimated Timeline

5-7 sessions across 2-3 weeks, plus 7-day soak. Anthropic off-peak promo (through March 28) provides cost headroom for spike and early integration work.
