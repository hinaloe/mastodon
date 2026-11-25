# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe 'otp_secret' do
    it 'is not a database column, so the secret is only stored encrypted' do
      expect(described_class.column_names).to_not include('otp_secret')
      expect(described_class.ignored_columns).to include('otp_secret')
    end
  end
end
