# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Measure::InstanceStatusesMeasure do
  subject(:measure) { described_class.new(start_at, end_at, params) }

  let(:domain) { 'example.com' }

  let(:start_at) { 2.days.ago }
  let(:end_at)   { Time.now.utc }

  let(:params) { ActionController::Parameters.new(domain: domain) }

  before do
    # Status IDs come from the database clock, which may be slightly ahead of
    # `end_at`; give them IDs from a few minutes ago so they are in range.
    Fabricate(:status, id: Mastodon::Snowflake.id_at(5.minutes.ago), account: Fabricate(:account, domain: domain))
    Fabricate(:status, id: Mastodon::Snowflake.id_at(5.minutes.ago), account: Fabricate(:account, domain: domain))

    Fabricate(:status, id: Mastodon::Snowflake.id_at(5.minutes.ago), account: Fabricate(:account, domain: "foo.#{domain}"))
  end

  describe 'total' do
    it 'returns the expected number of statuses' do
      expect(measure.total).to eq 2
    end
  end

  describe '#data' do
    it 'returns the statuses of each day' do
      expect(measure.data.size).to eq 3
      expect(measure.data.last[:value]).to eq '2'
    end
  end
end
