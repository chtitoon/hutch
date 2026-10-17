// Fails if the site's styles express design without the tokens generated from DESIGN.md.
// Scans CSS files, <style> blocks and style="" attributes in src/ and og/card.html, plus SVG
// color attributes in markup. Rules (see DESIGN.md in this folder):
// - raw-color: no hex, rgb(), hsl() or named colors; color-mix() only over var(--color-*)
// - undefined-var: every var(--…) must be defined in src/styles/tokens.css
// - type: font-family only var(--font-*), font only var(--type-*), no raw font-size,
//   line-height, letter-spacing or font-weight
// - external-font: no @import, @font-face (except local()-only fallbacks) or remote url(); fonts
//   come from @fontsource packages
// - raw-spacing: margin, padding and gap use var(--space-*), except the allowlist in DESIGN.md
import { readFileSync, readdirSync } from 'node:fs';
import { join, relative } from 'node:path';

const root = new URL('.', import.meta.url).pathname;
const tokensFile = 'src/styles/tokens.css';
const tokensCss = readFileSync(join(root, tokensFile), 'utf8');
const defined = new Set([...tokensCss.matchAll(/(--[\w-]+):/g)].map((m) => m[1]));
const colorByValue = new Map([...tokensCss.matchAll(/(--color-[\w-]+): (#[0-9A-Fa-f]+);/g)].map((m) => [m[2].toLowerCase(), m[1]]).reverse());
const spaceByPx = new Map([...tokensCss.matchAll(/(--space-\d+): (\d+)px;/g)].map((m) => [Number(m[2]), m[1]]));

// The spacing allowlist: rows of the "Spacing exceptions" table in this folder's DESIGN.md.
const guide = readFileSync(join(root, 'DESIGN.md'), 'utf8');
const exceptions = (guide.split(/^## Spacing exceptions$/m)[1] ?? '').split(/^## /m)[0];
const allowed = new Set([...exceptions.matchAll(/^\| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \|/gm)].map((m) => `${m[1]}|${m[2]}|${m[3]}`));

// CSS named colors (CSS Color 4), so `color: red` can't slip through.
const named = new Set(`aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown burlywood
cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey
darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey
darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro ghostwhite
gold goldenrod gray green greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon
lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue
lightslategray lightslategrey lightsteelblue lightyellow lime limegreen linen magenta maroon mediumaquamarine mediumblue mediumorchid
mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin
navajowhite navy oldlace olive olivedrab orange orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip
peachpuff peru pink plum powderblue purple rebeccapurple red rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna
silver skyblue slateblue slategray slategrey snow springgreen steelblue tan teal thistle tomato turquoise violet wheat white whitesmoke
yellow yellowgreen`.split(/\s+/));

const failures = [];
const lineAt = (text, index) => text.slice(0, index).split('\n').length;

const colorHint = (raw) => {
  const token = colorByValue.get(raw.toLowerCase());
  return token ? `use var(${token})` : 'use the var(--color-*) role for this job, or add a role to the root DESIGN.md';
};
const nearestVar = (name) => {
  const distance = (a, b) => {
    const d = Array.from({ length: b.length + 1 }, (_, j) => j);
    for (let i = 1; i <= a.length; i++) {
      let prev = d[0];
      d[0] = i;
      for (let j = 1; j <= b.length; j++) [prev, d[j]] = [d[j], Math.min(d[j] + 1, d[j - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1))];
    }
    return d[b.length];
  };
  return [...defined].sort((a, b) => distance(name, a) - distance(name, b))[0];
};
const nearestSpace = (px) => [...spaceByPx].sort(([a], [b]) => Math.abs(a - px) - Math.abs(b - px))[0][1];

const checkDeclaration = (file, line, selector, prop, value) => {
  const fail = (rule, message) => failures.push(`${file}:${line}  ${rule}  ${selector} { ${prop}: ${value} } — ${message}`);
  const bare = value.replace(/"[^"]*"|'[^']*'/g, '""');

  for (const [, name] of bare.matchAll(/var\(\s*(--[\w-]+)/g)) {
    if (!defined.has(name)) fail('undefined-var', `${name} isn't defined in ${tokensFile}; did you mean var(${nearestVar(name)})?`);
  }
  for (const [hex] of bare.matchAll(/#[0-9A-Fa-f]{3,8}\b/g)) fail('raw-color', colorHint(hex));
  for (const [fn] of bare.matchAll(/\b(rgba?|hsla?|hwb|lab|lch|oklab|oklch|color)\(/g)) fail('raw-color', `${fn} is a raw color; use a var(--color-*) role`);
  for (const [word] of bare.replace(/var\([^)]*\)/g, '').matchAll(/\b[a-z]+\b/gi)) {
    if (named.has(word.toLowerCase())) fail('raw-color', `"${word}" is a named color; use a var(--color-*) role`);
  }
  for (const [mix] of bare.matchAll(/color-mix\(([^()]*(\([^()]*\)[^()]*)*)\)/g)) {
    const args = mix.slice('color-mix('.length, -1).split(',').slice(1);
    for (const arg of args) {
      const color = arg.trim().replace(/\s+\d+(\.\d+)?%$/, '');
      if (color !== 'transparent' && !/^var\(--color-[\w-]+\)$/.test(color)) fail('raw-color', `color-mix() mixes only var(--color-*) roles (or transparent), not ${color}`);
    }
  }

  if (prop === 'font-family' && !/^var\(--font-[\w-]+\)$/.test(value)) fail('type', 'use var(--font-display) or var(--font-text)');
  if (prop === 'font' && !/^var\(--type-[\w-]+\)$/.test(value)) fail('type', 'use font: var(--type-<level>) with a level from the root DESIGN.md');
  if (['font-size', 'line-height'].includes(prop)) fail('type', 'set type with font: var(--type-<level>) instead');
  if (prop === 'letter-spacing' && !/^var\(--type-[\w-]+-tracking\)$/.test(value)) fail('type', 'use letter-spacing: var(--type-<level>-tracking)');
  if (prop === 'font-weight' && !/^var\(--font-weight-[\w-]+\)$/.test(value)) fail('type', 'use var(--font-weight-regular|medium|semibold|bold)');

  if (/^(margin|padding)(-(top|right|bottom|left|inline|block)(-(start|end))?)?$|^(row-|column-)?gap$/.test(prop)) {
    for (const [px, n] of bare.replace(/var\([^)]*\)/g, '').matchAll(/(-?\d*\.?\d+)px/g)) {
      if (Number(n) === 0 || allowed.has(`${file}|${selector}|${prop}`)) continue;
      const space = nearestSpace(Math.abs(Number(n)));
      fail('raw-spacing', spaceByPx.get(Math.abs(Number(n))) === space
        ? `${px} is var(${space}); use it`
        : `${px} isn't on the spacing scale; use var(${space}), or list this case under "Spacing exceptions" in apps/web/DESIGN.md with the reason`);
    }
  }
};

// A small CSS walker: comments out, then rules and declarations, nested blocks (@media) included.
const checkCss = (file, css, offset = 0, fullText = css) => {
  const text = css.replace(/\/\*[\s\S]*?\*\//g, (c) => c.replace(/[^\n]/g, ' '));
  // An @font-face whose src is only local() resizes an installed font and loads nothing; any other is a font file.
  for (const m of text.matchAll(/@import\b|@font-face\b(?![^{]*\{[^}]*\bsrc:(\s*local\([^)]*\)\s*,?)+\s*[;}])|url\(\s*["']?(https?:)?\/\//g)) {
    failures.push(`${file}:${lineAt(fullText, offset + m.index)}  external-font  ${m[0]} — fonts and styles are self-hosted: import an @fontsource package in Base.astro`);
  }
  const stack = [];
  let start = 0;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '{') {
      stack.push(text.slice(start, i).trim());
      start = i + 1;
    } else if (c === ';' || c === '}') {
      const decl = text.slice(start, i);
      const colon = decl.indexOf(':');
      const selector = stack.filter((s) => !s.startsWith('@')).at(-1);
      if (colon > 0 && selector !== undefined) {
        const lead = decl.length - decl.trimStart().length;
        checkDeclaration(file, lineAt(fullText, offset + start + lead), selector, decl.slice(0, colon).trim(), decl.slice(colon + 1).trim().replace(/\s*!important$/, ''));
      }
      if (c === '}') stack.pop();
      start = i + 1;
    }
  }
};

const checkMarkup = (file, html) => {
  for (const m of html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/g)) checkCss(file, m[1], m.index + m[0].indexOf('>') + 1, html);
  for (const m of html.matchAll(/\sstyle="([^"]*)"/g)) {
    checkCss(file, `[style] { ${m[1]} }`, m.index - '[style] { '.length + m[0].indexOf('"') + 1, html);
  }
  for (const m of html.matchAll(/\s(fill|stroke|stop-color|color)="([^"]*)"/g)) {
    const v = m[2];
    if (/^#|^(rgb|hsl)a?\(/.test(v) || named.has(v.toLowerCase())) failures.push(`${file}:${lineAt(html, m.index)}  raw-color  ${m[1]}="${v}" — draw in currentColor or a class whose color is a var(--color-*) role; ${colorHint(v)}`);
  }
  for (const m of html.matchAll(/<link\b[^>]*href="(https?:)?\/\/[^"]*"[^>]*>/g)) {
    if (/rel="(stylesheet|preconnect|preload)"/.test(m[0])) failures.push(`${file}:${lineAt(html, m.index)}  external-font  ${m[0]} — fonts and styles are self-hosted: import an @fontsource package in Base.astro`);
  }
};

const files = [
  ...readdirSync(join(root, 'src'), { recursive: true }).map((f) => join('src', f)),
  'og/card.html',
].filter((f) => /\.(css|astro|html|md)$/.test(f) && f !== tokensFile);

for (const file of files) {
  const text = readFileSync(join(root, file), 'utf8');
  if (file.endsWith('.css')) checkCss(file, text);
  else checkMarkup(file, text);
}

if (failures.length) {
  console.error(`Styles bypass the design tokens (${failures.length}):\n${failures.join('\n')}\nRules: apps/web/DESIGN.md. Values: the root DESIGN.md.`);
  process.exit(1);
}
console.log(`Styles OK: ${files.length} files use only tokens from ${relative(root, join(root, tokensFile))}`);
