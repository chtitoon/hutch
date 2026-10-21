// Static output only (D14): no adapter, no server rendering.
import { defineConfig } from 'astro/config';
import { subsetFonts } from './fonts.mjs';

export default defineConfig({
  // After the build, each web font is cut down to the characters it draws (PERFORMANCE.md, "Fonts").
  integrations: [subsetFonts()],
  site: 'https://myhutch.app',
  output: 'static',
  trailingSlash: 'never',
  // The one stylesheet goes inline in each page: a separate file blocked the first paint by
  // a full round trip on mobile (PERFORMANCE.md, D19).
  build: { format: 'file', inlineStylesheets: 'always' },
});
