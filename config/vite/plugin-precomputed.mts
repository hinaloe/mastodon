/* Provides data that used to be computed at build time with
   `babel-plugin-preval`:

   - `virtual:mastodon-emoji-compressed`: the compressed emoji data built by
     `app/javascript/mastodon/features/emoji/emoji_compressed.js`
   - `virtual:mastodon-sw-locales`: the few translations the service worker
     needs, built by `app/javascript/mastodon/service_worker/web_push_locales.js`

   Both scripts are plain Node.js (CommonJS) programs; they are executed here
   and only their result is bundled.
*/

import { createRequire } from 'node:module';
import path from 'node:path';

import type { Plugin } from 'vite';

const MODULES: Record<string, string> = {
  'virtual:mastodon-emoji-compressed':
    'mastodon/features/emoji/emoji_compressed.js',
  'virtual:mastodon-sw-locales': 'mastodon/service_worker/web_push_locales.js',
};

export function MastodonPrecomputed({ root }: { root: string }): Plugin {
  const require = createRequire(import.meta.url);

  return {
    name: 'mastodon-precomputed',
    resolveId(id) {
      if (id in MODULES) {
        return `\0${id}`;
      }

      return undefined;
    },
    load(id) {
      if (!id.startsWith('\0')) {
        return undefined;
      }

      const script = MODULES[id.slice(1)];

      if (!script) {
        return undefined;
      }

      const scriptPath = path.resolve(root, script);
      this.addWatchFile(scriptPath);

      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const data: unknown = require(scriptPath);

      return `export default ${JSON.stringify(data)};`;
    },
  };
}
