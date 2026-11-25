# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('db', 'post_migrate', '20261125120100_migrate_devise_two_factor_secrets.rb')

RSpec.describe MigrateDeviseTwoFactorSecrets do
  let!(:legacy_user) do
    # Secret stored by the previous version (attr_encrypted) only
    Fabricate(:user, otp_required_for_login: true).tap do |user|
      user.update_columns(
        otp_secret: nil,
        encrypted_otp_secret: "Fttsy7QAa0edaDfdfSz094rRLAxc8cJweDQ4BsWH/zozcdVA8o9GLqcKhn2b\nGi/V\n",
        encrypted_otp_secret_iv: 'rys3THICkr60BoWC',
        encrypted_otp_secret_salt: '_LMkAGvdg7a+sDIKjI3mR2Q=='
      )
    end
  end

  let!(:user_without_2fa) { Fabricate(:user, otp_required_for_login: false) }

  it 'copies the legacy secrets of users with two-factor authentication to otp_secret' do
    described_class.new.migrate(:up)

    expect(User.find(legacy_user.id)[:otp_secret]).to eq 'anotpsecretthatshouldbeencrypted'
    expect(User.connection.select_value("SELECT otp_secret FROM users WHERE id = #{legacy_user.id}")).to_not include 'anotpsecretthatshouldbeencrypted'
    expect(User.find(user_without_2fa.id)[:otp_secret]).to be_nil
  end
end
