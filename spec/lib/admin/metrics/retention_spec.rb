# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Retention do
  subject(:retention) { described_class.new(start_at, end_at, frequency) }

  let(:start_at)  { 2.days.ago.to_date }
  let(:end_at)    { Time.now.utc.to_date }
  let(:frequency) { 'day' }

  before do
    Fabricate(:user, created_at: Time.now.utc, current_sign_in_at: Time.now.utc)
    Fabricate(:user, created_at: Time.now.utc, current_sign_in_at: nil)
  end

  describe '#cohorts' do
    it 'returns a cohort for each day with the retained users of the current day' do
      cohorts = retention.cohorts

      expect(cohorts.size).to eq 3
      expect(cohorts.last.data.first.value).to eq '1'
      expect(cohorts.last.data.first.rate).to eq 0.5
    end
  end
end
