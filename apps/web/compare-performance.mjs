// Compares Lighthouse runs of main and a pull request, using the limits in PERFORMANCE.md's front matter.
// `node compare-performance.mjs <main-dir> <pr-dir> [--comment <file>]` reads every lhr-*.json in each
// directory (as written by `lhci collect`), takes each page's median per metric, and prints a Markdown report.
// Exits 1 if the PR breaks a limit or regresses beyond the noise margin. Writes the PR comment to
// <file> only when something got faster and nothing got slower.
// `node compare-performance.mjs --runs` prints how many runs to collect per side.
// `node compare-performance.mjs --changed <main-dist> <pr-dist>` prints the PR's pages that differ from
// main, one per line, so unchanged pages (identical files, identical results) aren't measured.
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import yaml from 'js-yaml';

const spec = yaml.load(readFileSync(new URL('./PERFORMANCE.md', import.meta.url), 'utf8').match(/^---\n([\s\S]*?)\n---/)[1]);
const { lighthouse } = spec;

if (process.argv[2] === '--runs') {
  console.log(lighthouse.runs);
  process.exit(0);
}

// A page changed if its HTML did. Asset names carry a content hash, so a changed asset changes the
// HTML that links it; files without a hash (favicon.svg) are compared directly, and any change there
// counts for every page.
if (process.argv[2] === '--changed') {
  const [, , , mainDist, prDist] = process.argv;
  const files = (dir) => readdirSync(dir, { recursive: true }).filter((f) => !f.startsWith('_astro') && /\.\w+$/.test(f));
  const same = (f) => existsSync(join(mainDist, f)) && readFileSync(join(mainDist, f)).equals(readFileSync(join(prDist, f)));
  const prFiles = files(prDist);
  const pages = prFiles.filter((f) => f.endsWith('.html'));
  const sharedChanged = prFiles.filter((f) => !f.endsWith('.html')).some((f) => !same(f))
    || files(mainDist).some((f) => !f.endsWith('.html') && !existsSync(join(prDist, f)));
  for (const page of pages) if (sharedChanged || !same(page)) console.log(`/${page.split('\\').join('/')}`);
  process.exit(0);
}

const seconds = (ms) => `${(ms / 1000).toFixed(2)} s`;
const metrics = {
  score: { label: 'Score', short: 'Score', read: (r) => r.categories.performance.score * 100, format: (v) => `${Math.round(v)}`, higherIsBetter: true },
  fcp_ms: { label: 'First Contentful Paint', short: 'FCP', audit: 'first-contentful-paint', format: seconds },
  lcp_ms: { label: 'Largest Contentful Paint', short: 'LCP', audit: 'largest-contentful-paint', format: seconds },
  tbt_ms: { label: 'Total Blocking Time', short: 'TBT', audit: 'total-blocking-time', format: (v) => `${Math.round(v)} ms` },
  cls: { label: 'Cumulative Layout Shift', short: 'CLS', audit: 'cumulative-layout-shift', format: (v) => v.toFixed(3) },
  total_bytes: { label: 'Page weight', short: 'Weight', audit: 'total-byte-weight', format: (v) => `${(v / 1024).toFixed(0)} KB` },
};
const value = (lhr, m) => (metrics[m].read ? metrics[m].read(lhr) : lhr.audits[metrics[m].audit].numericValue);
const median = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2;
};

// { '/index.html': { score: 99, fcp_ms: 1200, ... } }, medians across runs.
function load(dir) {
  const runs = {};
  for (const name of readdirSync(dir).filter((f) => /^lhr-.*\.json$/.test(f))) {
    const lhr = JSON.parse(readFileSync(join(dir, name), 'utf8'));
    if (lhr.configSettings.formFactor !== 'mobile') throw new Error(`${name} was not a mobile run`);
    const page = new URL(lhr.requestedUrl).pathname;
    (runs[page] ??= []).push(lhr);
  }
  return Object.fromEntries(Object.entries(runs).map(([page, lhrs]) => [
    page,
    Object.fromEntries(Object.keys(metrics).map((m) => [m, median(lhrs.map((l) => value(l, m)))])),
  ]));
}

const [mainDir, prDir] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const commentFile = process.argv.includes('--comment') ? process.argv[process.argv.indexOf('--comment') + 1] : null;
const main = load(mainDir);
const pr = load(prDir);

const failures = [];
const gains = [];
const rows = [];

for (const [page, now] of Object.entries(pr).sort()) {
  for (const [m, limit] of Object.entries(lighthouse.limits)) {
    const breached = metrics[m].higherIsBetter ? now[m] < limit : now[m] > limit;
    const exact = (v) => (m.endsWith('_ms') ? `${Math.round(v)} ms` : metrics[m].format(v)); // 1802 ms, not 1.80 s
    if (breached) failures.push(`${page}: ${metrics[m].label} is ${exact(now[m])}, past the ${exact(limit)} limit (rule: lighthouse.limits.${m})`);
  }
  const before = main[page];
  const cells = [];
  for (const m of Object.keys(metrics)) {
    let status = '';
    if (before) {
      // A change counts only when it's bigger than both the metric's threshold and the noise margin.
      const margin = Math.max(spec.compare.thresholds[m], spec.compare.noise_margin * Math.abs(before[m]));
      const worse = metrics[m].higherIsBetter ? before[m] - now[m] : now[m] - before[m];
      status = worse > margin ? ' 🔴' : -worse > margin ? ' 🟢' : '';
      if (status === ' 🔴') failures.push(`${page}: ${metrics[m].label} went from ${metrics[m].format(before[m])} to ${metrics[m].format(now[m])}, beyond the noise margin (rule: compare.thresholds.${m})`);
      if (status === ' 🟢') gains.push({ page, m, before: before[m], now: now[m] });
    }
    cells.push(before ? `${metrics[m].format(before[m])} → ${metrics[m].format(now[m])}${status}` : metrics[m].format(now[m]));
  }
  rows.push(`| ${page}${before ? '' : ' (new)'} | ${cells.join(' | ')} |`);
}

console.log([
  `### Lighthouse, mobile, median of ${lighthouse.runs} runs`,
  '',
  `main → PR. 🟢 faster, 🔴 slower, beyond the noise margin.`,
  '',
  `| Page | ${Object.values(metrics).map((d) => d.short).join(' | ')} |`,
  `|---|${Object.keys(metrics).map(() => '---').join('|')}|`,
  ...rows,
  '',
  failures.length ? `**Failed:**\n${failures.map((f) => `- ${f}`).join('\n')}` : gains.length ? '**Faster than main.**' : '**On par with main.**',
].join('\n'));

if (commentFile && gains.length && !failures.length) {
  const byPage = Object.groupBy(gains, (g) => g.page);
  writeFileSync(commentFile, [
    '<!-- hutch-performance -->',
    '### 🚀 This PR makes the site faster',
    `Lighthouse mobile, median of ${lighthouse.runs} runs, vs main.`,
    ...Object.entries(byPage).flatMap(([page, list]) => [
      '',
      `**${page.replace(/(index)?\.html$/, '') || '/'}**`,
      ...list.map(({ m, before, now }) => `- ${metrics[m].label}: ${metrics[m].format(before)} → ${metrics[m].format(now)}`),
    ]),
  ].join('\n') + '\n');
}

if (failures.length) process.exit(1);
