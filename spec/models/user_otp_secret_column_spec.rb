# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe 'otp_secret' do
    it 'is not a database column, so the secret is only stored encrypted' do
      expect(described_class.column_names).to_not include('otp_secret')
      expect(described_class.ignored_columns).to include('otp_secret')
    end

    context 'when the column added by the next release exists' do
      around do |example|
        described_class.connection.add_column :users, :otp_secret, :string
        example.run
      ensure
        described_class.connection.remove_column :users, :otp_secret
      end

      let(:user) { Fabricate(:user) }

      def newer_secret
        described_class.connection.select_value("SELECT otp_secret FROM users WHERE id = #{user.id}")
      end

      it 'never writes the secret into it' do
        user.update!(otp_secret: 'JBSWY3DPEHPK3PXP', otp_required_for_login: true)

        expect(newer_secret).to be_nil
        expect(user.reload.otp_secret).to eq 'JBSWY3DPEHPK3PXP'
      end

      it 'clears the copy stored by the next release when the secret changes' do
        described_class.connection.execute("UPDATE users SET otp_secret = 'stored-by-next-release' WHERE id = #{user.id}")

        user.update!(otp_secret: 'JBSWY3DPEHPK3PXP', otp_required_for_login: true)
        expect(newer_secret).to be_nil
      end

      it 'clears it when two-factor authentication is disabled' do
        user.update!(otp_secret: 'JBSWY3DPEHPK3PXP', otp_required_for_login: true)
        described_class.connection.execute("UPDATE users SET otp_secret = 'stored-by-next-release' WHERE id = #{user.id}")

        user.disable_two_factor!
        expect(newer_secret).to be_nil
      end
    end
  end
end
