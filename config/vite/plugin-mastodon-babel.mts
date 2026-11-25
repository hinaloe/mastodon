/* Transforms the web UI sources with Babel before Vite sees them.

   The sources still use JSX in `.js` files and legacy (TypeScript-style)
   class decorators such as `@connect(...)` and `@injectIntl`, which the
   default Vite pipeline does not understand. This plugin only compiles
   those two syntaxes (and, in production, strips prop-types and rewrites
   lodash imports to the individual functions); everything
   else is left to Vite, so the output keeps modern syntax.

   It also keeps `babel-plugin-react-intl`, which writes the default
   messages to `build/messages` for `yarn manage:translations`.
*/

import path from 'node:path';

import { transformAsync } from '@babel/core';
import type { Plugin } from 'vite';

export function MastodonBabel({ root }: { root: string }): Plugin {
  let production = false;

  return {
    name: 'mastodon-babel',
    enforce: 'pre',
    configResolved(config) {
      production = config.isProduction;
    },
    async transform(code, id) {
      const [filename] = id.split('?', 1);

      if (
        !filename ||
        !filename.endsWith('.js') ||
        !filename.startsWith(root + path.sep) ||
        filename.includes(`${path.sep}node_modules${path.sep}`)
      ) {
        return null;
      }

      const plugins: unknown[] = [
        ['@babel/plugin-proposal-decorators', { legacy: true }],
        ['@babel/plugin-transform-class-properties', { loose: true }],
        ['react-intl', { messagesDir: './build/messages' }],
      ];

      if (production) {
        // Import only the lodash functions that are used
        plugins.push('lodash');
        plugins.push([
          'transform-react-remove-prop-types',
          {
            mode: 'remove',
            removeImport: true,
            additionalLibraries: ['react-immutable-proptypes'],
          },
        ]);
      }

      const result = await transformAsync(code, {
        filename,
        babelrc: false,
        configFile: false,
        sourceMaps: true,
        presets: [['@babel/preset-react', { development: !production }]],
        plugins,
      });

      if (!result?.code) {
        return null;
      }

      return { code: result.code, map: result.map };
    },
  };
}
