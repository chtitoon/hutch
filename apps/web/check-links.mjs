// Fails if any internal link or asset in dist/ points at a file that doesn't exist.
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join } from 'node:path';

const dist = new URL('./dist/', import.meta.url).pathname;
const pages = readdirSync(dist, { recursive: true }).filter((f) => f.endsWith('.html'));
const isFile = (f) => existsSync(f) && statSync(f).isFile();
const broken = [];

for (const page of pages) {
  const html = readFileSync(join(dist, page), 'utf8');
  for (const [, url] of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
    if (/^(https?:|mailto:|#|data:)/.test(url)) continue;
    const file = join(dist, url.split(/[?#]/)[0]);
    if (![file, `${file}.html`, join(file, 'index.html')].some(isFile)) broken.push(`${page}: ${url}`);
  }
}

if (broken.length) {
  console.error(`Broken internal links:\n${broken.join('\n')}`);
  process.exit(1);
}
console.log(`Links OK across ${pages.length} pages`);
