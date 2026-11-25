# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::Field do
  describe '#value_for_verification' do
    it 'uses the plain text of a remote field, with entities decoded' do
      account = Fabricate(:account, domain: 'remote.example')
      field = described_class.new(account, 'name' => 'Website', 'value' => '<a href="https://example.com/?a=1&amp;b=2" rel="me">https://example.com/?a=1&amp;b=2</a>')

      expect(field.value_for_verification).to eq 'https://example.com/?a=1&b=2'
    end
  end
end
