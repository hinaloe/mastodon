# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ed25519SignatureValidator, type: :validator do
  let(:signing_key) { Ed25519::SigningKey.generate }

  let(:record_class) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :message, :signature, :verify_key

      validates :signature, ed25519_signature: { message: :message, verify_key: :verify_key }

      def self.name
        'Ed25519SignatureRecord'
      end
    end
  end

  let(:record) do
    record_class.new.tap do |r|
      r.message    = 'hello'
      r.verify_key = Base64.strict_encode64(signing_key.verify_key.to_bytes)
      r.signature  = signature
    end
  end

  context 'with a valid signature' do
    let(:signature) { Base64.strict_encode64(signing_key.sign('hello')) }

    it 'is valid' do
      expect(record).to be_valid
    end
  end

  context 'with a signature of another message' do
    let(:signature) { Base64.strict_encode64(signing_key.sign('goodbye')) }

    it 'is invalid' do
      expect(record).to_not be_valid
      expect(record.errors[:signature]).to eq [I18n.t('crypto.errors.invalid_signature')]
    end
  end

  context 'with a signature by another key' do
    let(:signature) { Base64.strict_encode64(Ed25519::SigningKey.generate.sign('hello')) }

    it 'is invalid' do
      expect(record).to_not be_valid
    end
  end
end
