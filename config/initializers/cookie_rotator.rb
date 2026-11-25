# frozen_string_literal: true

# Rails 7.0 derives the cookie keys with SHA256 instead of SHA1. Switching
# directly would sign every user out, and cookies set by one version could not
# be read by the other during a rolling deploy.
#
# Keep SHA1 for now and accept cookies made with SHA256, so this release can
# read cookies from the next one. In a later release, switch to SHA256 and
# rotate SHA1 instead (as upstream did in #26023).
Rails.application.configure do
  config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
end

Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    authenticated_encrypted_cookie_salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
    signed_cookie_salt = Rails.application.config.action_dispatch.signed_cookie_salt

    secret_key_base = Rails.application.secret_key_base

    key_generator = ActiveSupport::KeyGenerator.new(
      secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA256
    )
    key_len = ActiveSupport::MessageEncryptor.key_len

    cookies.rotate :encrypted, key_generator.generate_key(authenticated_encrypted_cookie_salt, key_len)
    cookies.rotate :signed, key_generator.generate_key(signed_cookie_salt)
  end
end
