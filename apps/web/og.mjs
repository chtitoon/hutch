// Renders og/card.html to public/og.png, the image shown when someone shares a myhutch.app link.
// `node og.mjs` renders it in headless Chromium (needs a Playwright browser: `npx playwright-core install chromium`).
// `--check` needs no browser: it fails if the card, the tokens or the fonts changed since the PNG was rendered.
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';

const file = (path) => new URL(path, import.meta.url);
const stampFile = file('./og/card.sha256');

const inputs = [
  './og/card.html',
  './src/styles/tokens.css',
  './node_modules/@fontsource-variable/bricolage-grotesque/package.json',
  './node_modules/@fontsource/instrument-sans/package.json',
];
const stamp = createHash('sha256').update(inputs.map((p) => readFileSync(file(p))).join('\0')).digest('hex') + '\n';

if (process.argv.includes('--check')) {
  let current = '';
  try { current = readFileSync(stampFile, 'utf8'); } catch {}
  if (current !== stamp) {
    console.error('public/og.png is out of date with og/card.html, the tokens or the fonts. Run `npm run og`.');
    process.exit(1);
  }
} else {
  const { chromium } = await import('playwright-core');
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
  await page.goto(file('./og/card.html').href);
  await page.evaluate(() => document.fonts.ready);
  mkdirSync(file('./public/'), { recursive: true });
  await page.screenshot({ path: file('./public/og.png').pathname });
  await browser.close();
  writeFileSync(stampFile, stamp);
  console.log('Wrote public/og.png (1200×630)');
}
