// Runs Lighthouse on main's and the PR's builds for the Web Performance check (see PERFORMANCE.md).
// `node run-lighthouse.mjs <main-dist> <pr-dist> <out-dir> <page>...` serves each build locally and runs
// every page `lighthouse.runs` times, alternating main and PR so a slow moment on the machine hits both
// alike. Writes one lhr-*.json per run to <out-dir>/main and <out-dir>/pr. Pages missing from main are
// run on the PR only.
// One Chrome for all runs and the performance category only: about 5 s a run instead of 10 with
// `lhci collect`, with the same results. Lighthouse's default waits stay: shorter ones can stop
// recording before a late font swap shifts the layout. Lighthouse isn't a dependency, so the
// Cloudflare build stays lean; the workflow installs it (`npm install --no-save lighthouse@…`).
import { createServer } from 'node:http';
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { gzipSync } from 'node:zlib';
import lighthouse from 'lighthouse';
import * as chromeLauncher from 'chrome-launcher';
import { parse } from 'yaml';

const spec = parse(readFileSync(new URL('./PERFORMANCE.md', import.meta.url), 'utf8').match(/^---\n([\s\S]*?)\n---/)[1]);
const [mainDist, prDist, outDir, ...pages] = process.argv.slice(2);

const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.svg': 'image/svg+xml', '.png': 'image/png', '.webp': 'image/webp', '.avif': 'image/avif', '.woff2': 'font/woff2', '.woff': 'font/woff' };
const compressible = /^(text\/|image\/svg)/;

// Serves a build like Cloudflare Pages: /privacy finds privacy.html; text is compressed.
function serve(dist) {
  const server = createServer((req, res) => {
    const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    const file = [path, `${path}.html`, join(path, 'index.html')].map((p) => join(dist, p)).find((f) => existsSync(f) && statSync(f).isFile());
    if (!file) return res.writeHead(404).end();
    const type = types[extname(file)] ?? 'application/octet-stream';
    let body = readFileSync(file);
    const headers = { 'content-type': type, 'cache-control': 'no-cache' };
    if (compressible.test(type)) {
      body = gzipSync(body);
      headers['content-encoding'] = 'gzip';
    }
    res.writeHead(200, headers).end(body);
  });
  return new Promise((resolve) => server.listen(0, '127.0.0.1', () => resolve(server)));
}

const sides = { main: await serve(mainDist), pr: await serve(prDist) };
for (const side of Object.keys(sides)) mkdirSync(join(outDir, side), { recursive: true });
const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless=new', '--no-sandbox'] });
const flags = {
  port: chrome.port,
  output: 'json',
  logLevel: 'error',
  onlyCategories: ['performance'],
  skipAudits: ['screenshot-thumbnails', 'final-screenshot', 'full-page-screenshot'],
};

try {
  for (let run = 1; run <= spec.lighthouse.runs; run++) {
    for (const page of pages) {
      for (const [side, server] of Object.entries(sides)) {
        const dist = side === 'main' ? mainDist : prDist;
        if (!existsSync(join(dist, page))) continue;
        const url = `http://127.0.0.1:${server.address().port}${page}`;
        const { lhr } = await lighthouse(url, flags);
        writeFileSync(join(outDir, side, `lhr-${page.replace(/\W/g, '_')}-${run}.json`), JSON.stringify(lhr));
        console.log(`${side} ${page} run ${run}: FCP ${Math.round(lhr.audits['first-contentful-paint'].numericValue)} ms`);
      }
    }
  }
} finally {
  await chrome.kill();
  for (const server of Object.values(sides)) server.close();
}
