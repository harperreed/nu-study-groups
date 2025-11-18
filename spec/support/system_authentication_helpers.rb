# ABOUTME: Helper methods for system tests to simulate OAuth authentication
# ABOUTME: Provides sign_in_as method that uses OmniAuth test mode
module SystemAuthenticationHelpers
  # Sign in as a user using OAuth test mode
  # Creates the user if not already persisted
  def sign_in_as(user)
    user.save! unless user.persisted?

    # Set up OmniAuth mock
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: user.uid,
      info: {
        email: user.email,
        name: user.name
      }
    })

    # Visit the OAuth callback URL to trigger sign in
    visit '/auth/google_oauth2/callback'

    # Verify we're signed in
    expect(page).to have_text(user.name)
  end

  # Sign out the current user
  def sign_out
    click_button 'Logout'
  end
end

RSpec.configure do |config|
  config.include SystemAuthenticationHelpers, type: :system
end
