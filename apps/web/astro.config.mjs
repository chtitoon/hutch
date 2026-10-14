// Static output only (D14): no adapter, no server rendering.
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://myhutch.app',
  output: 'static',
  trailingSlash: 'never',
  build: { format: 'file' },
});
