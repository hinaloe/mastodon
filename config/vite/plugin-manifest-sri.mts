/* Adds an `integrity` (SHA-384) to every entry of the manifests written by
   Vite and vite-plugin-ruby, which lib/vite_ruby/sri_extensions.rb uses to
   render Subresource Integrity attributes.
*/

import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

import type { Plugin } from 'vite';

const MANIFESTS = ['.vite/manifest.json', '.vite/manifest-assets.json'];

export function MastodonManifestSri(): Plugin {
  return {
    name: 'mastodon-manifest-sri',
    apply: 'build',
    enforce: 'post',
    writeBundle(options, bundle) {
      const outDir = options.dir;
      if (!outDir) return;

      const integrity = new Map<string, string>();

      // Hash the files as written, which may differ from the in-memory output
      // (for instance by the source map comment).
      for (const fileName of Object.keys(bundle)) {
        const filePath = path.resolve(outDir, fileName);
        if (!fs.existsSync(filePath)) continue;

        const digest = createHash('sha384')
          .update(fs.readFileSync(filePath))
          .digest('base64');
        integrity.set(fileName, `sha384-${digest}`);
      }

      for (const manifestName of MANIFESTS) {
        const manifestPath = path.resolve(outDir, manifestName);
        if (!fs.existsSync(manifestPath)) continue;

        const manifest = JSON.parse(
          fs.readFileSync(manifestPath, 'utf8'),
        ) as Record<string, { file: string; integrity?: string }>;

        for (const entry of Object.values(manifest)) {
          const hash = integrity.get(entry.file);
          if (hash) entry.integrity = hash;
        }

        fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
      }
    },
  };
}
