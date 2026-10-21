// Cuts the site's web fonts down to what its pages draw (see PERFORMANCE.md, "Fonts"). An Astro
// integration: after `astro build`, it reads every built page, works out which characters each
// @font-face draws, subsets that file to exactly those (subset-font: HarfBuzz, pinned), renames it
// by its new content and updates the pages. No browser (D16), so the Cloudflare build can run it.
// - Tracing follows the cascade the way a browser would, but only for what the site's CSS does:
//   `font` and `font-family`/`-weight`/`-style`, `text-transform`, var() from :root, @media. Anything
//   else that could change which font draws text (generated text, a font set on :hover, an unknown
//   selector) fails the build, so a trace is never a guess.
// - A variable font whose @font-face names one weight is pinned to it (Bricolage Grotesque at 700);
//   other axes stay, so headlines keep the optical size drawn for theirs.
// - Only FEATURES below are kept, with the glyphs and kerning they need.
// - A character the font doesn't have fails the build: it would show in the fallback font.
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, unlinkSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { selectOne, is } from 'css-select';
import { parse as parseSelector } from 'css-what';
import * as hb from 'harfbuzzjs';
import { parseDocument } from 'htmlparser2';
import postcss from 'postcss';
import subsetFont from 'subset-font';

// OpenType features to keep: the ones browsers turn on by default for English text. The others
// (tabular and fraction digits, other languages' letterforms) need CSS the site doesn't use, and
// their glyphs and kerning cost 8 to 14% of each file. Using one means adding it here.
const FEATURES = ['ccmp', 'rlig', 'mark', 'mkmk', 'kern', 'liga', 'clig', 'calt'];

const TRACED = ['font-family', 'font-weight', 'font-style', 'text-transform'];
const DYNAMIC = /:(hover|focus|focus-visible|focus-within|active|visited|target|checked)\b/;
// The parts of the browser's own stylesheet that set these, for the elements a page might use.
const UA = `
h1, h2, h3, h4, h5, h6, b, strong, th { font-weight: bolder; }
em, i, cite, var, dfn, address { font-style: italic; }
code, kbd, samp, pre { font-family: monospace; }
button, input, select, textarea { font-family: system-ui; font-weight: 400; font-style: normal; }
`;

const fail = (message) => {
  throw new Error(`fonts.mjs: ${message}`);
};

// Specificity as [ids, classes, types], from css-what's tokens.
const specificity = (tokens) => {
  const s = [0, 0, 0];
  for (const t of tokens) {
    if (t.type === 'attribute' && t.name === 'id' && t.action === 'equals') s[0]++;
    else if (t.type === 'attribute') s[1]++;
    else if (t.type === 'tag' || t.type === 'pseudo-element') s[2]++;
    else if (t.type === 'pseudo' && t.name === 'where') continue;
    else if (t.type === 'pseudo' && Array.isArray(t.data)) {
      const inner = t.data.map(specificity).sort(compare).at(-1) ?? [0, 0, 0];
      inner.forEach((n, i) => (s[i] += n));
    } else if (t.type === 'pseudo') s[1]++;
  }
  return s;
};
const compare = (a, b) => a[0] - b[0] || a[1] - b[1] || a[2] - b[2];
// Cascade order: [important, author over UA, ...specificity, source order]; a tie goes to the later
// declaration in the same rule.
const outranks = (a, b) => {
  const i = a.findIndex((n, j) => n !== b[j]);
  return i === -1 || a[i] > b[i];
};

// Rules from a stylesheet: each selector with its specificity, declarations, @media condition and
// source order. Checks for what the trace doesn't handle on the way.
const readRules = (css, origin, rules) => {
  postcss.parse(css).walkRules((rule) => {
    const at = rule.parent.type === 'atrule' ? rule.parent : null;
    if (at && at.name !== 'media') return; // @font-face has no rules; @keyframes can't set fonts here
    const decls = rule.nodes.filter((n) => n.type === 'decl');
    const sets = decls.some((d) => d.prop === 'font' || TRACED.includes(d.prop));
    for (const d of decls) {
      if (d.prop === 'content' && /"[^"]+"|'[^']+'|attr\(|counter/.test(d.value)) fail(`${origin}: "${rule.selector} { content: ${d.value} }" adds text the trace can't follow`);
    }
    const selectors = [];
    for (const selector of rule.selectors) {
      if (/::?(before|after|marker|first-line|first-letter|placeholder)\b/.test(selector)) continue;
      if (DYNAMIC.test(selector)) {
        if (sets) fail(`${origin}: "${selector}" changes the font on interaction, which the trace can't follow`);
        continue;
      }
      selectors.push({ selector, specificity: specificity(parseSelector(selector)[0]) });
    }
    if (selectors.length) rules.push({ selectors, decls, media: at?.params ?? null, ua: origin === 'UA', order: rules.length });
  });
};

