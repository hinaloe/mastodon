# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ed25519KeyValidator, type: :validator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :key

      validates :key, ed25519_key: true

      def self.name
        'Ed25519KeyRecord'
      end
    end
  end

  let(:record) { record_class.new.tap { |r| r.key = key } }

  context 'with a valid public key' do
    let(:key) { Base64.strict_encode64(Ed25519::SigningKey.generate.verify_key.to_bytes) }

    it 'is valid' do
      expect(record).to be_valid
    end
  end

  context 'with a key of the wrong length' do
    let(:key) { Base64.strict_encode64('too short') }

    it 'is invalid' do
      expect(record).to_not be_valid
      expect(record.errors[:key]).to eq [I18n.t('crypto.errors.invalid_key')]
    end
  end

  context 'with a blank key' do
    let(:key) { '' }

    it 'is left to other validators' do
      expect(record).to be_valid
    end
  end
end
