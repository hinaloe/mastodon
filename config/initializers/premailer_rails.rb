require_relative '../../lib/mastodon/premailer_bundled_asset_strategy'

Premailer::Rails.config.merge!(remove_ids: true,
                               adapter: :nokogiri,
                               generate_text_part: false,
                               strategies: [PremailerBundledAssetStrategy])
