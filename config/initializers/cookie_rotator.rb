# frozen_string_literal: true

# Cookie keys are now derived with SHA256, the Rails 7.0 default. Cookies set
# by the previous releases were derived with SHA1: keep accepting them so
# users are not signed out. This rotation can be removed once those cookies
# have expired.
Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    authenticated_encrypted_cookie_salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
    signed_cookie_salt = Rails.application.config.action_dispatch.signed_cookie_salt

    secret_key_base = Rails.application.secret_key_base

    key_generator = ActiveSupport::KeyGenerator.new(
      secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    key_len = ActiveSupport::MessageEncryptor.key_len

    cookies.rotate :encrypted, key_generator.generate_key(authenticated_encrypted_cookie_salt, key_len)
    cookies.rotate :signed, key_generator.generate_key(signed_cookie_salt)
  end
end
