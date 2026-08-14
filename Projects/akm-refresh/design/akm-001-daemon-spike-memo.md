---
project: akm-refresh
domain: software
type: design
skill_origin: null
created: 2026-08-14
updated: 2026-08-14
topics:
  - moc-crumb-architecture
tags:
  - akm
  - spike
  - design
---

# AKM-001 — Daemon Latency Spike: Decision Memo

Staged spike per `staged-spike-with-bail.md`. All measurements on installed qmd 2.5.3 (18185ee497), index at 1,607 docs, Mac Studio, 2026-08-14. Raw probe artifacts in session scratchpad (not retained); all numbers reproduced below.

## Stage-0 verdict: PASS — daemon exists, no bail

`qmd --help` (local, primary source) lists: *"Advanced: `qmd mcp --http ...` and `qmd mcp --http --daemon` are optional for custom transports."* Confirmed live:

- `qmd mcp --http` → foreground server, `http://localhost:8181/mcp`
- `qmd mcp --http --daemon` → detached daemon (re-execs itself with explicit `--port 8181`), logs to `~/.cache/qmd/mcp.log`
- `--port <n>` supported (surfaced by the bind-failure error message; not in `--help`)

## Daemon interface (what AKM-002/003 will build against)

MCP **streamable HTTP** (JSON-RPC) at `/mcp`. Handshake: `initialize` → capture `mcp-session-id` response header → `notifications/initialized` → `tools/call`. Four tools: `query`, `get`, `multi_get`, `status`.

The `query` tool covers every wrapper need natively:
- `searches[]` — typed sub-queries (`lex` | `vec` | `hyde`), 1–10 lines, first gets 2× weight → **mode selection = line composition** (lex-only ≈ BM25, vec-only ≈ vector, lex+vec = hybrid). This is the structured-query replacement for the groups-of-3 splitting hack (F4).
- `rerank` (default true) — the latency lever; `minScore` — floor support; `collections[]` — server-side KB scoping; `limit`; `intent`; `candidateLimit`.

## Operational findings (three hazards, all wrapper-relevant)

1. **False-success on bind failure.** With the port already held, `qmd mcp --http --daemon` printed `Started on http://localhost:8181/mcp (PID …)` and **exited 0**; the real error (`Port 8181 already in use. Try a different port with --port.`) went only to `~/.cache/qmd/mcp.log`. Daemon startup MUST be verified by a health probe (e.g. `initialize` round-trip), never by stdout/exit code.
2. **Orphan child on parent kill.** Killing a foreground `qmd mcp --http` parent left the actual server child alive (reparented to PPID 1, still holding the port). Lifecycle management must target the listener (e.g. `lsof -t -iTCP:8181 -sTCP:LISTEN`), not the launcher PID.
3. **Down-daemon failure is clean and instant.** Connection refused in ~30ms (curl exit 7). A daemon-alive check costs effectively nothing → degrade-to-CLI fallback is cheap to trigger inline.

Also observed: identical repeated queries hit a **result cache** (~100ms for an otherwise ~640ms rerank query) — benign for production, but latency measurements must use distinct queries (the first timing pass here was invalidated by this).

## Latency matrix (warm, distinct queries)

**Daemon transport** (10 distinct queries per mode, MCP `tools/call` round-trip):

| mode | p50 | p95 |
|---|---|---|
| lex only, no rerank (≈BM25) | 13ms | 18ms |
| vec only, no rerank (≈vector) | 80ms | 80ms |
| lex+vec, no rerank | 87ms | 91ms |
| lex+vec, **rerank** | 642ms | 1,292ms |

**CLI transport** (fresh process per call, distinct queries):

| invocation | warm timing |
|---|---|
| `qmd search` (BM25) | ~155ms |
| `qmd vsearch` | 0.7–1.9s (unstable; model load per invocation) |
| `qmd query 'lex:…\nvec:…' --no-rerank` | ~630–650ms (very stable) |
| `qmd query 'lex:…\nvec:…'` (rerank) | 3.3–4.5s (July eval: 4.8s — confirmed) |

CLI does **not** route through a running daemon — timings identical with daemon up or down.

