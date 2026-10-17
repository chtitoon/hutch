// Turns the tokens in DESIGN.md's front matter (the repo root) into CSS custom properties.
// A color ending in -dark overrides its role under prefers-color-scheme: dark, and a type
// level ending in -wide overrides its level from the `breakpoint-wide` spacing token up.
// It also writes public/favicon.svg: the icon's mark from design/light/icon.svg,
// in sage, switching to the dark sage in dark mode.
// `node tokens.mjs` writes both files; `--check` fails if either is stale.
import { readFileSync, writeFileSync } from 'node:fs';
import { parse } from 'yaml';

const target = new URL('./src/styles/tokens.css', import.meta.url);

export const readTokens = () => {
  const source = readFileSync(new URL('../../DESIGN.md', import.meta.url), 'utf8');
  const front = source.match(/^---\n([\s\S]*?)\n---\n/);
  if (!front) throw new Error('DESIGN.md has no front matter');
  return parse(front[1]);
};
const tokens = readTokens();

// `{colors.ink}` is a reference (the spec's `primary`), not a role of its own.
const isRef = (v) => typeof v === 'string' && v.startsWith('{');
const colors = Object.entries(tokens.colors).filter(([, v]) => !isRef(v));
const light = Object.fromEntries(colors.filter(([k]) => !k.endsWith('-dark')));
const dark = Object.fromEntries(colors.filter(([k]) => k.endsWith('-dark')).map(([k, v]) => [k.slice(0, -'-dark'.length), v]));
for (const role of Object.keys(dark)) {
  if (!(role in light)) throw new Error(`${role}-dark has no light role ${role}`);
}

// Font stacks are comma-separated; quote family names that contain spaces.
const stack = (family) => family.split(',').map((f) => f.trim()).map((f) => (f.includes(' ') ? `"${f}"` : f)).join(', ');
// The display family is the headlines', the text family the body's.
const fonts = { display: tokens.typography['headline-display'].fontFamily, text: tokens.typography['body-md'].fontFamily };
const weightNames = { 400: 'regular', 500: 'medium', 600: 'semibold', 700: 'bold' };
const weights = [...new Set(Object.values(tokens.typography).map((t) => Number(t.fontWeight)))].sort((a, b) => a - b);
for (const w of weights) {
  if (!weightNames[w]) throw new Error(`font weight ${w} has no name in tokens.mjs`);
}

// Each type level becomes a \`font\` shorthand plus its letter spacing, which \`font\` doesn't set.
const levels = Object.entries(tokens.typography);
const typeLines = (name, t) => [
  `--type-${name}: ${t.fontWeight} ${t.fontSize}/${t.lineHeight} ${stack(t.fontFamily)};`,
  `--type-${name}-tracking: ${t.letterSpacing ?? 'normal'};`,
];
const wide = levels.filter(([k]) => k.endsWith('-wide')).map(([k, t]) => [k.slice(0, -'-wide'.length), t]);
for (const [name] of wide) {
  if (!tokens.typography[name]) throw new Error(`${name}-wide has no base level ${name}`);
}

// Numbered spacing is the 4px scale; named spacing is layout (widths). Breakpoints can't be
// custom properties (media queries don't read them), so they're used here, not emitted.
const spacing = Object.entries(tokens.spacing);
const breakpoint = tokens.spacing['breakpoint-wide'];

const lines = [
  ...Object.entries(light).map(([k, v]) => `--color-${k}: ${v};`),
  ...Object.entries(fonts).map(([k, v]) => `--font-${k}: ${stack(v)};`),
  ...weights.map((w) => `--font-weight-${weightNames[w]}: ${w};`),
  ...levels.filter(([k]) => !k.endsWith('-wide')).flatMap(([k, t]) => typeLines(k, t)),
  ...Object.entries(tokens.rounded).map(([k, v]) => `--radius-${k}: ${v};`),
  ...spacing.filter(([k]) => /^\d+$/.test(k)).map(([k, v]) => `--space-${k}: ${v};`),
  ...spacing.filter(([k]) => !/^\d+$/.test(k) && !k.startsWith('breakpoint-')).map(([k, v]) => `--layout-${k}: ${v};`),
];
const wideLines = wide.flatMap(([k, t]) => typeLines(k, t));
const darkLines = Object.entries(dark).map(([k, v]) => `--color-${k}: ${v};`);

const css = `/* Generated from DESIGN.md by \`npm run tokens\`. Do not edit. */
:root {
${lines.map((l) => `  ${l}`).join('\n')}
}

@media (min-width: ${breakpoint}) {
  :root {
${wideLines.map((l) => `    ${l}`).join('\n')}
  }
}

@media (prefers-color-scheme: dark) {
  :root {
${darkLines.map((l) => `    ${l}`).join('\n')}
  }
}
`;

// The icon file is the mark on a background square: drop the square (the first path)
// and draw the rest as one even-odd path, so the background-colored shapes become holes.
const icon = readFileSync(new URL('../../design/light/icon.svg', import.meta.url), 'utf8');
const [, ...markPaths] = [...icon.matchAll(/<path[^>]* d="([^"]*)"/g)].map((m) => m[1]);
const mark = markPaths.map((d) => d.replace(/-?\d+\.\d+/g, (n) => String(Math.round(n * 10) / 10)).trim()).join(' ');
const favicon = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="583 495 880 880">
<!-- Generated from design/light/icon.svg and DESIGN.md by \`npm run tokens\`. Do not edit. -->
<style>path { fill: ${light.sage}; } @media (prefers-color-scheme: dark) { path { fill: ${dark.sage}; } }</style>
<path fill-rule="evenodd" d="${mark}"/>
</svg>
`;

const outputs = [
  [target, css, 'src/styles/tokens.css'],
  [new URL('./public/favicon.svg', import.meta.url), favicon, 'public/favicon.svg'],
];
for (const [file, content, name] of outputs) {
  if (process.argv.includes('--check')) {
    let current = '';
    try { current = readFileSync(file, 'utf8'); } catch {}
    if (current !== content) {
      console.error(`${name} is out of date with DESIGN.md. Run \`npm run tokens\`.`);
      process.exit(1);
    }
  } else {
    writeFileSync(file, content);
  }
}
if (!process.argv.includes('--check')) {
  console.log(`Wrote ${lines.length} tokens (${darkLines.length} with dark values) to src/styles/tokens.css, and public/favicon.svg`);
}
