# frozen_string_literal: true

# Copies the OTP secrets of users with two-factor authentication from the
# attr_encrypted columns to `users.otp_secret` (Active Record Encryption),
# as upstream did in #29548. The legacy columns keep the same secret (they
# are written again with a new IV and salt by LegacyOtpSecret), so the
# previous release can still read them.
class MigrateDeviseTwoFactorSecrets < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  class MigrationUser < ApplicationRecord
    self.table_name = :users

    devise :two_factor_authenticatable,
           otp_secret_encryption_key: Rails.configuration.x.otp_secret

    include LegacyOtpSecret # Must be after the above `devise` line in order to override the legacy method
  end

  def up
    MigrationUser.reset_column_information

    users_with_otp_enabled.find_each do |user|
      # Falls back to the legacy value for users that are not migrated yet
      otp_secret = begin
        user.otp_secret
      rescue OpenSSL::OpenSSLError
        next if ENV['MIGRATION_IGNORE_INVALID_OTP_SECRET'] == 'true'

        abort_with_decryption_error(user)
      end

      user.update!(otp_secret: otp_secret)

      # Make sure the stored value can be read back with this process's keys.
      # This does not check that web and sidekiq use the same keys.
      abort_with_verification_error(user) unless MigrationUser.find(user.id)[:otp_secret] == otp_secret
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def users_with_otp_enabled
    MigrationUser.where(otp_required_for_login: true, otp_secret: nil)
  end

  def abort_with_verification_error(user)
    abort <<~MESSAGE

      ERROR: The OTP secret stored for user #{user.id} could not be read back with the
      Active Record Encryption settings of this process.

      Check the ACTIVE_RECORD_ENCRYPTION_* variables, then run the migration again. Make sure
      the web, sidekiq and tootctl processes use the same values: this migration cannot check that.

      Migration aborted.
    MESSAGE
  end

  def abort_with_decryption_error(user)
    abort <<~MESSAGE

      ERROR: Unable to decrypt OTP secret for user #{user.id}.

      This is most likely because you have changed the value of `OTP_SECRET` at some point in
      time after the user configured 2FA.

      In this case, their OTP secret had already been lost with the change to `OTP_SECRET`, and
      proceeding with this migration will not make the situation worse.

      Please double-check that you have not accidentally changed `OTP_SECRET` just for this
      migration, and re-run the migration with `MIGRATION_IGNORE_INVALID_OTP_SECRET=true`.

      Migration aborted.
    MESSAGE
  end
end
