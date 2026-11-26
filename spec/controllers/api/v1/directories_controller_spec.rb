# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::DirectoriesController do
  render_views

  let(:user)    { Fabricate(:user, confirmed_at: nil) }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:follows') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  # The directory only lists accounts that have an account_stat row, which
  # accounts in this version only get once they have some activity.
  # Statuses set it with the database's now(), which does not move inside the
  # test transaction, so the order is set explicitly where it matters.
  def with_stats(account, last_status_at: nil)
    account.account_stat.update!(last_status_at: last_status_at)
    account
  end

  describe 'GET #show' do
    context 'with no params' do
      before do
        _local_unconfirmed_account = with_stats Fabricate(
          :account,
          domain: nil,
          user: Fabricate(:user, confirmed_at: nil, approved: true),
          discoverable: true,
          username: 'local_unconfirmed'
        )

        local_unapproved_account = with_stats Fabricate(
          :account,
          domain: nil,
          user: Fabricate(:user, confirmed_at: 10.days.ago),
          discoverable: true,
          username: 'local_unapproved'
        )
        local_unapproved_account.user.update(approved: false)

        _local_undiscoverable_account = with_stats Fabricate(
          :account,
          domain: nil,
          user: Fabricate(:user, confirmed_at: 10.days.ago, approved: true),
          discoverable: false,
          username: 'local_undiscoverable'
        )

        excluded_from_timeline_account = with_stats Fabricate(
          :account,
          domain: 'host.example',
          discoverable: true,
          username: 'remote_excluded_from_timeline'
        )
        Fabricate(:block, account: user.account, target_account: excluded_from_timeline_account)

        _domain_blocked_account = with_stats Fabricate(
          :account,
          domain: 'test.example',
          discoverable: true,
          username: 'remote_domain_blocked'
        )
        Fabricate(:account_domain_block, account: user.account, domain: 'test.example')
      end

      it 'returns only the local discoverable account' do
        local_discoverable_account = with_stats Fabricate(
          :account,
          domain: nil,
          user: Fabricate(:user, confirmed_at: 10.days.ago, approved: true),
          discoverable: true,
          username: 'local_discoverable'
        ), last_status_at: 2.days.ago

        eligible_remote_account = with_stats Fabricate(
          :account,
          domain: 'host.example',
          discoverable: true,
          username: 'eligible_remote'
        ), last_status_at: 1.day.ago

        get :show

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(2)
        expect(body_as_json.first[:id]).to include(eligible_remote_account.id.to_s)
        expect(body_as_json.second[:id]).to include(local_discoverable_account.id.to_s)
      end
    end

    context 'when asking for local accounts only' do
      it 'returns only the local accounts' do
        user = Fabricate(:user, confirmed_at: 10.days.ago, approved: true)
        local_account = with_stats Fabricate(:account, domain: nil, user: user, discoverable: true)
        remote_account = with_stats Fabricate(:account, domain: 'host.example', discoverable: true)

        get :show, params: { local: '1' }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(1)
        expect(body_as_json.first[:id]).to include(local_account.id.to_s)
        expect(response.body).to_not include(remote_account.id.to_s)
      end
    end

    context 'when ordered by active' do
      it 'returns accounts in order of most recent status activity' do
        status_old = Fabricate(:status, account: Fabricate(:account, discoverable: true))
        travel_to 10.seconds.from_now
        status_new = Fabricate(:status, account: Fabricate(:account, discoverable: true))
        status_old.account.account_stat.update!(last_status_at: status_old.created_at)
        status_new.account.account_stat.update!(last_status_at: status_new.created_at)

        get :show, params: { order: 'active' }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(2)
        expect(body_as_json.first[:id]).to include(status_new.account.id.to_s)
        expect(body_as_json.second[:id]).to include(status_old.account.id.to_s)
      end
    end

    context 'when ordered by new' do
      it 'returns accounts in order of creation' do
        account_old = with_stats Fabricate(:account, discoverable: true)
        travel_to 10.seconds.from_now
        account_new = with_stats Fabricate(:account, discoverable: true)

        get :show, params: { order: 'new' }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(2)
        expect(body_as_json.first[:id]).to include(account_new.id.to_s)
        expect(body_as_json.second[:id]).to include(account_old.id.to_s)
      end
    end
  end
end
