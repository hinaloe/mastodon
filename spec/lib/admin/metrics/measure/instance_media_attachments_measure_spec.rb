# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Measure::InstanceMediaAttachmentsMeasure do
  subject(:measure) { described_class.new(start_at, end_at, params) }

  let(:domain) { 'example.com' }

  let(:start_at) { 2.days.ago }
  let(:end_at)   { Time.now.utc }

  let(:params) { ActionController::Parameters.new(domain: domain) }

  let!(:media_attachment) { Fabricate(:media_attachment, account: Fabricate(:account, domain: domain)) }

  before do
    Fabricate(:media_attachment, account: Fabricate(:account, domain: "foo.#{domain}"))
  end

  let(:expected_size) { media_attachment.file_file_size + (media_attachment.thumbnail_file_size || 0) }

  describe 'total' do
    it 'returns the size of the media attachments' do
      expect(measure.total).to eq expected_size
    end
  end

  describe '#data' do
    it 'returns the size of the media attachments of each day' do
      expect(measure.data.size).to eq 3
      expect(measure.data.last[:value]).to eq expected_size.to_s
    end
  end
end
