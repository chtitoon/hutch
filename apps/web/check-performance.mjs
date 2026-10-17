// Checks every page in dist/ against the budgets and rules in PERFORMANCE.md's front matter.
// No browser: it reads the built files and adds up what each page makes the browser download.
// `--report` prints each page's measured sizes, used to set the budgets.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { extname, join, posix } from 'node:path';
import yaml from 'js-yaml';

const file = (path) => new URL(path, import.meta.url).pathname;
const dist = file('./dist/');
const spec = yaml.load(readFileSync(file('./PERFORMANCE.md'), 'utf8').match(/^---\n([\s\S]*?)\n---/)[1]);
const site = new URL(spec.origins.site);

const size = (path) => {
  const stat = statSync(path);
  if (!stat.isFile()) throw new Error(`${path} is not a file`);
  return stat.size;
};
const kb = (bytes) => (bytes < 1024 ? `${bytes} B` : `${(bytes / 1024).toFixed(1)} KB`);
const attr = (tag, name) => tag.match(new RegExp(`\\s${name}\\s*=\\s*"([^"]*)"`, 'i'))?.[1];

// Turns a URL found in a page or stylesheet into a file in dist/, or reports it as off-site.
// `from` is the dist-relative path of the file the URL appears in.
function resolve(url, from) {
  if (url.startsWith('data:')) return { inline: true };
  const absolute = new URL(url, new URL(from, site));
  if (absolute.origin !== site.origin && !(spec.origins.others ?? []).includes(absolute.origin)) return { offsite: absolute.href };
  if (absolute.origin !== site.origin) return { inline: true }; // an allowed other origin: not counted
  return { path: decodeURIComponent(absolute.pathname).replace(/^\//, '') };
}

// Code points that could render on the page: its text, with tags, scripts and styles removed.
function pageCodePoints(html) {
  const text = html
    .replace(/<(script|style)[\s\S]*?<\/\1>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)));
  return new Set([...text].map((c) => c.codePointAt(0)));
}

function inRange(codePoints, unicodeRange) {
  if (!unicodeRange) return true;
  const ranges = unicodeRange.split(',').map((r) => {
    const [lo, hi = lo] = r.trim().replace(/^U\+/i, '').split('-');
    return [parseInt(lo, 16), parseInt(hi, 16)];
  });
  for (const cp of codePoints) if (ranges.some(([lo, hi]) => cp >= lo && cp <= hi)) return true;
  return false;
}

