# ABOUTME: Handles OAuth authentication flow for login and logout
# ABOUTME: Creates or finds user from OAuth callback and manages session
class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    user = User.from_omniauth(request.env['omniauth.auth'])

    if user.persisted?
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Signed in successfully!'
    else
      redirect_to root_path, alert: 'Authentication failed, please try again.'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Signed out successfully!'
  end
end
