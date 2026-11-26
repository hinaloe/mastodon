/* Builds the service worker (`mastodon/service_worker/entry.js`) as a classic
   script at `public/assets/sw.js`, which is what `public/sw.js` links to and
   what the web UI registers. It used to be built by Webpack's OfflinePlugin.

   The service worker must keep a stable URL, so it is built separately from
   the hashed entrypoints, after the main build.
*/

import path from 'node:path';

import { build } from 'vite';
import type { Plugin, PluginOption } from 'vite';

export function MastodonServiceWorker({
  root,
  outDir,
  plugins,
}: {
  root: string;
  outDir: string;
  plugins: PluginOption[];
}): Plugin {
  let enabled = false;

  return {
    name: 'mastodon-service-worker',
    apply: 'build',
    configResolved(config) {
      enabled = !config.build.ssr;
    },
    async closeBundle() {
      if (!enabled) return;

      await build({
        configFile: false,
        root,
        publicDir: false,
        logLevel: 'warn',
        mode: 'production',
        plugins,
        build: {
          outDir,
          emptyOutDir: false,
          copyPublicDir: false,
          manifest: false,
          sourcemap: false,
          minify: true,
          rollupOptions: {
            input: path.resolve(root, 'mastodon/service_worker/entry.js'),
            output: {
              format: 'iife',
              entryFileNames: 'sw.js',
            },
          },
        },
      });
    },
  };
}
