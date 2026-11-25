# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Measure::InstanceReportsMeasure do
  subject(:measure) { described_class.new(start_at, end_at, params) }

  let(:domain) { 'example.com' }

  let(:start_at) { 2.days.ago }
  let(:end_at)   { Time.now.utc }

  let(:params) { ActionController::Parameters.new(domain: domain) }

  before do
    Fabricate(:report, target_account: Fabricate(:account, domain: domain))
    Fabricate(:report, target_account: Fabricate(:account, domain: domain))

    Fabricate(:report, target_account: Fabricate(:account, domain: "foo.#{domain}"))
  end

  describe 'total' do
    it 'returns the expected number of reports' do
      expect(measure.total).to eq 2
    end
  end

  describe '#data' do
    it 'returns the reports of each day' do
      expect(measure.data.size).to eq 3
      expect(measure.data.last[:value]).to eq '2'
    end
  end
end
