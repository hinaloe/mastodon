/* Writes a gzip-compressed copy next to each built text asset, like Webpack's
   CompressionPlugin did. Rails (RAILS_SERVE_STATIC_FILES) and nginx
   (gzip_static) serve these to clients that accept gzip.
*/

import fs from 'node:fs';
import path from 'node:path';
import { gzipSync } from 'node:zlib';

import type { Plugin } from 'vite';

const COMPRESSIBLE = /\.(js|css|html|json|ico|svg|eot|otf|ttf|map)$/;

export function MastodonCompress(): Plugin {
  return {
    name: 'mastodon-compress',
    apply: 'build',
    enforce: 'post',
    writeBundle(options, bundle) {
      const outDir = options.dir;
      if (!outDir) return;

      for (const fileName of Object.keys(bundle)) {
        if (!COMPRESSIBLE.test(fileName)) continue;

        const filePath = path.resolve(outDir, fileName);
        if (!fs.existsSync(filePath)) continue;

        fs.writeFileSync(`${filePath}.gz`, gzipSync(fs.readFileSync(filePath), { level: 9 }));
      }
    },
  };
}
