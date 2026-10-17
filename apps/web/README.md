# myhutch.app

Static website: what Hutch is, the App Store link, privacy policy and support page. Astro in static mode (D14), no client-side JavaScript, no tracking.

## Commands

| Command | What it does |
|---------|--------------|
| `npm run setup` | Install pinned dependencies |
| `npm test` | Lint DESIGN.md, check tokens and styles, check the link preview is current, build, validate the HTML, check internal links |
| `npm run run` | Serve the site locally with live reload |
| `npm run tokens` | Regenerate `src/styles/tokens.css` and `public/favicon.svg` from the root `DESIGN.md` |
| `npm run lint:design` | Lint the root `DESIGN.md`: references, contrast (light and dark), unused tokens |
| `npm run check:css` | Fail on styles that bypass the tokens: raw colors, undefined variables, type outside the scale, external fonts, off-scale spacing |
| `npm run og` | Re-render the link-preview image (`public/og.png`) |

## Where things live

- `src/pages/` — one file per page. Text pages (`privacy.md`, `support.md`) are Markdown.
- `src/layouts/` — the shared header and footer (`Base.astro`) and the text-page layout (`Prose.astro`).
- `src/components/AppStoreLink.astro` — the one place the App Store link lives; set its URL once Hutch is listed.
- `src/styles/tokens.css` — generated; never edit by hand. `site.css` uses only these variables; [DESIGN.md](DESIGN.md) has the web rules.

## Deploying

Cloudflare Pages project `hutch`, connected to this GitHub repo. Merging to `main` deploys myhutch.app; every PR touching `apps/web/` or `design/` gets a preview URL, posted on the PR. Pages runs `npm ci && npm test` in `apps/web`, so a failing test blocks the deploy. Nothing to deploy by hand.
