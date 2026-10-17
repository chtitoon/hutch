// Lints the root DESIGN.md: the source of the design tokens.
// Runs Google's DESIGN.md linter (broken references, contrast, unused tokens, structure) and fails
// on any error or warning. Two Hutch conventions the spec doesn't know are checked here too:
// - a component ending in -graphic is a mark, not text, so it needs 3:1 (WCAG 1.4.11), not 4.5:1;
// - a component whose colors have -dark values needs a -dark twin using them, so dark mode is checked.
import { readFileSync } from 'node:fs';
import { lint, contrastRatio } from '@google/design.md/linter';
import { parse } from 'yaml';

const file = new URL('../../DESIGN.md', import.meta.url);
const source = readFileSync(file, 'utf8');
const lines = source.split('\n');
// The line where a front-matter key is defined, so a failure points at it.
const lineOf = (path = '') => {
  let from = 0;
  for (const key of path.split('.')) {
    const i = lines.findIndex((l, n) => n >= from && new RegExp(`^\\s*"?${key}"?:`).test(l));
    if (i === -1) break;
    from = i;
  }
  return from + 1;
};

const failures = [];
const fail = (path, rule, message) => failures.push(`DESIGN.md:${lineOf(path)}  ${rule}  ${message}`);

const { findings, designSystem } = lint(source);
for (const f of findings) {
  if (f.severity === 'info') continue;
  if (f.rule === 'contrast-ratio' && /-graphic(-dark)?$/.test(f.path)) {
    const props = designSystem.components.get(f.path.split('.')[1]).properties;
    const ratio = contrastRatio(props.get('backgroundColor'), props.get('textColor'));
    if (ratio >= 3) continue;
    fail(f.path, f.rule, `graphic contrast ${ratio.toFixed(2)}:1, below the 3:1 minimum for marks. Use a color with more contrast against its background.`);
    continue;
  }
  fail(f.path, f.rule, f.message);
}

const tokens = parse(source.match(/^---\n([\s\S]*?)\n---\n/)[1]);
const colorOf = (v) => (typeof v === 'string' ? v.match(/^\{colors\.(.+)\}$/)?.[1] : undefined);
for (const [name, props] of Object.entries(tokens.components ?? {})) {
  // A reference to a missing color is already a broken-ref failure.
  if (name.endsWith('-dark') || Object.values(props).some((v) => colorOf(v) && !(colorOf(v) in tokens.colors))) continue;
  const expected = Object.fromEntries(Object.entries(props).map(([k, v]) => {
    const color = colorOf(v);
    return [k, color && `${color}-dark` in tokens.colors ? `{colors.${color}-dark}` : v];
  }));
  if (Object.entries(expected).every(([k, v]) => v === props[k])) continue;
  const twin = tokens.components[`${name}-dark`];
  if (!twin) {
    fail(`components.${name}`, 'dark-twin', `${name} uses colors with -dark values but has no ${name}-dark component, so its dark-mode contrast isn't checked. Add ${name}-dark using ${Object.values(expected).filter(colorOf).join(', ')}.`);
    continue;
  }
  for (const [k, v] of Object.entries(expected)) {
    if (colorOf(v) && twin[k] !== v) fail(`components.${name}-dark.${k}`, 'dark-twin', `${name}-dark.${k} is ${twin[k] ?? 'missing'}; it should be ${v}.`);
  }
}

if (failures.length) {
  console.error(`DESIGN.md has ${failures.length} problem(s):\n${failures.join('\n')}`);
  process.exit(1);
}
console.log(`DESIGN.md OK: ${designSystem.colors.size} colors, ${designSystem.typography.size} type levels, ${designSystem.components.size} checked pairs`);
