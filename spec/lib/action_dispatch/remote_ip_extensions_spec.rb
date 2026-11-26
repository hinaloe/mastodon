# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActionDispatch::RemoteIp do
  # 10.0.0.0/8 is one of the default trusted proxies
  def remote_ip(remote_addr:, forwarded_for: nil, client_ip: nil)
    env = Rack::MockRequest.env_for('/', 'REMOTE_ADDR' => remote_addr)
    env['HTTP_X_FORWARDED_FOR'] = forwarded_for if forwarded_for
    env['HTTP_CLIENT_IP'] = client_ip if client_ip

    app = described_class.new(->(e) { [200, {}, [e['action_dispatch.remote_ip'].to_s]] }, true)
    app.call(env)[2].first
  end

  it 'uses the address set by a trusted proxy' do
    expect(remote_ip(remote_addr: '10.0.0.1', forwarded_for: '203.0.113.5')).to eq '203.0.113.5'
  end

  it 'ignores entries that are not IP addresses' do
    expect(remote_ip(remote_addr: '10.0.0.1', forwarded_for: 'not-an-ip, 203.0.113.5')).to eq '203.0.113.5'
  end

  it 'ignores addresses with a netmask' do
    expect(remote_ip(remote_addr: '10.0.0.1', forwarded_for: '203.0.113.0/24')).to eq '10.0.0.1'
  end

  it 'uses the client address without forwarding headers' do
    expect(remote_ip(remote_addr: '198.51.100.7')).to eq '198.51.100.7'
  end

  it 'rejects forwarding headers sent by a client that is not a trusted proxy' do
    expect { remote_ip(remote_addr: '198.51.100.7', forwarded_for: '203.0.113.5') }
      .to raise_error(ActionDispatch::RemoteIp::IpSpoofAttackError)
  end

  it 'rejects conflicting Client-Ip and X-Forwarded-For headers' do
    expect { remote_ip(remote_addr: '10.0.0.1', forwarded_for: '203.0.113.5', client_ip: '192.0.2.9') }
      .to raise_error(ActionDispatch::RemoteIp::IpSpoofAttackError)
  end
end
