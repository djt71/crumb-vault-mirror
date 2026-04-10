---
project: think-different
domain: learning
type: specification
skill_origin: systems-analyst
status: draft
created: 2026-02-17
updated: 2026-02-17
tags:
  - specification
  - think-different
---

# Think Different — Specification

## Problem Statement

Apple's "Think Different" campaign (1997–2002) featured dozens of history's most remarkable
individuals — scientists, artists, activists, leaders, inventors, filmmakers, musicians.
Danny wants a comprehensive vault-native reference capturing the campaign's history and
deep intellectual profiles of every personality featured, along with a thematic synthesis
of what "thinking different" meant across these lives.

## Scope

### Campaign History Document
Full contextual history covering:
- Apple's crisis in 1997 and Jobs' return as interim CEO
- TBWA\Chiat\Day and the key creatives: Lee Clow, Rob Siltanen, Craig Tanimoto, Ken Segall, Jessica Schulman Edelstein
- Development of the "Here's to the Crazy Ones" narration (Siltanen/Segall draft, Jobs' involvement, the Siltanen–Isaacson authorship dispute)
- The 17-day sprint from approval to launch
- Narrator selection: Robin Williams (declined), Tom Hanks (considered), Richard Dreyfuss (chosen)
- Jobs' personal role securing likeness rights (Yoko Ono visit, Henson family call)
- TV commercial (September 28, 1997) — 60-second spot with 17 figures + closing shot
- Seinfeld finale 30-second variant
- Print/poster campaign — five numbered sets, standalone posters, Educator series
- Unreleased posters (Dalai Lama, Bob Dylan, Set 5 "The Directors")
- "Think different" grammar controversy
- Awards (1998 Emmy, 2000 Grand Effie)
- Campaign legacy and phase-out (~2002)
- Impact on Apple's brand identity and the marketing industry

### Personality Profiles (one file per person)
Full intellectual profiles for each confirmed personality, stored in `profiles/` subdirectory.
Each profile includes:
- **Biographical overview** — life dates, origin, key life arc
- **Philosophy & worldview** — what they believed, how they saw the world
- **Major works & achievements** — the things that made them historic
- **"Think Different" connection** — why Apple chose them, which media they appeared in (TV/print/poster/Educator), what aspect of "thinking differently" they represent
- **Notable quotes** — 2–3 representative quotes capturing their philosophy

Frontmatter: `type: profile`, tags: `#think-different`, `#kb/history`

### Thematic Synthesis Document
Cross-cutting analysis drawing connections across all personalities:
- Thematic groupings (what unites the scientists vs. the artists vs. the activists, and what unites them all)
- Philosophical patterns — rebellion, vision, persistence, creative courage
- What "thinking differently" actually meant across these lives
- The campaign's implicit argument about human greatness
- Connections and relationships between the featured individuals

### Master Roster
Quick-reference table of all personalities with: name, field, media appearances (TV/print/Educator), profile link.

## Confirmed Personality Roster (45 figures)

### TV Commercial (17 + 2 special)
1. Albert Einstein — Physics
2. Bob Dylan — Music
3. Martin Luther King Jr. — Civil rights
4. Richard Branson — Business/entrepreneurship
5. John Lennon (with Yoko Ono) — Music
6. R. Buckminster Fuller — Architecture/invention
7. Thomas Edison — Invention
8. Muhammad Ali — Boxing
9. Ted Turner — Media
10. Maria Callas — Opera
11. Mahatma Gandhi — Political/spiritual leadership
12. Amelia Earhart — Aviation
13. Alfred Hitchcock — Film
14. Martha Graham — Dance
15. Jim Henson (with Kermit the Frog) — Puppetry/entertainment
16. Frank Lloyd Wright — Architecture
17. Pablo Picasso — Art
18. Shaan Sahota — Young girl (closing shot)
19. Jerry Seinfeld — Comedy (30-second Seinfeld finale variant only)

### Print/Poster Only
20. Joan Baez — Folk music/activism
21. 14th Dalai Lama (Tenzin Gyatso) — Spiritual leadership (created, never released)
22. Jimi Hendrix — Music
23. Miles Davis — Jazz
24. Ansel Adams — Photography
25. Lucille Ball & Desi Arnaz — Television/comedy
26. Paul Rand — Graphic design
27. Frank Sinatra — Music/entertainment
28. Richard Feynman — Physics
29. Jackie Robinson — Baseball/civil rights
30. Cesar Chavez — Labor/civil rights
31. Charlie Chaplin — Film (Set 5, unreleased)
32. Francis Ford Coppola — Film (Set 5, unreleased)
33. Orson Welles — Film (Set 5, unreleased)
34. Frank Capra — Film (Set 5, unreleased)
35. John Huston — Film (Set 5, unreleased)
36. Nelson Mandela — Political leadership
37. Eleanor Roosevelt — Politics/humanitarianism
38. Buzz Aldrin — Space exploration
39. Bill Bernbach — Advertising
40. George Gershwin — Music/composition
41. Rosa Parks — Civil rights
42. James Watson — Genetics/science
43. Jane Goodall — Primatology/conservation
44. Ron Howard — Film
45. Flik — Animated character (Pixar's *A Bug's Life*, promotional tie-in)

## Deliverables

| # | Artifact | File | Description |
|---|----------|------|-------------|
| 1 | Campaign History | `campaign-history.md` | Full contextual history of the Think Different campaign |
| 2 | Personality Profiles | `profiles/[name].md` (×44) | One file per real person (excluding Flik) |
| 3 | Flik Note | `profiles/flik.md` | Brief note on the Pixar promotional tie-in |
| 4 | Thematic Synthesis | `synthesis.md` | Cross-cutting themes and philosophical patterns |
| 5 | Master Roster | `roster.md` | Quick-reference table with links to all profiles |

## File Conventions

- Profile filenames: kebab-case of person's name (e.g., `albert-einstein.md`, `martin-luther-king-jr.md`)
- All profiles tagged `#think-different` and `#kb/history`
- Campaign history and synthesis tagged `#think-different`
- Frontmatter on every file per vault conventions

## Out of Scope

- Apple marketing history beyond the Think Different campaign
- Detailed analysis of Apple's financial recovery (mentioned only as context)
- Merchandise, memorabilia, or collector market for campaign posters
- Fan-made or unconfirmed poster subjects

## Acceptance Criteria

1. Campaign history document covers all sections listed in Scope
2. A profile exists for every confirmed real personality (44 files)
3. Each profile contains all five required sections (bio, philosophy, works, TD connection, quotes)
4. Thematic synthesis identifies at least 4 cross-cutting themes with specific examples
5. Master roster links to every profile
6. All files have valid YAML frontmatter and correct tags
7. vault-check passes clean after all files are written
