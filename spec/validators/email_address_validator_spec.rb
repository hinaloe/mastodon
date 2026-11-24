# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailAddressValidator do
  context 'with no options' do
    let(:record_class) do
      Class.new do
        include ActiveModel::Model

        def self.name
          'Record'
        end

        attr_accessor :email

        validates :email, email_address: true
      end
    end

    it 'considers a valid email address as such' do
      expect(record_class.new(email: 'foo@example.com')).to be_valid
    end

    it 'considers an address on localhost as valid' do
      expect(record_class.new(email: 'admin@localhost')).to be_valid
    end

    it 'considers an invalid email address as such' do
      expect(record_class.new(email: 'foo @ example.com')).to_not be_valid
    end

    it 'considers an email address with a % as invalid' do
      expect(record_class.new(email: 'foo@example.com%foo.example.com')).to_not be_valid
    end

    it 'considers an email address with a comma as invalid' do
      expect(record_class.new(email: 'foo@example.com,bar@example.com')).to_not be_valid
    end

    it 'considers an email address with a double quote as invalid' do
      expect(record_class.new(email: '"foo"@example.com')).to_not be_valid
    end
  end
end