// What one stylesheet adds: browsers fetch the first source of a @font-face (woff2 here) and only
// when the page has characters in its unicode-range. Weights aren't resolved, so every weight
// that matches counts: an upper bound.
// `path` is where the CSS lives: its stylesheet, or the page for an inline <style>.
function stylesheet(css, path, codePoints, add) {
  const fontFaces = [...css.matchAll(/@font-face\s*{([^}]*)}/g)];
  for (const [, body] of fontFaces) {
    const first = body.match(/src\s*:[^;]*?url\(\s*["']?([^"')]+)/)?.[1];
    if (first && inRange(codePoints, body.match(/unicode-range\s*:\s*([^;]+)/)?.[1])) add('fonts', first, path);
  }
  const rest = css.replace(/@font-face\s*{[^}]*}/g, '');
  for (const [, url] of rest.matchAll(/@import\s+(?:url\()?\s*["']?([^"')\s;]+)/g)) add('css', url, path);
  for (const [, url] of rest.matchAll(/url\(\s*["']?([^"')]+)/g)) if (!/\.css$/.test(url)) add('images', url, path);
}

function measure(page) {
  const html = readFileSync(join(dist, page), 'utf8');
  const codePoints = pageCodePoints(html);
  const totals = { html: size(join(dist, page)), css: 0, fonts: 0, images: 0, js: 0 };
  const seen = new Set();
  const images = [];
  const problems = [];

  function add(kind, url, from) {
    const r = resolve(url, from);
    if (r.offsite) return problems.push(`loads ${r.offsite} from another origin (rule: origins.others)`);
    if (r.inline || seen.has(r.path)) return;
    seen.add(r.path);
    let bytes;
    try { bytes = size(join(dist, r.path)); } catch { return; } // missing files are check-links' job
    totals[kind] += bytes;
    if (kind === 'css') stylesheet(readFileSync(join(dist, r.path), 'utf8'), r.path, codePoints, add);
    if (kind === 'images') images.push({ path: r.path, bytes });
  }

  // Inline styles count as CSS, not HTML, so a stylesheet costs the same budget inlined or not.
  for (const [, css] of html.matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/gi)) {
    const bytes = Buffer.byteLength(css);
    totals.html -= bytes;
    totals.css += bytes;
    stylesheet(css, page, codePoints, add);
  }
  for (const [tag] of html.matchAll(/<link\b[^>]*>/gi)) {
    const rel = (attr(tag, 'rel') ?? '').toLowerCase().split(/\s+/);
    const href = attr(tag, 'href');
    if (!href) continue;
    if (rel.includes('stylesheet')) add('css', href, page);
    else if (rel.includes('icon') || rel.includes('apple-touch-icon')) add('images', href, page);
    else if (rel.includes('modulepreload')) add('js', href, page);
    else if (rel.some((r) => ['preload', 'prefetch', 'preconnect', 'dns-prefetch'].includes(r))) {
      const as = attr(tag, 'as');
      add(as === 'font' ? 'fonts' : as === 'style' ? 'css' : as === 'script' ? 'js' : 'images', href, page);
    }
  }
  for (const [, tag, body] of html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)) {
    if (/type\s*=\s*"application\/(ld\+)?json"/i.test(tag)) continue;
    const src = attr(tag, 'src');
    if (src) add('js', src, page);
    else totals.js += Buffer.byteLength(body); // inline JS is part of the HTML too, but it's still JS
  }
  for (const [tag] of html.matchAll(/<(img|source|video|iframe|embed|object)\b[^>]*>/gi)) {
    const kind = /^<(iframe|embed|object)/i.test(tag) ? 'html' : 'images';
    for (const url of [attr(tag, 'src'), attr(tag, 'poster'), attr(tag, 'data')].filter(Boolean)) add(kind, url, page);
    for (const candidate of (attr(tag, 'srcset') ?? '').split(',').map((c) => c.trim().split(/\s+/)[0]).filter(Boolean)) {
      add('images', candidate, page);
    }
    if (spec.images.require_dimensions && /^<img/i.test(tag) && !(attr(tag, 'width') && attr(tag, 'height'))) {
      problems.push(`<img src="${attr(tag, 'src')}"> has no width and height (rule: images.require_dimensions)`);
    }
  }
  for (const [, css] of html.matchAll(/style="([^"]*url\([^"]*)"/gi)) {
    for (const [, url] of css.matchAll(/url\(\s*['"]?([^'")]+)/g)) add('images', url, page);
  }

  for (const { path, bytes } of images) {
    const format = extname(path).slice(1).toLowerCase();
    if (!spec.images.formats.includes(format)) {
      problems.push(`${path} is .${format}; use ${spec.images.formats.join(', ')} (rule: images.formats)`);
    }
    const cap = spec.images.max_kb * 1024;
    if (bytes > cap) problems.push(`${path} is ${kb(bytes)}, over the ${kb(cap)} cap by ${kb(bytes - cap)} (rule: images.max_kb)`);
  }

  totals.total = totals.html + totals.css + totals.fonts + totals.images + totals.js;
  const budget = { ...spec.budgets.default, ...spec.budgets.pages?.[page] };
  for (const [rule, limitKb] of Object.entries(budget)) {
    const kind = rule.replace(/_kb$/, '');
    const limit = limitKb * 1024;
    if (totals[kind] > limit) {
      problems.push(`${kind} is ${kb(totals[kind])}, over its ${kb(limit)} budget by ${kb(totals[kind] - limit)} (rule: budgets.${rule})`);
    }
  }
  return { totals, problems: [...new Set(problems)] };
}

const pages = readdirSync(dist, { recursive: true }).filter((f) => f.endsWith('.html')).map((f) => f.split('\\').join(posix.sep)).sort();
const results = pages.map((page) => ({ page, ...measure(page) }));

if (process.argv.includes('--report')) {
  console.table(Object.fromEntries(results.map(({ page, totals }) => [page, totals])));
}

const failures = results.flatMap(({ page, problems }) => problems.map((p) => `${page}: ${p}`));
if (failures.length) {
  console.error(`Performance budget broken (see PERFORMANCE.md):\n${failures.join('\n')}`);
  process.exit(1);
}
const largest = Math.max(...results.map((r) => r.totals.total));
console.log(`Performance OK across ${pages.length} pages (largest ${kb(largest)})`);