**Cold behavior:** daemon's first query after start pays lazy model load — observed 4.1–7.6s. A warmup query at daemon start is mandatory; after that, no per-request cold cost. CLI pays partial model load on *every* embedding/rerank invocation — that is the 3.3–4.5s figure; it cannot be warmed away.

**Wrapper overhead** (knowledge-retrieve.sh entry → brief emit, qmd zeroed via PATH shim returning canned JSON instantly, splitting cost thereby neutralized): **~150ms warm** (0.49s first run). Current real end-to-end on the live BM25+splitting path: 0.77–0.95s (consistent with F8's 0.97s). The A1 review arithmetic assumed ~0.8s overhead — actual is ~5× lower, which materially improves CLI-fallback viability.

**Memory:** daemon RSS ~48MB at idle after start; **~3.5GB** after serving embedding + rerank queries (model weights stay resident). This is the price of the daemon's latency win — an always-on 3.5GB resident service. Flagged as an AKM-002 design consideration (idle timeout? on-demand start? acceptable on a 96GB machine?).

## Recall@3 baselines (M1 gate metric — `qmd bench`, fixture v1, 2026-08-14)

| mode | R@3 | R@5 | MRR | in-process avg |
|---|---|---|---|---|
| bm25 | 0.284 | 0.343 | 0.538 | 5ms |
| vector | **0.475** | 0.645 | 0.674 | 77ms |
| hybrid | 0.476 | 0.619 | 0.736 | ~1.1s |
| full | 0.570 | 0.657 | 0.764 | ~3.7s |

Vector R@5 0.645 matches the 2026-07-07 baseline (0.64) — index consistent; small drift in hybrid/full vs July (0.60/0.70 → 0.619/0.657) attributed to corpus growth.

**Caveat for AKM-002:** bench's `hybrid` mode includes reranking. The latency-attractive `lex+vec, no rerank` shape is **not** covered by bench — its recall must be verified (manual fixture run over MCP, or `--explain` traces) before it can be chosen. Do not assume RRF-only recall equals reranked recall; rerank is plausibly where hybrid's MRR advantage (0.736) comes from.

## M1–M5 projection (per acceptance: explicit)

**Yes — at least one combination is projected to pass M1–M5. M6 does not fire.**

Candidate: **daemon transport + structured `lex:`+`vec:` query + rerank** (skill-activation):
- **M1** (R@3 ≥ vector's 0.475): hybrid 0.476 — passes, margin ~zero. Structured queries with real `query_hints` lex terms should beat the fixture's generic phrasing; re-measure at AKM-004 fixture v2.
- **M2** (within-domain ≥71%): July EVL measured hybrid within-domain 100% — projection only; AKM-003 re-verifies post-implementation.
- **M3** (expected doc in ≤3 surfaced): hybrid MRR 0.736 is the best sub-4s mode; unverified at brief level until AKM-003.
- **M4** (noise/N3 empty): daemon exposes `minScore` + wrapper accept-empty + score-0 drop; splitting hack (the N3 false-positive source) is deleted by construction. Verified at AKM-003.
- **M5** (≤2s p95 warm end-to-end): 150ms overhead + 1,292ms transport p95 ≈ **~1.45s p95 — passes** with margin. Cold start handled by daemon warmup query (M5 excludes cold per spec).

**Fallback (daemon down): CLI `qmd query --no-rerank` structured** — 150ms + ~650ms ≈ **~0.8s end-to-end, passes M5**; recall without rerank unverified (caveat above). CLI *with* rerank fails M5 (3.5–4.7s e2e) and is not a viable fallback. `full` mode fails M5 on any transport (~3.7s in-process compute — the daemon cannot rescue it) despite the best R@3 (0.570); rejected.

## Recommendation (go/no-go)

**GO.** Adopt the daemon as primary transport for skill-activation; structured lex+vec queries; rerank on (latency budget allows it and recall likely depends on it); CLI structured no-rerank as the degrade fallback. AKM-002 must design: daemon lifecycle (start/warmup/health-probe/orphan handling — findings 1–3 above), RSS posture, floors per mode, empty-brief handling, and the no-rerank recall verification. Nothing in this spike blocks AKM-002; M6 exception path not needed.
