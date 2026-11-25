# frozen_string_literal: true

# Active Record Encryption is used by devise-two-factor to store the OTP
# secrets of users (users.otp_secret).
#
# Generate the keys once with `bin/rails db:encryption:init` and set them in the
# environment of the Rails processes (web, sidekiq, tootctl and migrations;
# not streaming). Never change or lose them: the secrets encrypted with them
# could not be decrypted anymore.
%w(
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
).each do |key|
  # Fixed keys for development and tests, and placeholders while compiling
  # assets during the image build
  ENV[key] ||= "#{key.downcase}_DO_NOT_USE_IN_PRODUCTION" if Rails.env.local? || ENV['SECRET_KEY_BASE_DUMMY']

  value = ENV.fetch(key, '')

  if value.blank?
    abort <<~MESSAGE

      Mastodon now requires that these variables are set:

        - ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
        - ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
        - ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY

      Run `bin/rails db:encryption:init` to generate new secrets and then assign the environment variables.
      Do not change the secrets once they are set, as doing so may cause data loss and other issues that will be difficult or impossible to recover from.
    MESSAGE
  end

  next unless Rails.env.production? && !ENV['SECRET_KEY_BASE_DUMMY'] && value.end_with?('DO_NOT_USE_IN_PRODUCTION')

  abort <<~MESSAGE

    It looks like you are trying to run Mastodon in production with a #{key} value from the test environment.

    Please generate fresh secrets using `bin/rails db:encryption:init` and use them instead.
  MESSAGE
end

# Configure the encryption directly: `config.active_record.encryption` is
# applied by an on_load hook that may already have run when this initializer
# is loaded. This hook runs right away if Active Record Encryption is loaded,
# and otherwise after Rails' own one.
ActiveSupport.on_load(:active_record_encryption) do
  ActiveRecord::Encryption.configure(
    primary_key: ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'),
    deterministic_key: ENV.fetch('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY'),
    key_derivation_salt: ENV.fetch('ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'),
    # No data was encrypted before this release: use SHA256 from the start,
    # so no SHA1-compatibility setting is ever needed (upstream had to add one).
    hash_digest_class: OpenSSL::Digest::SHA256,
    support_sha1_for_non_deterministic_encryption: false
  )
end
