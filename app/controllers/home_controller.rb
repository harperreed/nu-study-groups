# ABOUTME: Landing page controller showing courses and study groups
# ABOUTME: Redirects to courses list if logged in, shows welcome page if not
class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to courses_path
    end
    # If not signed in, render the welcome page
  end
end
