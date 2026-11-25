# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Measure::InstanceAccountsMeasure do
  subject(:measure) { described_class.new(start_at, end_at, params) }

  let(:domain) { 'example.com' }

  let(:start_at) { 2.days.ago }
  let(:end_at)   { Time.now.utc }

  let(:params) { ActionController::Parameters.new(domain: domain) }

  before do
    Fabricate(:account, domain: domain, created_at: 1.year.ago)
    Fabricate(:account, domain: domain)
    Fabricate(:account, domain: domain)

    Fabricate(:account, domain: "foo.#{domain}")
  end

  describe 'total' do
    it 'returns the expected number of accounts' do
      expect(measure.total).to eq 3
    end
  end

  describe '#data' do
    it 'returns the accounts of each day' do
      expect(measure.data.size).to eq 3
      expect(measure.data.last[:value]).to eq '2'
    end
  end
end
