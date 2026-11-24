require 'rails_helper'

RSpec.describe CustomFilter, type: :model do
  describe 'validations' do
    let(:account) { Fabricate(:account) }

    it 'is valid with a phrase up to the length limit' do
      filter = CustomFilter.new(account: account, context: %w(home), phrase: 'a' * CustomFilter::KEYWORD_LENGTH_LIMIT)
      expect(filter).to be_valid
    end

    it 'is invalid with a phrase over the length limit' do
      filter = CustomFilter.new(account: account, context: %w(home), phrase: 'a' * (CustomFilter::KEYWORD_LENGTH_LIMIT + 1))
      expect(filter).to_not be_valid
      expect(filter.errors[:phrase]).to be_present
    end
  end
end
