# myhutch.app

Static website: what Hutch is, the App Store link, privacy policy and support page. Astro in static mode (D14), no client-side JavaScript, no tracking.

## Commands

| Command | What it does |
|---------|--------------|
| `npm run setup` | Install pinned dependencies |
| `npm test` | Both checks below, as Cloudflare runs them; GitHub runs each as its own workflow |
| `npm run validate:design` | Lint the root DESIGN.md and check the styles use only its tokens (`lint:design`, `check:css`) |
| `npm run validate:website` | Check generated files and the link preview are current, build, validate the HTML, check internal links, check every page against the budgets in `PERFORMANCE.md` |
| `npm run run` | Serve the site locally with live reload |
| `npm run tokens` | Regenerate `src/styles/tokens.css` and `public/favicon.svg` from the root `DESIGN.md` |
| `npm run lint:design` | Lint the root `DESIGN.md`: references, contrast (light and dark), unused tokens |
| `npm run check:css` | Fail on styles that bypass the tokens: raw colors, undefined variables, type outside the scale, external fonts, off-scale spacing |
| `npm run og` | Re-render the link-preview image (`public/og.png`) |
| `node check-performance.mjs --report` | After a build, print each page's bytes by kind (for setting budgets) |

## Where things live

- `PERFORMANCE.md` — performance budgets and rules, checked by `npm test` and by the Lighthouse workflow on PRs (`.github/workflows/web-performance.yml`).
- `src/pages/` — one file per page. Text pages (`privacy.md`, `support.md`) are Markdown.
- `src/layouts/` — the shared header and footer (`Base.astro`) and the text-page layout (`Prose.astro`).
- `src/components/AppStoreLink.astro` — the one place the App Store link lives; set its URL once Hutch is listed.
- `src/styles/tokens.css` — generated; never edit by hand. `site.css` uses only these variables; [DESIGN.md](DESIGN.md) has the web rules.

## Deploying

Cloudflare Pages project `hutch`, connected to this GitHub repo. Merging to `main` deploys myhutch.app; every PR touching `apps/web/` or `design/` gets a preview URL, posted on the PR. Pages runs `npm ci && npm test` in `apps/web`, so a failing test blocks the deploy. On GitHub, the **Design Lint** and **Web Build** workflows run the same checks as two required checks on every PR, so a failure shows in the PR's checks and blocks the merge. Nothing to deploy by hand.
