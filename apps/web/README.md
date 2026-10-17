# myhutch.app

Static website: what Hutch is, the App Store link, privacy policy and support page. Astro in static mode (D14), no client-side JavaScript, no tracking.

## Commands

| Command | What it does |
|---------|--------------|
| `npm run setup` | Install pinned dependencies |
| `npm test` | Check tokens are current, build, validate the HTML, check internal links, check every page against the budgets in `PERFORMANCE.md` |
| `npm run run` | Serve the site locally with live reload |
| `npm run tokens` | Regenerate `src/styles/tokens.css` from `design/tokens.json` |
| `npm run new-page -- <slug> "<Title>"` | Start a Markdown page at `/<slug>` that already meets `PERFORMANCE.md` |
| `node check-performance.mjs --report` | After a build, print each page's bytes by kind (for setting budgets) |

## Performance

`PERFORMANCE.md` is the single source of the site's performance rules: read it before adding a page, an asset or a feature. Its budgets run in `npm test`, so Cloudflare refuses to deploy a page that breaks one. Every PR touching `apps/web/` or `design/` also runs Lighthouse on main and the PR in GitHub Actions (`.github/workflows/web-performance.yml`): the check fails on a slowdown, and a comment appears when the PR makes the site faster.

## Where things live

- `src/pages/` — one file per page. Text pages (`privacy.md`, `support.md`) are Markdown.
- `src/layouts/` — the shared header and footer (`Base.astro`) and the text-page layout (`Prose.astro`).
- `src/components/AppStoreLink.astro` — the one place the App Store link lives; set its URL once Hutch is listed.
- `src/styles/tokens.css` — generated; never edit by hand. `site.css` uses only these colors.

## Deploying

Cloudflare Pages project `hutch`, connected to this GitHub repo. Merging to `main` deploys myhutch.app; every PR touching `apps/web/` or `design/` gets a preview URL, posted on the PR. Pages runs `npm ci && npm test` in `apps/web`, so a failing test blocks the deploy. Nothing to deploy by hand.
