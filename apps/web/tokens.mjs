// Turns design/tokens.json into CSS custom properties. The `color-dark` group
// overrides the `color` roles under prefers-color-scheme: dark.
// It also writes public/favicon.svg: the icon's mark from design/light/icon.svg,
// in sage, switching to the dark sage in dark mode.
// `node tokens.mjs` writes both files; `--check` fails if either is stale.
import { readFileSync, writeFileSync } from 'node:fs';

const source = new URL('../../design/tokens.json', import.meta.url);
const target = new URL('./src/styles/tokens.css', import.meta.url);

const tokens = JSON.parse(readFileSync(source, 'utf8'));
// Font stacks are arrays; quote family names that contain spaces.
const toCss = (v) => (Array.isArray(v) ? v.map((f) => (f.includes(' ') ? `"${f}"` : f)).join(', ') : v);

const walk = (node, path, lines = []) => {
  for (const [key, value] of Object.entries(node)) {
    if (key.startsWith('$') || !value || typeof value !== 'object') continue;
    if ('$value' in value) lines.push(`--${[...path, key].join('-')}: ${toCss(value.$value)};`);
    else walk(value, [...path, key], lines);
  }
  return lines;
};
const { 'color-dark': dark, ...light } = tokens;
const lines = walk(light, []);
const darkLines = walk(dark, ['color']);
for (const line of darkLines) {
  if (!lines.some((l) => l.startsWith(line.split(':')[0] + ':'))) throw new Error(`color-dark has no light role: ${line}`);
}

const css = `/* Generated from design/tokens.json by \`npm run tokens\`. Do not edit. */
:root {
${lines.map((l) => `  ${l}`).join('\n')}
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
<!-- Generated from design/light/icon.svg and design/tokens.json by \`npm run tokens\`. Do not edit. -->
<style>path { fill: ${tokens.color.sage.$value}; } @media (prefers-color-scheme: dark) { path { fill: ${dark.sage.$value}; } }</style>
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
      console.error(`${name} is out of date with design/. Run \`npm run tokens\`.`);
      process.exit(1);
    }
  } else {
    writeFileSync(file, content);
  }
}
if (!process.argv.includes('--check')) {
  console.log(`Wrote ${lines.length} tokens (${darkLines.length} with dark values) to src/styles/tokens.css, and public/favicon.svg`);
}
