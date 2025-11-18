# ABOUTME: Request specs for OAuth authentication flow
# ABOUTME: Tests login, logout, and OAuth callback handling
require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /auth/google_oauth2/callback" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        'provider' => 'google_oauth2',
        'uid' => '12345',
        'info' => {
          'email' => 'student@example.com',
          'name' => 'Jane Student'
        }
      })
    end

    before do
      # Set up OmniAuth mock for the test
      OmniAuth.config.add_mock(:google_oauth2, auth_hash)
      Rails.application.env_config['omniauth.auth'] = auth_hash
      # Visit the auth endpoint first to set up the session properly
      post '/auth/google_oauth2'
    end

    after do
      Rails.application.env_config['omniauth.auth'] = nil
    end

    it 'creates a new user and logs them in' do
      expect {
        get '/auth/google_oauth2/callback'
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(User.last.id)
    end

    it 'logs in an existing user' do
      user = User.create!(
        email: 'student@example.com',
        name: 'Jane Student',
        provider: 'google_oauth2',
        uid: '12345',
        role: 'student'
      )

      expect {
        get '/auth/google_oauth2/callback'
      }.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "DELETE /logout" do
    let(:user) { User.create!(email: 'test@example.com', name: 'Test', provider: 'google_oauth2', uid: '123', role: 'student') }
    let(:logout_auth_hash) do
      OmniAuth::AuthHash.new({
        'provider' => 'google_oauth2',
        'uid' => '123',
        'info' => {
          'email' => 'test@example.com',
          'name' => 'Test'
        }
      })
    end

    before do
      # Log in first
      OmniAuth.config.add_mock(:google_oauth2, logout_auth_hash)
      Rails.application.env_config['omniauth.auth'] = logout_auth_hash
      post '/auth/google_oauth2'
      get '/auth/google_oauth2/callback'
    end

    after do
      Rails.application.env_config['omniauth.auth'] = nil
    end

    it 'logs out the user and clears the session' do
      delete '/logout'

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
    end
  end
end
