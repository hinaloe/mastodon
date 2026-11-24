require 'rails_helper'

RSpec.describe AboutController, type: :controller do
  render_views

  describe 'GET #show' do
    before do
      get :show
    end

    it 'assigns @instance_presenter' do
      expect(assigns(:instance_presenter)).to be_kind_of InstancePresenter
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET #more' do
    before do
      get :more
    end

    it 'assigns @instance_presenter' do
      expect(assigns(:instance_presenter)).to be_kind_of InstancePresenter
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET #more with domain blocks restricted to users' do
    before do
      Setting.show_domain_blocks = 'users'
      Setting.show_domain_blocks_rationale = 'users'
      Fabricate(:domain_block, domain: 'blocked.example', severity: :suspend, public_comment: 'reason')
    end

    after do
      Setting.show_domain_blocks = 'disabled'
      Setting.show_domain_blocks_rationale = 'disabled'
    end

    it 'does not show blocks to anonymous visitors' do
      get :more
      expect(assigns(:blocks)).to be_nil
    end

    it 'shows blocks to a functional user' do
      sign_in Fabricate(:user)
      get :more
      expect(assigns(:blocks)).to_not be_nil
      expect(@controller.view_context.display_blocks_rationale?).to be true
    end

    it 'does not show blocks to an unconfirmed user' do
      sign_in Fabricate(:user, confirmed_at: nil)
      get :more
      expect(assigns(:blocks)).to be_nil
      expect(@controller.view_context.display_blocks_rationale?).to be false
    end

    it 'does not show blocks to an unapproved user' do
      user = Fabricate(:user)
      user.update!(approved: false)
      sign_in user
      get :more
      expect(assigns(:blocks)).to be_nil
    end

    it 'does not show blocks to a suspended user' do
      user = Fabricate(:user)
      user.account.suspend!
      sign_in user
      get :more
      expect(assigns(:blocks)).to be_nil
    end
  end

  describe 'GET #terms' do
    before do
      get :terms
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'helper_method :new_user' do
    it 'returns a new User' do
      user = @controller.view_context.new_user
      expect(user).to be_kind_of User
      expect(user.account).to be_kind_of Account
    end
  end
end
