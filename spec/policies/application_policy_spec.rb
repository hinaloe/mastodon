# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject { described_class.new(user.account, nil) }

  context 'with an enabled admin' do
    let(:user) { Fabricate(:user, admin: true) }

    it 'grants staff permissions' do
      expect(subject.send(:admin?)).to be true
      expect(subject.send(:staff?)).to be true
    end
  end

  context 'with a disabled admin' do
    let(:user) { Fabricate(:user, admin: true, disabled: true) }

    it 'does not grant staff permissions' do
      expect(subject.send(:admin?)).to be false
      expect(subject.send(:moderator?)).to be false
      expect(subject.send(:staff?)).to be false
    end
  end

  context 'with a disabled moderator' do
    let(:user) { Fabricate(:user, moderator: true, disabled: true) }

    it 'does not grant staff permissions' do
      expect(subject.send(:moderator?)).to be false
      expect(subject.send(:staff?)).to be false
    end
  end
end
