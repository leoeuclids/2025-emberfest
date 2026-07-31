import { ember, extensions } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import { defineConfig } from 'vite';

// Linked local @warp-drive/* packages (via root pnpm.overrides link:) live outside
// this project's root. Without deduping, Vite pre-bundles the app's own import of
// @warp-drive/core while the linked @warp-drive/ember resolves core through a
// different pipeline — two physical module instances trip WarpDrive's singleton
// guard ("Multiple copies of WarpDrive detected"). Force one copy: dedupe by name
// and skip pre-bundling so both resolve to the same source.
const warpDrivePackages = [
  '@warp-drive/core',
  '@warp-drive/ember',
  '@warp-drive/json-api',
  '@warp-drive/utilities',
];

export default defineConfig({
  resolve: {
    dedupe: warpDrivePackages,
  },
  optimizeDeps: {
    exclude: warpDrivePackages,
  },
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
  plugins: [
    ember(),
    babel({
      babelHelpers: 'runtime',
      extensions,
    }),
  ],
});
