# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ActionLog, type: :model do
  describe '#action' do
    it 'returns action' do
      action_log = described_class.new(action: 'hoge')
      expect(action_log.action).to be :hoge
    end
  end

  describe 'recorded_changes' do
    let(:account) { Fabricate(:account) }
    let(:target)  { Fabricate(:account) }

    def stored_value(action_log)
      described_class.connection.select_value("SELECT recorded_changes FROM admin_action_logs WHERE id = #{action_log.id}")
    end

    it 'stores an empty value for actions that do not record changes' do
      action_log = described_class.create!(account: account, action: :suspend, target: target)

      expect(stored_value(action_log)).to eq "--- ''\n"
      expect(action_log.reload.recorded_changes).to eq ''
    end

    it 'stores the attributes of created records' do
      action_log = described_class.create!(account: account, action: :create, target: target)

      expect(action_log.reload.recorded_changes).to include('username' => target.username)
    end
  end
end