// font: [style] [variant] [weight] [stretch] size[/line-height] family, after var() is resolved.
const expandFont = (value) => {
  if (value === 'inherit') return { 'font-family': 'inherit', 'font-weight': 'inherit', 'font-style': 'inherit' };
  const m = value.match(/^((?:[\w-]+\s+)*?)(\d*\.?\d+(?:px|rem|em|%)|[a-z-]+)(?:\s*\/\s*[\d.]+[a-z%]*)?\s+(.+)$/i);
  if (!m) fail(`can't read "font: ${value}"`);
  const out = { 'font-family': m[3], 'font-weight': '400', 'font-style': 'normal' };
  for (const word of m[1].trim().split(/\s+/).filter(Boolean)) {
    if (/^(italic|oblique)$/.test(word)) out['font-style'] = word;
    else if (/^(\d{3}|bold|bolder|lighter)$/.test(word)) out['font-weight'] = word;
  }
  return out;
};

const families = (value) => value.split(',').map((f) => f.trim().replace(/^["']|["']$/g, '').toLowerCase());

const resolveWeight = (value, parent) => {
  if (value === 'inherit') return parent;
  if (value === 'normal') return 400;
  if (value === 'bold') return 700;
  if (value === 'bolder') return parent < 350 ? 400 : parent < 550 ? 700 : 900;
  if (value === 'lighter') return parent < 550 ? 100 : parent < 750 ? 400 : 700;
  const n = Number(value);
  if (!Number.isFinite(n)) fail(`can't read "font-weight: ${value}"`);
  return n;
};

// CSS font matching (Fonts 4, 5.2) on weight: the face a browser picks for the weight asked for.
const matchWeight = (faces, wanted) => {
  const ws = [...new Set(faces.map((f) => f.weight))].sort((a, b) => a - b);
  const up = ws.filter((w) => w >= wanted);
  const down = ws.filter((w) => w < wanted).reverse();
  let order;
  if (wanted >= 400 && wanted <= 500) order = [...up.filter((w) => w <= 500), ...down, ...up.filter((w) => w > 500)];
  else if (wanted < 400) order = [...down, ...up];
  else order = [...up, ...down];
  return faces.find((f) => f.weight === order[0]);
};

// Every combination of the stylesheet's @media conditions on and off, since a page can be seen in
// any of them.
const scenarios = (rules) => {
  const media = [...new Set(rules.map((r) => r.media).filter(Boolean))];
  return Array.from({ length: 2 ** media.length }, (_, i) => new Set(media.filter((_, j) => i & (1 << j))));
};

// Characters each face draws on one page, as Map(face → Map(character → page)).
const tracePage = (page, html, dist, faces, used) => {
  const doc = parseDocument(html);
  const rules = [];
  readRules(UA, 'UA', rules);
  const elements = (node, out = []) => {
    for (const child of node.children ?? []) if (child.type === 'tag' || child.type === 'style' || child.type === 'script') out.push(child, ...elements(child));
    return out;
  };
  for (const el of elements(doc)) {
    if (el.name === 'style') readRules(el.children.map((c) => c.data).join(''), page, rules);
    if (el.name === 'link' && /\bstylesheet\b/.test(el.attribs.rel ?? '')) readRules(readFileSync(join(dist, el.attribs.href), 'utf8'), el.attribs.href, rules);
  }
  const body = selectOne('body', doc);
  if (!body) return;

  for (const active of scenarios(rules)) {
    const live = rules.filter((r) => !r.media || active.has(r.media));
    // Custom properties come from :root only; one set anywhere else would make the trace wrong.
    const vars = new Map();
    const rootDecls = [];
    for (const r of live) {
      for (const d of r.decls.filter((d) => d.prop.startsWith('--'))) {
        const s = r.selectors.filter((x) => x.selector.trim().startsWith(':root'));
        if (!s.length) fail(`${page}: "${r.selectors[0].selector}" sets ${d.prop}; the trace reads custom properties from :root only`);
        rootDecls.push({ d, specificity: s.map((x) => x.specificity).sort(compare).at(-1), order: r.order });
      }
    }
    rootDecls.sort((a, b) => compare(a.specificity, b.specificity) || a.order - b.order).forEach(({ d }) => vars.set(d.prop, d.value));
    const resolve = (value) => value.replace(/var\((--[\w-]+)\s*(?:,\s*([^)]*))?\)/g, (_, name, fallback) => vars.get(name) ?? fallback ?? fail(`${page}: var(${name}) isn't defined`));

    const walk = (el, inherited) => {
      const winners = {};
      for (const r of live) {
        const hits = r.selectors.filter((s) => {
          try {
            return is(el, s.selector);
          } catch {
            fail(`${page}: can't match selector "${s.selector}"`);
          }
        });
        if (!hits.length) continue;
        const spec = hits.map((s) => s.specificity).sort(compare).at(-1);
        for (const d of r.decls) {
          const longhands = d.prop === 'font' ? expandFont(resolve(d.value)) : TRACED.includes(d.prop) ? { [d.prop]: resolve(d.value) } : {};
          for (const [prop, value] of Object.entries(longhands)) {
            const rank = [d.important ? 1 : 0, r.ua ? 0 : 1, ...spec, r.order];
            if (!winners[prop] || outranks(rank, winners[prop].rank)) winners[prop] = { value, rank };
          }
        }
      }
      const pick = (prop) => (winners[prop] && winners[prop].value !== 'inherit' ? winners[prop].value : inherited[prop]);
      const style = {
        'font-family': pick('font-family'),
        'font-weight': resolveWeight(winners['font-weight']?.value ?? 'inherit', inherited['font-weight']),
        'font-style': pick('font-style'),
        'text-transform': pick('text-transform'),
      };
      const family = families(style['font-family'])[0];
      const candidates = faces.filter((f) => f.family === family);
      const face = candidates.length ? matchWeight(candidates, style['font-weight']) : null;
      for (const child of el.children ?? []) {
        if (child.type === 'text' && face) {
          let text = child.data.replace(/[\t\n\r]/g, ' ');
          if (style['text-transform'] === 'uppercase') text = text.toUpperCase();
          else if (style['text-transform'] === 'lowercase') text = text.toLowerCase();
          else if (style['text-transform'] === 'capitalize') text += text.toUpperCase();
          const chars = used.get(face);
          for (const c of text) if (!chars.has(c)) chars.set(c, page);
        } else if (child.type === 'tag' && !['script', 'style', 'template', 'noscript'].includes(child.name)) {
          walk(child, style);
        }
      }
    };
    walk(body, { 'font-family': 'serif', 'font-weight': 400, 'font-style': 'normal', 'text-transform': 'none' });
  }
};

// The page's web fonts: each @font-face that loads a file from the build.
const readFaces = (html) => {
  const faces = [];
  for (const css of html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/g)) {
    postcss.parse(css[1]).walkAtRules('font-face', (at) => {
      const get = (prop) => at.nodes.find((n) => n.prop === prop)?.value;
      const url = get('src')?.match(/url\(\s*["']?(\/_astro\/[^"')]+\.woff2)/)?.[1];
      if (!url) return;
      const weight = get('font-weight') ?? '400';
      if (!/^\d{3}$/.test(weight)) fail(`@font-face for ${url} needs one numeric font-weight, not "${weight}"`);
      faces.push({ family: families(get('font-family'))[0], weight: Number(weight), url });
    });
  }
  return faces;
};

const hash = (bytes) => createHash('sha256').update(bytes).digest('base64url').slice(0, 8);
const kb = (n) => `${(n / 1024).toFixed(1)} KB`;
const unicodes = (sfnt) => new Set(new hb.Face(new hb.Blob(sfnt)).collectUnicodes());

export const subsetFonts = () => ({
  name: 'hutch:subset-fonts',
  hooks: {
    'astro:build:done': async ({ dir, logger }) => {
      const dist = fileURLToPath(dir);
      const pages = readdirSync(dist, { recursive: true }).filter((f) => f.endsWith('.html')).sort();
      const html = new Map(pages.map((p) => [p, readFileSync(join(dist, p), 'utf8')]));
      const faces = [...new Map(pages.flatMap((p) => readFaces(html.get(p))).map((f) => [f.url, f])).values()];
      const used = new Map(faces.map((f) => [f, new Map()]));
      for (const page of pages) tracePage(page, html.get(page), dist, faces, used);

      // Everything is computed before dist/ changes, so a failure leaves the build as Astro wrote it.
      const outputs = [];
      for (const face of faces) {
        const source = readFileSync(join(dist, face.url));
        const options = { keepFeatures: FEATURES };
        if ('wght' in new hb.Face(new hb.Blob(await subsetFont(source, ' ', { targetFormat: 'sfnt' }))).getAxisInfos()) options.variationAxes = { wght: face.weight };
        // A character the file doesn't have is drawn by the next font in the stack whatever we do;
        // it's reported, since it shows in a different typeface.
        const have = unicodes(await subsetFont(source, [...used.get(face).keys()].join(''), { targetFormat: 'sfnt' }));
        const missing = [...used.get(face)].filter(([c]) => c.codePointAt(0) > 0x20 && !have.has(c.codePointAt(0)));
        for (const [c, page] of missing) logger.warn(`${face.family} ${face.weight} has no "${c}" (U+${c.codePointAt(0).toString(16).toUpperCase().padStart(4, '0')}, ${page}): it shows in the fallback font`);
        const chars = [...used.get(face).keys()].filter((c) => have.has(c.codePointAt(0))).sort().join('');
        const out = await subsetFont(source, chars, { ...options, targetFormat: 'woff2' });
        outputs.push({ face, out, url: face.url.replace(/\.[\w-]+\.woff2$/, `.${hash(out)}.woff2`), from: source.length, count: [...chars].length });
      }
      const renames = [];
      for (const { face, out, url, from, count } of outputs) {
        writeFileSync(join(dist, url), out);
        unlinkSync(join(dist, face.url));
        renames.push([basename(face.url), basename(url)]);
        logger.info(`${basename(url)}: ${kb(from)} → ${kb(out.length)}, ${count} characters`);
      }
      for (const [page, text] of html) {
        const updated = renames.reduce((t, [from, to]) => t.replaceAll(from, to), text);
        if (updated !== text) writeFileSync(join(dist, page), updated);
      }
    },
  },
});
