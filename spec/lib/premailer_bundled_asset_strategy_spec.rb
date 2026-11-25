# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PremailerBundledAssetStrategy do
  around do |example|
    original = ENV.to_h.slice('CDN_HOST', 'WEB_DOMAIN', 'LOCAL_DOMAIN')
    example.run
  ensure
    %w(CDN_HOST WEB_DOMAIN LOCAL_DOMAIN).each { |key| ENV[key] = original[key] }
  end

  before do
    ENV['LOCAL_DOMAIN'] = 'example.com'
    ENV['WEB_DOMAIN'] = nil
    ENV['CDN_HOST'] = nil
    allow(Rails.configuration.x).to receive(:use_https).and_return(true)
  end

  describe '.asset_host' do
    it 'falls back to LOCAL_DOMAIN' do
      expect(described_class.asset_host).to eq 'https://example.com'
    end

    it 'prefers WEB_DOMAIN over LOCAL_DOMAIN' do
      ENV['WEB_DOMAIN'] = 'web.example.com'

      expect(described_class.asset_host).to eq 'https://web.example.com'
    end

    it 'ignores an empty CDN_HOST' do
      ENV['CDN_HOST'] = ''

      expect(described_class.asset_host).to eq 'https://example.com'
    end

    it 'uses a full CDN_HOST URL as is' do
      ENV['CDN_HOST'] = 'https://cdn.example.net'

      expect(described_class.asset_host).to eq 'https://cdn.example.net'
    end

    it 'adds the scheme to a protocol-relative CDN_HOST' do
      ENV['CDN_HOST'] = '//cdn.example.net'

      expect(described_class.asset_host).to eq 'https://cdn.example.net'
    end
  end

  describe '.load' do
    let(:stylesheet) { Rails.public_path.join('packs', 'premailer-spec', 'assets', 'mailer.css') }

    before do
      allow(ViteRuby.instance).to receive(:dev_server_running?).and_return(false)
      FileUtils.mkdir_p(stylesheet.dirname)
      stylesheet.write(<<~CSS)
        .a { background: url(logo.png); }
        .b { background: url('/packs/assets/icon.png'); }
        .c { background: url(//other.example/x.png); }
      CSS
    end

    after do
      FileUtils.rm_rf(Rails.public_path.join('packs', 'premailer-spec'))
    end

    it 'turns relative and root-relative URLs into absolute ones' do
      ENV['CDN_HOST'] = ''

      css = described_class.load('/packs/premailer-spec/assets/mailer.css')

      expect(css).to include('url(https://example.com/packs/premailer-spec/assets/logo.png)')
        .and include("url('https://example.com/packs/assets/icon.png')")
        .and include('url(//other.example/x.png)')
    end
  end
end
