import path from 'node:path';
import { fileURLToPath } from 'node:url';

import autoprefixer from 'autoprefixer';
import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';

import { MastodonBabel } from './config/vite/plugin-mastodon-babel.mts';
import { MastodonLocalePacks } from './config/vite/plugin-locale-packs.mts';
import { MastodonManifestSri } from './config/vite/plugin-manifest-sri.mts';
import { MastodonPrecomputed } from './config/vite/plugin-precomputed.mts';
import { MastodonServiceWorker } from './config/vite/plugin-service-worker.mts';

const projectRoot = path.dirname(fileURLToPath(import.meta.url));
const jsRoot = path.resolve(projectRoot, 'app/javascript');

// Chunk names used to come from `webpackChunkName` comments. Name the chunks
// after their directory instead of `index-<hash>.js` so they stay readable.
function chunkFileNames({
  facadeModuleId,
  name,
}: {
  facadeModuleId: string | null;
  name: string;
}) {
  if (facadeModuleId && name === 'index') {
    const parent = facadeModuleId.split('/').at(-2);

    if (parent) {
      return `assets/${parent}-[name]-[hash].js`;
    }
  }

  return 'assets/[name]-[hash].js';
}

export default defineConfig(({ command }) => ({
  resolve: {
    alias: [
      // Modules are imported as `mastodon/...` from anywhere in the sources.
      { find: /^mastodon\//, replacement: `${jsRoot}/mastodon/` },
    ],
  },
  css: {
    postcss: {
      plugins: [autoprefixer()],
    },
    preprocessorOptions: {
      scss: {
        // The stylesheets predate the Sass module system; keep the build
        // output readable until they are migrated.
        quietDeps: true,
        silenceDeprecations: [
          'import',
          'global-builtin',
          'slash-div',
          'color-functions',
        ],
      },
    },
  },
  experimental: {
    // Load lazy chunks and CSS assets relative to the file that references
    // them, so they follow the host the entrypoints were loaded from
    // (`CDN_HOST`), as Webpack's runtime public path did.
    renderBuiltUrl(_filename, { hostType }) {
      if (hostType === 'js' || hostType === 'css') {
        return { relative: true };
      }

      return undefined;
    },
  },
  build: {
    chunkSizeWarningLimit: 2 * 1024 * 1024,
    rollupOptions: {
      output: {
        chunkFileNames,
      },
    },
  },
  optimizeDeps: {
    // The dependency scanner of the dev server reads the sources before
    // MastodonBabel transforms them: let it parse JSX and legacy decorators.
    rolldownOptions: {
      moduleTypes: { '.js': 'jsx' },
      transform: { decorator: { legacy: true } },
    },
  },
  server: {
    // The dev server is reached through the Rails app in development.
    fs: { allow: [projectRoot] },
  },
  plugins: [
    // Must come before RubyPlugin, which collects the entrypoints.
    MastodonLocalePacks({ root: jsRoot, projectRoot }),
    RubyPlugin(),
    MastodonBabel({ root: jsRoot }),
    MastodonPrecomputed({ root: jsRoot }),
    MastodonManifestSri(),
    command === 'build' &&
      MastodonServiceWorker({
        root: jsRoot,
        outDir: path.resolve(projectRoot, 'public/assets'),
        plugins: [
          MastodonBabel({ root: jsRoot }),
          MastodonPrecomputed({ root: jsRoot }),
        ],
      }),
  ],
}));
