# frozen_string_literal: true

# devise-two-factor 6 stores the OTP secret in `users.otp_secret` with Active
# Record Encryption. Versions before it used attr_encrypted, which stored it in
# `encrypted_otp_secret`, `encrypted_otp_secret_iv` and
# `encrypted_otp_secret_salt`.
#
# - Reading: fall back to the legacy columns for users that have not been
#   migrated yet (devise-two-factor calls `legacy_otp_secret`).
# - Writing: also keep the legacy columns up to date, in attr_encrypted's
#   format, so that a rollback to the previous release still works for users
#   who set up or reset two-factor authentication after the upgrade.
#
# Include it after the `devise :two_factor_authenticatable` line.
module LegacyOtpSecret
  extend ActiveSupport::Concern

  # Settings of attr_encrypted 4 (per_attribute_iv_and_salt mode) and Encryptor 3
  ALGORITHM = 'aes-256-gcm'
  HMAC_ITERATIONS = 2000
  AUTH_TAG_LENGTH = 16

  included do
    before_save :write_legacy_otp_secret, if: :will_save_change_to_otp_secret?
  end

  # If the new column cannot be decrypted (for instance a process started
  # with different ACTIVE_RECORD_ENCRYPTION_* keys), use the legacy copy
  # instead of failing the sign-in, and report it loudly.
  def otp_secret
    super
  rescue ActiveRecord::Encryption::Errors::Decryption => e
    Rails.logger.error("Unable to decrypt users.otp_secret of user #{id} (#{e.class}); check ACTIVE_RECORD_ENCRYPTION_* keys. Using the legacy copy.")
    legacy_otp_secret
  end

  private

  # Decrypt and return the secret stored by previous versions of
  # devise-two-factor.
  # @return [String] The decrypted OTP secret
  def legacy_otp_secret
    return nil unless self[:encrypted_otp_secret]
    return nil unless self.class.otp_secret_encryption_key

    salt = Base64.decode64(encrypted_otp_secret_salt)
    iv = Base64.decode64(encrypted_otp_secret_iv)

    raw_cipher_text = Base64.decode64(encrypted_otp_secret)
    # The last 16 bytes of the ciphertext are the authentication tag
    cipher_text = raw_cipher_text[0...-AUTH_TAG_LENGTH]
    auth_tag = raw_cipher_text[-AUTH_TAG_LENGTH..]

    cipher = OpenSSL::Cipher.new(ALGORITHM)
    cipher.decrypt
    cipher.key = legacy_otp_secret_key(salt, cipher.key_len)
    cipher.iv = iv
    # The tag must be set after #decrypt, #key= and #iv=, and before #final,
    # which verifies it (and raises OpenSSL::Cipher::CipherError on mismatch)
    cipher.auth_tag = auth_tag
    cipher.auth_data = ''

    cipher.update(cipher_text) + cipher.final
  end

  # Encrypt the secret into the legacy columns, as attr_encrypted did: Base64
  # values, a "_"-prefixed salt, and the authentication tag appended to the
  # ciphertext.
  def write_legacy_otp_secret
    secret = self[:otp_secret]

    if secret.blank? || self.class.otp_secret_encryption_key.blank?
      self.encrypted_otp_secret = nil
      self.encrypted_otp_secret_iv = nil
      self.encrypted_otp_secret_salt = nil
      return
    end

    cipher = OpenSSL::Cipher.new(ALGORITHM)
    cipher.encrypt
    iv = cipher.random_iv
    salt = SecureRandom.random_bytes
    cipher.key = legacy_otp_secret_key(salt, cipher.key_len)
    cipher.iv = iv
    cipher.auth_data = ''

    encrypted = cipher.update(secret) + cipher.final + cipher.auth_tag

    self.encrypted_otp_secret = [encrypted].pack('m')
    self.encrypted_otp_secret_iv = [iv].pack('m')
    self.encrypted_otp_secret_salt = "_#{[salt].pack('m')}"
  end

  def legacy_otp_secret_key(salt, key_len)
    OpenSSL::PKCS5.pbkdf2_hmac_sha1(self.class.otp_secret_encryption_key, salt, HMAC_ITERATIONS, key_len)
  end
end
