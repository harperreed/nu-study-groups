# ABOUTME: Policy for admin dashboard access
# ABOUTME: Only admins can view the dashboard
class DashboardPolicy
  attr_reader :user, :dashboard

  def initialize(user, dashboard)
    @user = user
    @dashboard = dashboard
  end

  def show?
    user&.admin?
  end
end
