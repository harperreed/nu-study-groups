# ABOUTME: Helper methods for authenticating users in request specs
# ABOUTME: Provides sign_in method by setting session directly
module AuthenticationHelpers
  def sign_in(user)
    # Ensure the user exists in the database
    user.save! unless user.persisted?

    # For request specs, we need to actually make a request that sets up the session
    # The trick is to use the session hash directly through a special header
    # This is a workaround for the OAuth flow not working in tests
    @current_user = user

    # Set up a stub that works for the duration of the test
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)

    # Also stub pundit_user to return the same user
    allow_any_instance_of(ApplicationController).to receive(:pundit_user).and_return(user)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
