require 'rails_helper'

RSpec.describe List, type: :model do
  describe 'validations' do
    let(:account) { Fabricate(:account) }

    it 'is valid with a title up to the length limit' do
      list = List.new(account: account, title: 'a' * List::TITLE_LENGTH_LIMIT)
      expect(list).to be_valid
    end

    it 'is invalid with a title over the length limit' do
      list = List.new(account: account, title: 'a' * (List::TITLE_LENGTH_LIMIT + 1))
      expect(list).to_not be_valid
      expect(list.errors[:title]).to be_present
    end
  end
end
