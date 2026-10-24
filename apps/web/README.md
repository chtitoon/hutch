# myhutch.app

Static website: what Hutch is, the App Store link, privacy policy and support page. Astro in static mode (D14), no client-side JavaScript, no tracking.

## Commands

### Everyday

- `npm run setup`: install pinned dependencies.
- `npm run run`: serve the site locally with live reload.
- `npm test`: both checks below, as Cloudflare runs them. GitHub runs each as its own workflow.

### The checks in `npm test`

- `npm run design:lint`: runs `design:lint:md` and `design:lint:css`.
- `npm run design:lint:md`: lints the root `DESIGN.md` for references, contrast (light and dark) and unused tokens.
- `npm run design:lint:css`: fails on styles that bypass the tokens:
  - raw colors
  - undefined variables
  - type outside the scale
  - external fonts
  - off-scale spacing
- `npm run web:build`, in order:
  - checks generated files and the link preview are current
  - builds the site
  - validates the HTML
  - checks internal links
  - checks every page against the budgets in `PERFORMANCE.md`

### Regenerating files

- `npm run tokens`: regenerates `src/styles/tokens.css` and `public/favicon.svg` from the root `DESIGN.md`.
- `npm run og`: re-renders the link-preview image (`public/og.png`).

### Measuring

- `npx performance check --report`: after a build, prints each page's bytes by kind (for setting budgets).

## Where things live

- `PERFORMANCE.md` — performance budgets and rules, in the [performance.md](https://github.com/chtitoon/performance.md) format, checked by `npm test` and by the Validate Page Speed check on PRs (`.github/workflows/validate-web.yml`).
- `src/pages/` — one file per page. Text pages (`privacy.md`, `support.md`) are Markdown.
- `src/layouts/` — the shared header and footer (`Base.astro`) and the text-page layout (`Prose.astro`).
- `src/components/AppStoreLink.astro` — the one place the App Store link lives; set its URL once Hutch is listed.
- `src/styles/fonts.css` — the web fonts' `@font-face` rules, pointing at the `@fontsource` packages. `fonts.mjs` cuts each file down after `astro build` (an Astro integration, in `astro.config.mjs`).
- `src/styles/tokens.css` — generated; never edit by hand. `site.css` uses only these variables; [DESIGN.md](DESIGN.md) has the web rules.

## Deploying

Cloudflare Pages project `hutch`, connected to this GitHub repo. Merging to `main` deploys myhutch.app; every PR touching `apps/web/` or `design/` gets a preview URL, posted on the PR. Pages runs `npm ci && npm test` in `apps/web`, so a failing test blocks the deploy. On GitHub, the required checks **Design / Validate DESIGN.md** and **Web / Validate Web Build** run the same checks on every PR, so a failure shows in the PR's checks and blocks the merge. Nothing to deploy by hand.
