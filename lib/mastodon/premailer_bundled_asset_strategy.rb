# frozen_string_literal: true

module PremailerBundledAssetStrategy
  def load(url)
    asset_host = ENV['CDN_HOST'] || ENV['WEB_DOMAIN'] || ENV['LOCAL_DOMAIN']
    # WEB_DOMAIN and LOCAL_DOMAIN are bare host names
    asset_host = "#{Rails.configuration.x.use_https ? 'https' : 'http'}://#{asset_host}" unless asset_host.blank? || asset_host.include?('://')

    css = if ViteRuby.instance.dev_server_running? && !url.start_with?('http')
            # The dev server serves the stylesheet as a JS module unless CSS is requested explicitly
            HTTP.headers(accept: 'text/css').get(File.join(ViteRuby.config.origin, url)).to_s
          elsif url.start_with?('http')
            HTTP.get(url).to_s
          else
            Rails.public_path.join(url.delete_prefix('/')).read
          end

    # Vite emits URLs relative to the stylesheet; make them absolute paths first
    base_path = File.dirname(URI.parse(url).path)
    css = css.gsub(%r{url\((['"]?)(?![a-z]+:|/|#)([^'")]+)\1\)}i) { "url(#{Regexp.last_match(1)}#{File.expand_path(Regexp.last_match(2), base_path)}#{Regexp.last_match(1)})" }

    css.gsub(%r{url\((['"]?)/(?!/)}, "url(\\1#{asset_host}/")
  end

  module_function :load
end
