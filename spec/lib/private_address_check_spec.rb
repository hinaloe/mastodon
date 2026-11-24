# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrivateAddressCheck do
  describe 'private_address?' do
    private_ips = %w(192.168.1.7 10.0.0.1 0.0.0.0 127.0.0.1 169.254.169.254 ::1 fe80::1 fc00::1 ::ffff:0.0.0.1 ::127.0.0.1 ::ffff:127.0.0.1 ::ffff:10.0.0.1 ::ffff:169.254.169.254 :: 64:ff9b:1::1)
    public_ips  = %w(8.8.8.8 1.1.1.1 2001:4860:4860::8888 ::ffff:8.8.8.8)

    private_ips.each do |addr|
      it "returns true for #{addr}" do
        expect(described_class.private_address?(IPAddr.new(addr))).to be true
      end
    end

    public_ips.each do |addr|
      it "returns false for #{addr}" do
        expect(described_class.private_address?(IPAddr.new(addr))).to be false
      end
    end
  end
end
