# ABOUTME: OmniAuth configuration for RSpec tests
# ABOUTME: Enables test mode and provides helper methods for mocking OAuth
RSpec.configure do |config|
  config.before(:each) do
    OmniAuth.config.test_mode = true
  end

  config.after(:each) do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end

# Helper to set up OmniAuth mock auth
def set_omniauth(provider: :google_oauth2, uid: '12345', email: 'test@example.com', name: 'Test User')
  OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
    provider: provider.to_s,
    uid: uid,
    info: {
      email: email,
      name: name
    }
  })
end
