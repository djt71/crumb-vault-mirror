---
type: run-log
project: vault-mobile-access
created: 2026-04-04
updated: 2026-04-04
---

# vault-mobile-access — Run Log

## 2026-04-04 — Project kickoff

**Session goal:** Specify and implement Quartz-based mobile vault access over Tailscale.

**Context:** User wants to view the Crumb vault on iPhone. Vault lives on Mac Studio, phone has Tailscale. Evaluated options: Quartz static site (selected), Obsidian Sync, Working Copy, dynamic markdown servers. Quartz chosen for best Obsidian syntax support, zero cost, read-only fit.

**Decisions:**
- Quartz v4 for static site generation
- Serve over Tailscale (already configured on phone + Mac Studio)
- CSS overrides planned for iOS WebKit mobile issues
- Graph view will be disabled on mobile (WebKit crash risk)

**SPECIFY phase:**
- Spec written, peer-reviewed (4 reviewers: GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1)
- 3 must-fix, 7 should-fix, 3 deferred findings — all addressed
- Key peer review contributions: Mac Studio sleep/Tailscale interaction (Gemini), content ingestion strategy gap (OpenAI), atomic rebuild definition (consensus)
- Spec updated with: system requirements, content ingestion via symlink, `npx serve` on 0.0.0.0:8080, MagicDNS addressing, atomic rebuild with rollback

### Phase Transition: SPECIFY → PLAN
- Date: 2026-04-04
- SPECIFY phase outputs: specification.md, specification-summary.md, peer review note
- Goal progress: all acceptance criteria met — problem defined, system mapped, tasks decomposed, peer-reviewed
- Compound: No compoundable insights from SPECIFY phase
- Context usage before checkpoint: moderate (extended conversation with peer review dispatch)
- Action taken: none
- Key artifacts for PLAN phase: specification-summary.md

### PLAN → IMPLEMENT (collapsed — tasks already defined in spec)

**VMA-001: Install and configure Quartz v4** ✅
- Quartz v4.5.2 cloned to `/Users/tess/quartz-vault/`
- Content symlinked: `content/ → /Users/tess/crumb-vault/`
- `ignorePatterns` configured for all excluded directories
- Build: 2240 files parsed, 3539 emitted in **19 seconds**
- Search index: 22MB (FlexSearch contentIndex.json)
- Fixed 2 pre-existing YAML issues in vault (duplicate key, bad indentation in review files)
- Port changed from 8080 → **8843** (8080 occupied by llama-server)

**VMA-002: iOS mobile CSS fixes** ✅
- Graph view wrapped in `DesktopOnly()` — hidden on mobile (WebKit crash prevention)
- Mobile CSS: margins, sidebar overflow containment, code/table horizontal scroll
- Footer cleaned up (removed Quartz GitHub/Discord links)
- Page title set to "Crumb Vault"

**VMA-003: Web server + launchd service** ✅
- `npx serve` on `0.0.0.0:8843`
- LaunchAgent: `com.crumb.vault-web` (KeepAlive, RunAtLoad)
- Accessible at `http://tesss-mac-studio:8843` or `http://100.114.233.12:8843`
- Registered in project-state.yaml services

**VMA-004: Automated rebuild** ✅
- `rebuild.sh`: builds to `public-next/`, validates, atomic rename swap, rollback on failure
- LaunchAgent: `com.crumb.vault-rebuild` (every 900s / 15 min)
- Build logs at `/Users/tess/quartz-vault/logs/rebuild.log`

### Phase Transition: IMPLEMENT → DONE
- Date: 2026-04-04
- All 4 tasks completed in a single session
- User verified site on iPhone — "looks good"
- Compound: No compoundable insights from IMPLEMENT phase — standard infrastructure project
- Model routing: all work on Opus (session default), peer review dispatch to 4 external models ($0.20-0.26 estimated)

### Session-end notes
- Pre-existing vault YAML issues fixed: duplicate `domain:` key in research index, bad indentation in FIF review, unquoted string in vault-restructure review
- Port 8080 unavailable (llama-server) — used 8843 instead
- 22MB search index may be worth optimizing if mobile load is sluggish — defer to user feedback
