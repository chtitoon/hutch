// Static output only (D14): no adapter, no server rendering.
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://myhutch.app',
  output: 'static',
  trailingSlash: 'never',
  // The one stylesheet goes inline in each page: a separate file blocked the first paint by
  // a full round trip on mobile (PERFORMANCE.md, D18).
  build: { format: 'file', inlineStylesheets: 'always' },
});
