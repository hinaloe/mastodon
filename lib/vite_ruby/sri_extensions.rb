# frozen_string_literal: true

# Adds Subresource Integrity to the tags rendered by vite_rails, like
# lib/webpacker/helper_extensions.rb did for Webpacker.
#
# The hashes are written to the Vite manifests by
# config/vite/plugin-manifest-sri.mts. They are not available from the dev
# server, in which case the tags are rendered without them.

module ViteRuby::ManifestIntegrityExtension
  # Public: The integrity hash of a built file, from its public path
  # (the `file` of a manifest entry, e.g. "/packs/assets/application-1a2b3c.js").
  def integrity_for(path)
    return if dev_server_running?

    integrity_by_file[path]
  end

  # Public: The manifest entry for a source file that is not an entrypoint,
  # such as a lazily loaded chunk ("mastodon/features/compose/index.js").
  def lookup_chunk(name)
    lookup(name, type: :virtual)
  end

  private

  def integrity_by_file
    current = manifest
    return @integrity_by_file if @integrity_by_file && @integrity_manifest.equal?(current)

    @integrity_manifest = current
    @integrity_by_file = current.each_value.with_object({}) do |entry, map|
      map[entry['file']] = entry['integrity'] if entry['integrity']
    end
  end
end

ViteRuby::Manifest.prepend ViteRuby::ManifestIntegrityExtension

module ViteRails::TagHelpers::IntegrityExtension
  def vite_javascript_tag(*names,
                          type: 'module',
                          asset_type: :javascript,
                          skip_preload_tags: false,
                          skip_style_tags: false,
                          crossorigin: 'anonymous',
                          media: 'all',
                          **options)
    entries = vite_manifest.resolve_entries(*names, type: asset_type)

    ''.html_safe.tap do |tags|
      entries.fetch(:scripts).each do |script|
        tags << javascript_include_tag(script, integrity: vite_manifest.integrity_for(script), crossorigin: crossorigin, type: type, extname: false, **options)
      end

      unless skip_preload_tags
        entries.fetch(:imports).each do |import|
          tags << vite_integrity_preload_tag(import, crossorigin: crossorigin)
        end
      end

      unless skip_style_tags
        entries.fetch(:stylesheets).each do |stylesheet|
          tags << stylesheet_link_tag(stylesheet, integrity: vite_manifest.integrity_for(stylesheet), media: media, crossorigin: crossorigin, **vite_stylesheet_extname_option)
        end
      end
    end
  end

  def vite_stylesheet_tag(*names, crossorigin: 'anonymous', **options)
    ''.html_safe.tap do |tags|
      names.each do |name|
        path = vite_manifest.path_for(name, type: :stylesheet)

        tags << stylesheet_link_tag(path, integrity: vite_manifest.integrity_for(path), crossorigin: crossorigin, **vite_stylesheet_extname_option, **options)
      end
    end
  end

  # Public: Renders a modulepreload tag for a lazily loaded chunk, identified
  # by its source path relative to app/javascript.
  def vite_preload_chunk_tag(name, crossorigin: 'anonymous')
    entry = vite_manifest.lookup_chunk(name)
    return if entry.nil?

    vite_integrity_preload_tag(entry['file'], crossorigin: crossorigin)
  end

  private

  # Rails 6.1 does not know the extname option for stylesheets and would
  # render it as an attribute; the paths already have an extension.
  def vite_stylesheet_extname_option
    Rails::VERSION::MAJOR >= 7 ? { extname: false } : {}
  end

  def vite_integrity_preload_tag(source, crossorigin:)
    tag.link(rel: 'modulepreload', href: path_to_asset(source), as: 'script', crossorigin: crossorigin, integrity: vite_manifest.integrity_for(source))
  end
end

ViteRails::TagHelpers.prepend ViteRails::TagHelpers::IntegrityExtension
