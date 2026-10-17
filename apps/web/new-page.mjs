// Starts a new page that already meets PERFORMANCE.md: Markdown on the shared layout, so it ships
// no JavaScript, loads only the site's own CSS and fonts, and stays static.
// `npm run new-page -- <slug> "<Title>" ["<description>"]` writes src/pages/<slug>.md.
import { existsSync, writeFileSync } from 'node:fs';

const [slug, title, description = ''] = process.argv.slice(2);
if (!slug || !title || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(slug)) {
  console.error('Usage: npm run new-page -- <slug> "<Title>" ["<description>"]   (slug: lowercase-with-dashes)');
  process.exit(1);
}
const path = new URL(`./src/pages/${slug}.md`, import.meta.url);
if (existsSync(path)) {
  console.error(`src/pages/${slug}.md already exists`);
  process.exit(1);
}

const quote = (s) => JSON.stringify(s);
writeFileSync(path, `---
layout: ../layouts/Prose.astro
title: ${quote(title)}
description: ${quote(description || title)}
---

# ${title}

Write the page here. Before adding anything beyond text, read the checklist in PERFORMANCE.md:
images are self-hosted SVG, WebP or AVIF with width and height; no scripts or embeds without a stated need.
`);
console.log(`Wrote src/pages/${slug}.md, served at /${slug}. Run \`npm test\` to check it against PERFORMANCE.md.`);
