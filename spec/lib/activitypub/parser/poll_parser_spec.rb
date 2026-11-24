# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::Parser::PollParser do
  subject { described_class.new(json) }

  let(:json) do
    {
      'type' => 'Question',
      'anyOf' => Array.new(described_class::MAX_ITEMS + 1) { |i| { 'type' => 'Note', 'name' => "option #{i}", 'replies' => { 'type' => 'Collection', 'totalItems' => 0 } } },
    }
  end

  it 'truncates the number of poll options' do
    expect(subject.options.size).to eq described_class::MAX_ITEMS
    expect(subject.cached_tallies.size).to eq described_class::MAX_ITEMS
  end
end
