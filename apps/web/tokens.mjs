// Turns design/tokens.json into CSS custom properties. The `color-dark` group
// overrides the `color` roles under prefers-color-scheme: dark.
// `node tokens.mjs` writes src/styles/tokens.css; `--check` fails if it is stale.
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

if (process.argv.includes('--check')) {
  let current = '';
  try { current = readFileSync(target, 'utf8'); } catch {}
  if (current !== css) {
    console.error('src/styles/tokens.css is out of date with design/tokens.json. Run `npm run tokens`.');
    process.exit(1);
  }
} else {
  writeFileSync(target, css);
  console.log(`Wrote ${lines.length} tokens (${darkLines.length} with dark values) to src/styles/tokens.css`);
}
