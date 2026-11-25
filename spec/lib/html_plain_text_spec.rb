# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HtmlPlainText do
  it 'removes tags and decodes entities' do
    expect(described_class.call('<p>Let&#39;s go &amp; see &lt;this&gt;</p>')).to eq "Let's go & see <this>"
  end

  it 'keeps the query string of links intact' do
    expect(described_class.call('<a href="https://example.com/?a=1&amp;b=2">https://example.com/?a=1&amp;b=2</a>')).to eq 'https://example.com/?a=1&b=2'
  end

  it 'accepts nil' do
    expect(described_class.call(nil)).to eq ''
  end
end
