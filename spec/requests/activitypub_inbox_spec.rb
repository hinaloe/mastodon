# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ActivityPub inbox' do
  describe 'POST /inbox' do
    it 'rejects payloads over the size limit before parsing them' do
      body = Oj.dump({ 'type' => 'Create', 'content' => 'a' * ActivityPub::Activity::MAX_JSON_SIZE })

      post '/inbox', params: body, headers: { 'Content-Type' => 'application/activity+json' }

      expect(response).to have_http_status(413)
    end
  end
end
