# arjunraghuraman.me — Project Context

This file is read automatically at the start of every Claude Code session in this project. Keep it updated as decisions change.

## What this is
A personal thought-leadership website for Arjun Raghuraman. The connective thread across every section is **statistics, math, and Wolfram Language** — it underlies the stats projects directly, and implicitly runs through SDL/automation, reaction engineering, and (eventually) protein folding.

## Audience
Hiring managers/interviewers (e.g., job applications with an optional "personal website" field — Anthropic, NVIDIA), ACS/PMSE peers, potential collaborators, and a general technical audience interested in DOE/statistics/chemistry.

## Key Decisions (locked in)
- **Platform**: static site generator (not a no-code builder). Specific generator (Hugo/Astro/Next.js/etc.) still to be chosen.
- **Design language**: modern portfolio look — not an academic/CV aesthetic.
- **Launch philosophy**: progress over perfection, but quality-gated. Goal is to reach a point where the site can be listed on job applications without risking quality — not a hard calendar deadline.
- **Domain**: arjunraghuraman.me (registered via Cloudflare).

## Information Architecture
- **Home** — intro, links to interest areas, recent activity
- **Interest Areas**:
  1. Statistics, Math & Wolfram
     - Mixed Effects Models (content ready)
     - Alpha-Pinene Estimation — WLS, rotated responses (content ready)
  2. Self-Driving Labs / Process Automation & Sensors
     - Sterling's course reference
     - Paper — placeholder until ready
  3. Chemical Reaction Engineering
     - Scope: PDE model exploration, tubular reactors only
  4. Protein Folding & Design
     - No original content yet. Do NOT use "coming soon" language. Instead: reference Robert's blog with Arjun's own commentary/notes layered on top.
  5. Agentic Workflows
     - Excluded from launch entirely (not just "coming soon") until patent-agent or job-search agent projects are presentable.
- **Music** — content ready: Spotify links + short "what I'm doing now" text (practice, listening)
- **About / Now** — bio, current role, current focus
- **Community / Affiliations** — light-touch mentions, not hard sells: BIP Forum (ACS PMSE), The Lens, Varinia's agentic workflow course
- **Publications & Patents** — recommended addition given 78 patents / 26 publications

## Content Status
| Content | Status |
|---|---|
| Mixed Effects Models | Ready |
| Alpha-Pinene Estimation | Ready |
| Music (links + text) | Ready |
| SDL / Automation / Sensors | Partial — waiting on paper |
| Reaction Engineering (PDE, tubular reactors) | Not started |
| Protein Folding & Design | No original content — reference Robert's blog + commentary |
| Agentic Workflows | Not ready — excluded from launch |
| BIP / Lens / Varinia's course blurbs | Not started |

## Decisions (confirmed)
- Static site generator: Astro
- Design system: Quantitative Minimalism (near-white ground, charcoal text, single teal/blue/red accent, IBM Plex Sans/Mono, data-axis motifs) — Working Notebook explored as an alternative but not chosen
- Nav treatment for unfinished sections: fully hidden project-wide (no "coming soon" indicators anywhere), consistent with the protein-folding decision above
- Profile photo: duotone treatment (mapped to the site's own charcoal/near-white palette), chosen over sepia and black & white options

## Cross-Agent Awareness (standing behavior)

Every time this project is worked on, as a standard step — not something to be asked for separately:

1. Read the latest output from job-search-agent
   (/Users/arjun/Documents/Python/job search-agent/output/).
2. Compare that snapshot against the current state of this site
   (content/ inventory — what's published, what's drafted, what's
   just an idea).
3. Surface any potential new project ideas or content angles suggested
   by the overlap — e.g. a company/theme appearing in job-search-agent's
   leads that isn't well represented on the site yet, or an existing
   interest area that deserves more prominence given who's currently
   in the pipeline (life sciences / pharma companies and entrepreneurs
   in particular).

This is a comparison at the time the project is run, not a live sync —
job-search-agent's output only changes when Arjun manually triggers it
(currently a ~2-day reminder cadence), and this project only checks it
when Arjun is actually working in this session.

## Working Notes
- Raw material lives in `content/`, organized by interest area, separate from the actual site codebase in `site/`.
- When drafting page copy from notebooks/notes, keep the stats/Wolfram throughline explicit even on non-stats pages (e.g., note where Wolfram Language was used in the SDL or reaction engineering work).
