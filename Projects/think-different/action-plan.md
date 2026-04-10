---
project: think-different
domain: learning
type: action-plan
skill_origin: null
status: active
created: 2026-02-17
updated: 2026-02-17
tags:
  - action-plan
  - think-different
---

# Think Different — Action Plan

## Execution Model

All writing happens in the main session, serially. Profiles are written in batches of
5–8 per session with context checkpoints between batches. Thematic groupings organize
the work but execute sequentially across sessions. No subagents — this is
research/writing execution, not isolated design work.

## Execution Order

### Session 1 (current): Foundation
1. **Campaign History** (`campaign-history.md`) — establishes narrative context
2. **Profile Template** — define consistent structure for all 44 profiles
3. **Begin Batch A — Scientists & Inventors** (7 profiles, may split across sessions)
   - Albert Einstein
   - Thomas Edison
   - Richard Feynman
   - R. Buckminster Fuller
   - James Watson
   - Jane Goodall
   - Buzz Aldrin

### Session 2: Batch B — Musicians (8 profiles)
- Bob Dylan
- John Lennon (with Yoko Ono)
- Maria Callas
- Jimi Hendrix
- Miles Davis
- Joan Baez
- Frank Sinatra
- George Gershwin

### Session 3: Batch C — Civil Rights & Political Leaders (7 profiles)
- Martin Luther King Jr.
- Mahatma Gandhi
- Nelson Mandela
- Rosa Parks
- Jackie Robinson
- Cesar Chavez
- Eleanor Roosevelt

### Session 4: Batch D — Film & Entertainment (10 profiles, may split)
- Alfred Hitchcock
- Charlie Chaplin
- Francis Ford Coppola
- Orson Welles
- Frank Capra
- John Huston
- Ron Howard
- Jim Henson
- Lucille Ball & Desi Arnaz
- Jerry Seinfeld

### Session 5: Batch E — Visual Arts, Design, Architecture & Dance (5 profiles)
- Pablo Picasso
- Ansel Adams
- Paul Rand
- Frank Lloyd Wright
- Martha Graham

### Session 6: Batch F — Business, Media, Sports & Other (6 profiles) + Special (2)
- Richard Branson
- Ted Turner
- Bill Bernbach
- Muhammad Ali
- Amelia Earhart
- 14th Dalai Lama
- Shaan Sahota (brief)
- Flik (brief)

### Session 7: Capstone
1. **Master Roster** (`roster.md`) — quick-reference table linking all profiles
2. **Thematic Synthesis** (`synthesis.md`) — cross-cutting themes and philosophical patterns

## Context Checkpoint Protocol

Between each batch:
- Check context usage
- If >70%: compact before next batch
- If >85%: end session, pick up in next session
- Log batch completion to run-log.md

Between sessions:
- Read project-state.yaml and last run-log entry to reconstruct state
- Load specification-summary.md (not full spec)
- Resume from next batch in sequence

## Profile Template

Each profile follows this structure:

```markdown
---
project: think-different
domain: learning
type: profile
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - think-different
  - kb/history
---

# [Person Name]

## Biographical Overview
[Life dates, origin, key life arc — 2–3 paragraphs]

## Philosophy & Worldview
[What they believed, how they saw the world — 2–3 paragraphs]

## Major Works & Achievements
[The things that made them historic — bulleted or narrative]

## Think Different Connection
[Why Apple chose them, which media (TV/print/poster/Educator), what aspect of
"thinking differently" they represent — 1–2 paragraphs]

## Notable Quotes
[2–3 representative quotes capturing their philosophy]
```

## Acceptance Criteria (from spec)

1. Campaign history covers all scoped sections
2. 44 profile files exist, each with 5 required sections
3. Synthesis identifies ≥4 cross-cutting themes with examples
4. Roster links to every profile
5. Valid frontmatter and tags; vault-check clean
