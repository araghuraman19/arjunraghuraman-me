# WA — Website Agent (arjunraghuraman.me)

The Claude Code project that builds and grows my personal thought-leadership site, **arjunraghuraman.me**. It works as an "agent" because of one standing behavior: every session, it checks the latest output from the other agents against the site's current content and suggests new projects and content angles, with emphasis on life sciences and pharma.

`CLAUDE.md` is the source of truth for design decisions and site structure. This README is the human-facing summary and records how WA connects to the ecosystem. See `../agentic-collaboration/README.md` for the full picture.

## At a glance

| | |
|---|---|
| Domain | arjunraghuraman.me (registered via Cloudflare) |
| Generator | Astro |
| Design system | Quantitative Minimalism: near-white ground, charcoal text, a single teal/blue/red accent, IBM Plex Sans/Mono, data-axis motifs |
| Throughline | Statistics, math, and Wolfram Language, made explicit on every page |
| Audience | Hiring managers (applications with a "personal website" field), ACS/PMSE peers, collaborators, technical readers |
| Launch rule | Progress over perfection, but quality-gated. Launch when it's good enough to list on job applications. |
| Hosting / deploy | Cloudflare Workers static assets: `site/wrangler.jsonc` defines a Worker named `arjunraghuraman-me` serving the `./dist` build output (Astro's `npm run build` target) with no separate Worker script — the shape used by `wrangler deploy`, not `wrangler pages deploy`. Unconfirmed: `wrangler` isn't yet a project dependency or global install, and there's no deploy script or CI workflow, so the actual deploy command hasn't been run/scripted yet. |

## Running it

```bash
cd arjun-me-project/site
npm install
npm run dev      # local preview
npm run build    # production build
```
These match `site/package.json`'s scripts. Deploy target is Cloudflare Workers static assets (`site/wrangler.jsonc`: Worker `arjunraghuraman-me`, assets served from `./dist`) via `wrangler deploy` — but `wrangler` isn't installed as a dependency yet and there's no deploy script or CI, so the deploy step itself hasn't been run or automated.

Open the project folder in Claude Code to work on it. `CLAUDE.md` loads automatically, and the cross-agent check (below) runs as a standard first step.

## Project layout

```
arjun-me-project/
├── CLAUDE.md        # decisions, information architecture, standing cross-agent behavior
├── content/         # raw material, organized by interest area (notebooks, notes, drafts)
└── site/            # Astro codebase
```

## Content status

| Section | Status |
|---|---|
| Statistics, Math & Wolfram: Mixed Effects Models | Ready |
| Statistics, Math & Wolfram: Alpha-Pinene Estimation | Ready |
| Music (Spotify links + "now" text) | Ready |
| SDL / Automation / Sensors | Partial; waiting on the paper |
| Kinetics & PK (`/kinetics`): Arrhenius Reparameterization | Ready. Light and dark figures exported from `content/kinetics/ArrheniusJacobianEigen_themed.wl` (`wolframscript -file ... light|dark`) |
| Kinetics & PK: pharmacokinetics content | Not started |
| Protein Folding & Design | Robert's blog plus my own commentary (no "coming soon") |
| Community blurbs (BIP Forum, The Lens, Varinia's course) | Not started |
| Publications & Patents | Recommended; not yet committed as a live section. `content/publications_patents/` already exists as the destination folder for PLSA's Mode 3 (granted-patents refresh) output once that mode is live (still untested on PLSA's side) |
| Agentic Workflows | Excluded from launch until PLSA or JSA is presentable |

Unfinished sections are hidden entirely, with no "coming soon" indicators anywhere.

The site defaults to dark mode. Light is opt-in via the toggle and remembered per browser; the OS setting is ignored. Chart figures ship as `<name>.png` plus `<name>-dark.png`. A wide multi-panel figure can also pass `narrowSrc` to `Figure` (a stacked export, plus its `-dark` sibling), which replaces it below 640 px.

## Interfaces with other agents

| Direction | Mechanism | Status |
|---|---|---|
| **JSA → WA** | Every session, WA reads the latest report in `../job-search-agent/output/`, compares it with the `content/` inventory, and suggests new projects or angles | Working. Path fixed 2026-09-22 (`/Users/arjun/Documents/Python/job-search-agent/output/`). |
| **PLSA → WA** | WA reading PLSA reports | Not implemented. `CLAUDE.md` reads only JSA. Add it if WA should see PLSA themes directly. |
| **PLSA Mode 3 → WA** | Granted-patents delta for a Publications & Patents page | Manual for now. Formalize once that page is committed. |
| **Wolfram work → WA** | Notebooks and write-ups placed in `content/` | Manual (file drop) |

This is a snapshot comparison made when a session runs, not a live sync. JSA's output only changes when I trigger it (about every 2 days).

## Known gaps (update as these get resolved)

- **PLSA isn't read**, even though the ecosystem description says WA uses PLSA reports.
- **Hosting/deploy command** isn't confirmed — `wrangler.jsonc` shows the target (Cloudflare Workers static assets) but `wrangler` isn't installed yet and no deploy script/CI exists.

## Ideas

- **Agentic Workflows section:** once presentable, the READMEs of PLSA, JSA, WA and the hub are ready-made source material. Architecture, data flow, and design decisions such as "LinkedIn is manual only" and "no unattended scheduling" all make good thought-leadership content.

## Changelog

One line per meaningful change. Mirror each entry in the hub README's changelog.

- 2026-11-01: Arrhenius article: corrected the A–Ea estimate correlation to ρ = +0.99986 (−0.99986 is the cosine between the sensitivity columns); "in one line" → "in a couple of lines". Fig. 1 now has a stacked export (`Fig1_sensitivity_columns-stacked.png`) that `Figure` swaps in on phones via a new `narrowSrc` prop, so its panel labels stay readable.
- 2026-11-01: Publications & Patents links use a new `--color-link` token (Wolfram StandardBlue #6699ff in dark; same hue at 73% brightness, #4a70ba, in light for 4.5:1). α-pinene plots re-exported from `alpha_pinene_analysis.wl` at one width (640 pt), 13 pt labels, shared padding and legends below, so labels match on the page; dark exports now use the site's text/frame colors. Arrhenius article ends with a "Get in touch" line for the notebook.
- 2026-11-01: Publications & Patents: every publication title links to its DOI (checked against Crossref) and every patent number links to Google Patents (Singapore grants link to the `…A` publication, which is the one Google indexes); section headings use the accent green. Links were added to both `content/publications_patents/publications-patents.md` and the site copy.
- 2026-11-01: α-pinene case study: added a reaction-scheme figure (`content/stats-math-wolfram/alpha_pinene_scheme_themed.wl`, from `alpha-pinene-scheme.nb`) and a structures figure drawn in ChemDraw's ACS Document 1996 style by `alpha_pinene_structures.py` (RDKit + cairosvg; PubChem 2D coordinates in `pubchem_2d/`, hand-placed α-pinene). Removed the "What this page deliberately leaves out" section.
- 2026-11-01: Nav uses Wolfram StandardOrange (`--color-nav`); broader `/kinetics` intro and home-card copy.
- 2026-10-31: New interest area, Kinetics & PK (`/kinetics`, `kinetics` content collection). First article: Arrhenius reparameterization, cross-linked with α-pinene. Raw material in `content/kinetics/`, including `ArrheniusJacobianEigen_themed.wl`, which exports light and dark figures.
- 2026-10-31: Dark mode is now the default theme. Light is opt-in via the toggle; the OS preference is ignored. Added a `theme-color` meta tag.
- 2026-09-22: Added a Publications & Patents row to `CLAUDE.md`'s Content Status table (parity with README's own table).
- 2026-09-22: Filled in the deploy TODO (Cloudflare Workers static assets, per `site/wrangler.jsonc`); tightened `CLAUDE.md`'s JSA-read step to target `job_search_report_*.docx` and ignore `.DS_Store`/`.gitkeep`; noted `content/publications_patents/` already exists as PLSA Mode 3's destination folder.
- 2026-09-22: `CLAUDE.md` fixed: JSA path, stale generator line, old agent names; added source-of-truth rule.
- 2026-09-22: README created; WA named. Documented JSA → WA contract, broken path after folder rename, and PLSA → WA gap.
- 2026-09: Added standing cross-agent check (reads JSA output each session).
- 2026-09: Chose Astro, Quantitative Minimalism, hidden unfinished sections, and a duotone profile photo.
